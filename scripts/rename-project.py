#!/usr/bin/env python3
"""Rename the starter to your app's name.

Run once, right after cloning:

    ./scripts/rename-project.py MyApp

Renames every file and folder carrying the old name, then rewrites the name inside
source files. Use --dry-run first if you want to see the plan without touching disk.
"""

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Never descend into these. `ref/` holds cloned third-party repos and `.git` holds
# history: rewriting either corrupts something that is not ours.
SKIP_DIRS = {
    ".git", "ref", ".claude", ".agents", "node_modules",
    "DerivedData", ".build", "xcuserdata", "TestResults.xcresult",
}

# Extensions carrying the project name. `Makefile` and `Brewfile` have no extension
# and were previously missed, which left `make` pointing at the old .xcodeproj.
ALLOWED_EXTENSIONS = {
    "swift", "plist", "yml", "yaml", "pbxproj", "storyboard",
    "xctestplan", "xcscheme", "md", "xcconfig", "sh",
}
EXTENSIONLESS_FILES = {"Makefile", "Brewfile"}

# An Xcode target name becomes a Swift module name, so it has to be a bare identifier:
# leading letter, then letters, digits or underscores. A name with a space or a hyphen
# produces a project that opens and then fails to build.
VALID_NAME = re.compile(r"^[A-Za-z][A-Za-z0-9_]*$")

COLOR = sys.stdout.isatty() and os.environ.get("NO_COLOR") is None


def paint(text, code):
    return f"\033[{code}m{text}\033[0m" if COLOR else text


def bold(text):
    return paint(text, "1")


def dim(text):
    return paint(text, "2")


def green(text):
    return paint(text, "32")


def red(text):
    return paint(text, "31")


def fail(message):
    print(f"{red('error')}: {message}", file=sys.stderr)
    sys.exit(1)


def is_renameable(name):
    return name in EXTENSIONLESS_FILES or name.rsplit(".", 1)[-1] in ALLOWED_EXTENSIONS


def plan_renames(old, new):
    """Paths to rename, deepest first.

    Depth order is what makes this correct: renaming `TemplateApp/` before the files
    beneath it invalidates every path still queued underneath.
    """
    matches = []
    for root, dirs, files in os.walk(ROOT, topdown=True):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for name in dirs + files:
            if old in name:
                matches.append(Path(root) / name)
    return sorted(matches, key=lambda path: len(path.parts), reverse=True)


def plan_rewrites(old):
    """Files whose contents mention the old name."""
    matches = []
    for root, dirs, files in os.walk(ROOT, topdown=True):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for name in files:
            if not is_renameable(name):
                continue
            path = Path(root) / name
            try:
                if old in path.read_text():
                    matches.append(path)
            except (UnicodeDecodeError, OSError):
                continue
    return sorted(matches)


def relative(path):
    return path.relative_to(ROOT).as_posix()


def working_tree_is_dirty():
    result = subprocess.run(
        ["git", "status", "--porcelain"],
        cwd=ROOT, capture_output=True, text=True, check=False,
    )
    return result.returncode == 0 and result.stdout.strip() != ""


def main():
    parser = argparse.ArgumentParser(
        description="Rename the starter project to your app's name.",
        epilog="example: ./scripts/rename-project.py MyApp",
    )
    parser.add_argument("name", nargs="?", help="the new project name, e.g. MyApp")
    parser.add_argument("--old", default="TemplateApp", help="the name being replaced (default: TemplateApp)")
    parser.add_argument("-n", "--dry-run", action="store_true", help="print the plan without touching disk")
    parser.add_argument("-y", "--yes", action="store_true", help="skip the confirmation prompt")
    parser.add_argument("--force", action="store_true", help="proceed even with uncommitted changes")
    args = parser.parse_args()

    new = args.name or input("New project name: ").strip()
    old = args.old

    if not VALID_NAME.match(new):
        fail(f"{new!r} is not a valid target name — use letters, digits and underscores, starting with a letter.")
    if new == old:
        fail(f"the project is already named {new!r}.")

    renames = plan_renames(old, new)
    rewrites = plan_rewrites(old)

    if not renames and not rewrites:
        fail(f"nothing to rename — found no trace of {old!r}. Already renamed?")

    print(f"\n{bold('Renaming')} {old} {dim('→')} {bold(new)}\n")
    for path in renames:
        print(f"  {dim('move')}    {relative(path)}")
    for path in rewrites:
        print(f"  {dim('rewrite')} {relative(path)}")
    print(f"\n  {len(renames)} paths renamed, {len(rewrites)} files rewritten.\n")

    if args.dry_run:
        print(dim("Dry run — nothing was changed."))
        return

    if not args.force and working_tree_is_dirty():
        fail("uncommitted changes present. Commit or stash them first, so this is reviewable as one diff (--force overrides).")

    if not args.yes and input("Proceed? [y/N] ").strip().lower() not in {"y", "yes"}:
        print(dim("Cancelled."))
        return

    for path in renames:
        path.rename(path.with_name(path.name.replace(old, new)))

    for path in rewrites:
        # Re-derive the path: a rewrite target may have moved in the pass above. Only the
        # part below ROOT is rewritten — the checkout itself may sit in a directory whose
        # own name contains the old one.
        moved = ROOT / relative(path).replace(old, new)
        target = moved if moved.exists() else path
        target.write_text(target.read_text().replace(old, new))

    print(f"\n{green('Done.')} Next:\n")
    print(f"  1. open {new}.xcodeproj and set your bundle identifier and team")
    print("  2. replace Assets.xcassets/AppIcon.appiconset/AppIcon.png - one 1024x1024,")
    print("     no transparency. Xcode derives every other size from it.")
    print("  3. make check")
    print(f"  4. git add -A && git commit -m 'chore: rename to {new}'")
    print(f"\n{dim('This script has done its job — delete it.')}")


if __name__ == "__main__":
    main()
