#!/usr/bin/env python3
"""Turn a translations file into Liquid blocks for the Superwall paywall editor.

    ./scripts/paywall-liquid.py                 # every string in scripts/paywall-strings.json
    ./scripts/paywall-liquid.py headline        # just one
    ./scripts/paywall-liquid.py --file other.json

Each text element on a paywall takes one block: paste it into the element's text box.
The block picks a translation from the device's language and falls back to the base
language, so a paywall localizes without the dashboard's paid localization feature.

Language keys are BCP 47: `fr`, `de`, `pt-BR`, `zh-Hant`. A key with a region or script
is matched on the locale *inside* its language's branch, as a nested `if`. Liquid has no
parentheses and reads `and`/`or` right to left, so a flat condition mixing the two is a
bug waiting for the day someone reorders it; nesting has one reading.

Missing or empty translations fail the run. An element that quietly stays in English
on an otherwise translated paywall looks broken, and nobody sees it until a user does.
"""

import argparse
import json
import sys
from pathlib import Path

DEFAULT_FILE = Path(__file__).resolve().parent / "paywall-strings.json"

# What the SDK reports. `app` follows the language the app is running in, so the paywall
# matches the app and respects the per-app language setting — but it is only ever a
# language the app itself is localized into. `device` follows the user's first preferred
# language, which is what an English-only app with a translated paywall needs.
VARIABLES = {
    "app": ("device.deviceLanguageCode", "device.deviceLocale"),
    "device": ("device.preferredLanguageCode", "device.preferredLocale"),
}

# A script subtag rarely survives into the locale identifier on its own, so the regions
# that imply it are matched too.
SCRIPT_MARKERS = {
    "Hant": ["Hant", "_TW", "_HK", "_MO"],
    "Hans": ["Hans", "_CN", "_SG"],
}


def fail(message: str) -> None:
    sys.exit(f"error: {message}")


def markers(subtag: str) -> list[str]:
    """Substrings of a locale identifier that select this script or region."""
    if subtag in SCRIPT_MARKERS:
        return SCRIPT_MARKERS[subtag]
    # Identifiers arrive as `pt_BR` from Foundation and `pt-BR` from preferred languages.
    return [f"_{subtag}", f"-{subtag}"]


def validate(strings: dict, base: str) -> list[str]:
    """Every string must carry every language. Returns the languages in a stable order."""
    languages = sorted({tag for translations in strings.values() for tag in translations})
    if base not in languages:
        fail(f"no string has the base language '{base}'")
    problems = []
    for key, translations in strings.items():
        for tag in languages:
            text = translations.get(tag)
            if not isinstance(text, str) or not text.strip():
                problems.append(f"  {key}: missing '{tag}'")
    if problems:
        fail("incomplete translations\n" + "\n".join(problems))
    return languages


def language_branch(translations: dict, tags: list[str], locale_variable: str) -> str:
    """The body for one language: its text, or a nested choice between its variants."""
    plain = [tag for tag in tags if "-" not in tag]
    variants = [tag for tag in tags if "-" in tag]
    # With no plain key, the first variant doubles as the language's default: `pt-BR`
    # alone should still serve a reader in Portugal rather than drop them to English.
    default = translations[plain[0]] if plain else translations[variants.pop(0)]
    if not variants:
        return default

    parts = []
    for index, tag in enumerate(variants):
        condition = " or ".join(
            f'{locale_variable} contains "{marker}"' for marker in markers(tag.split("-", 1)[1])
        )
        parts.append(f"{{% {'if' if index == 0 else 'elsif'} {condition} %}}{translations[tag]}")
    return "".join(parts) + f"{{% else %}}{default}{{% endif %}}"


def block(translations: dict, languages: list[str], base: str, match: str) -> str:
    language_variable, locale_variable = VARIABLES[match]
    base_language = base.split("-", 1)[0]

    grouped: dict[str, list[str]] = {}
    for tag in languages:
        grouped.setdefault(tag.split("-", 1)[0], []).append(tag)

    parts = []
    for language, tags in grouped.items():
        if language == base_language:
            continue
        keyword = "if" if not parts else "elsif"
        body = language_branch(translations, tags, locale_variable)
        parts.append(f'{{% {keyword} {language_variable} == "{language}" %}}{body}')

    fallback = language_branch(translations, grouped[base_language], locale_variable)
    if not parts:
        return fallback
    return "".join(parts) + f"{{% else %}}{fallback}{{% endif %}}"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("keys", nargs="*", help="strings to print; all of them when omitted")
    parser.add_argument("--file", type=Path, default=DEFAULT_FILE)
    args = parser.parse_args()

    try:
        config = json.loads(args.file.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        fail(f"{args.file}: {error}")

    strings = config.get("strings") or {}
    base = config.get("base", "en")
    match = config.get("match", "app")
    if not strings:
        fail(f"{args.file} has no strings")
    if match not in VARIABLES:
        fail(f"'match' must be one of {sorted(VARIABLES)}, not '{match}'")

    unknown = [key for key in args.keys if key not in strings]
    if unknown:
        fail(f"no such string: {', '.join(unknown)}")

    languages = validate(strings, base)
    for key in args.keys or strings:
        print(f"── {key} ──")
        print(block(strings[key], languages, base, match))
        print()
    print(f"{len(args.keys or strings)} block(s), {len(languages)} languages: {', '.join(languages)}", file=sys.stderr)


if __name__ == "__main__":
    main()
