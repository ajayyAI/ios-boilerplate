//
//  Theme.swift
//  Scaffold
//

import SwiftUI

/// Every design decision in the app, in one value.
///
/// This is the file you edit to rebrand. Views never name a colour, a corner radius or a
/// point value directly — they read a semantic token off `\.theme`, the same contract as a
/// CSS variable block: swap the values here and every screen follows, with nothing else to
/// find and change.
///
/// Tokens are semantic ("the colour of a card") rather than descriptive ("light grey"), so
/// a dark appearance or a second brand is a different `Theme`, not a set of `if` statements
/// scattered through the views.
///
/// Adding a token is deliberately a two-line change — a property here and a value in
/// ``Theme/scaffold`` — because a token that only one screen uses is a hardcoded value with
/// extra steps. Reach for one when a second view needs the same decision.
struct Theme: Equatable, Sendable {
    var color: ColorTokens
    var spacing: SpacingTokens
    var radius: RadiusTokens
    var font: FontTokens
}

// MARK: - Tokens

extension Theme {
    /// Colours by role. Each is an adaptive pair, so light and dark are decided here rather
    /// than at the point of use.
    struct ColorTokens: Equatable, Sendable {
        /// Brand colour. Drives primary buttons, links and selection.
        var accent: Color
        /// Content drawn on top of ``accent`` — not a shade of it, a contrasting colour.
        /// This is why it is a token and not a hardcoded `.white`: an accent light enough to
        /// read against a dark background is too light to carry white text.
        var onAccent: Color
        /// The window behind everything.
        var background: Color
        /// Raised content: cards, grouped rows, sheets.
        var surface: Color
        /// The hairline separating a surface from the background.
        var border: Color
        /// Body copy and headings.
        var textPrimary: Color
        /// Supporting copy. Must stay legible — this is not "disabled".
        var textSecondary: Color
        /// Destructive actions and error states.
        var danger: Color
    }

    /// A 4pt scale. Sizes are named by role, not by number, so a change to the rhythm of the
    /// app is one edit rather than a search for every `16`.
    struct SpacingTokens: Equatable, Sendable {
        /// 4 — between a label and the value it describes.
        var xs: CGFloat
        /// 8 — between tightly related controls.
        var sm: CGFloat
        /// 16 — the default gap, and a card's inner padding.
        var md: CGFloat
        /// 24 — between sections.
        var lg: CGFloat
        /// 32 — around the edge of a screen's content.
        var xl: CGFloat
    }

    struct RadiusTokens: Equatable, Sendable {
        /// 8 — chips and small controls.
        var sm: CGFloat
        /// 12 — buttons and fields.
        var md: CGFloat
        /// 20 — cards and sheets.
        var lg: CGFloat
    }

    /// Fonts by role. Every one is built from a system text style, so Dynamic Type keeps
    /// working — a fixed `.system(size:)` would not scale and is the usual way a design
    /// system breaks accessibility.
    struct FontTokens: Equatable, Sendable {
        var screenTitle: Font
        var sectionTitle: Font
        var body: Font
        var label: Font
        var caption: Font
    }
}

// MARK: - The default theme

extension Theme {
    /// The theme the starter ships with.
    ///
    /// A `static let` rather than a computed property on purpose: SwiftUI compares
    /// environment values to decide what to re-render, and two separately constructed
    /// adaptive `Color`s never compare equal. One stored instance keeps the comparison
    /// cheap and stops unrelated environment writes from invalidating every view that
    /// reads the theme.
    static let scaffold = Theme(
        color: ColorTokens(
            accent: Color(
                light: Color(red: 0.20, green: 0.36, blue: 0.98),
                dark: Color(red: 0.44, green: 0.58, blue: 1.00),
            ),
            onAccent: Color(light: .white, dark: Color(white: 0.06)),
            background: Color(light: Color(white: 0.97), dark: Color(white: 0.07)),
            surface: Color(light: .white, dark: Color(white: 0.13)),
            border: Color(light: Color(white: 0.00, opacity: 0.08), dark: Color(white: 1.00, opacity: 0.12)),
            textPrimary: Color(light: Color(white: 0.07), dark: Color(white: 0.96)),
            textSecondary: Color(light: Color(white: 0.42), dark: Color(white: 0.64)),
            danger: Color(
                light: Color(red: 0.79, green: 0.16, blue: 0.20),
                dark: Color(red: 1.00, green: 0.42, blue: 0.42),
            ),
        ),
        spacing: SpacingTokens(xs: 4, sm: 8, md: 16, lg: 24, xl: 32),
        radius: RadiusTokens(sm: 8, md: 12, lg: 20),
        font: FontTokens(
            screenTitle: .system(.largeTitle, design: .rounded, weight: .bold),
            sectionTitle: .system(.headline, design: .rounded, weight: .semibold),
            body: .system(.body),
            label: .system(.subheadline, weight: .medium),
            caption: .system(.footnote),
        ),
    )
}

// MARK: - Environment

extension EnvironmentValues {
    /// The active theme. Override it at the root to rebrand:
    ///
    /// ```swift
    /// RootView().environment(\.theme, .myBrand)
    /// ```
    ///
    /// Bind a stored `static let`, never a `Theme(...)` literal written inline in a body —
    /// a fresh instance on every evaluation defeats SwiftUI's equality check and re-renders
    /// every view that reads the theme.
    @Entry var theme: Theme = .scaffold
}

// MARK: - Adaptive colour

extension Color {
    /// A colour that resolves against the current interface style.
    ///
    /// Asset catalogues can do this too, but a token set spread over a folder of JSON is
    /// hard to read as a whole. Keeping both appearances on one line makes the contrast
    /// pair reviewable.
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            UIColor(traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}
