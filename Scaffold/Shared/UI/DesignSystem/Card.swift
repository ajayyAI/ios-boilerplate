//
//  Card.swift
//  Scaffold
//

import SwiftUI

extension View {
    /// Lifts content onto a surface: inner padding, the theme's card radius, a hairline
    /// border and a shadow shallow enough to survive dark mode.
    func card() -> some View {
        modifier(CardSurface())
    }
}

private struct CardSurface: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .padding(theme.spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.color.surface, in: .rect(cornerRadius: theme.radius.lg))
            // The border carries the separation in dark mode, where a shadow on a near-black
            // background is invisible; the shadow carries it in light mode. Both are always
            // present so neither appearance is a special case.
            .overlay {
                RoundedRectangle(cornerRadius: theme.radius.lg)
                    .stroke(theme.color.border, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

#Preview("Card") {
    @Previewable @Environment(\.theme) var theme

    VStack(alignment: .leading, spacing: theme.spacing.xs) {
        Text("Example user")
            .font(theme.font.caption)
            .foregroundStyle(theme.color.textSecondary)

        Text(verbatim: "hello@example.com")
            .font(theme.font.body)
            .foregroundStyle(theme.color.textPrimary)
    }
    .card()
    .padding(theme.spacing.xl)
    .frame(maxHeight: .infinity)
    .background(theme.color.background)
}
