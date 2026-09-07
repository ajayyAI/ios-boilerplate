//
//  ButtonStyles.swift
//  Scaffold
//

import SwiftUI

/// The filled button. One per screen at most — it is the thing you want tapped.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PrimaryButtonBody(configuration: configuration)
    }
}

/// The outlined button. Everything that is a real choice but not *the* choice.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        SecondaryButtonBody(configuration: configuration)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: Self {
        PrimaryButtonStyle()
    }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: Self {
        SecondaryButtonStyle()
    }
}

// MARK: - Bodies

/// `ButtonStyle` is not a `View`, so it cannot read `@Environment` itself. The body has to
/// be a real view type for the theme — and for `isEnabled` and the motion setting — to
/// reach it.
private struct PrimaryButtonBody: View {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    let configuration: ButtonStyle.Configuration

    var body: some View {
        configuration.label
            .font(theme.font.label)
            .foregroundStyle(theme.color.onAccent)
            // A spinner inside the label follows `tint`, not `foregroundStyle`, and would
            // otherwise render in the accent colour on top of the accent colour.
            .tint(theme.color.onAccent)
            .padding(.vertical, theme.spacing.md)
            .frame(maxWidth: .infinity)
            .background(theme.color.accent, in: .rect(cornerRadius: theme.radius.md))
            .pressFeedback(isPressed: configuration.isPressed, isEnabled: isEnabled)
    }
}

private struct SecondaryButtonBody: View {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    let configuration: ButtonStyle.Configuration

    var body: some View {
        configuration.label
            .font(theme.font.label)
            .foregroundStyle(theme.color.textPrimary)
            .padding(.vertical, theme.spacing.md)
            .frame(maxWidth: .infinity)
            .background(theme.color.surface, in: .rect(cornerRadius: theme.radius.md))
            .overlay {
                RoundedRectangle(cornerRadius: theme.radius.md)
                    .stroke(theme.color.border, lineWidth: 1)
            }
            .pressFeedback(isPressed: configuration.isPressed, isEnabled: isEnabled)
    }
}

// MARK: - Press feedback

extension View {
    fileprivate func pressFeedback(isPressed: Bool, isEnabled: Bool) -> some View {
        modifier(PressFeedback(isPressed: isPressed, isEnabled: isEnabled))
    }
}

/// The shrink-on-touch every native control has.
///
/// Scale rather than a colour change because it survives any tint the theme is given, and
/// because it reads as the button moving under the finger rather than as a state change.
private struct PressFeedback: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isPressed: Bool
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : 1)
            .opacity(isEnabled ? 1 : 0.4)
            // Reduce Motion asks for no movement, not for no feedback: the press still
            // registers, it just arrives without the spring.
            .animation(reduceMotion ? nil : .snappy(duration: 0.18), value: isPressed)
            .animation(.easeOut(duration: 0.15), value: isEnabled)
    }
}

// MARK: - Previews

#Preview("Buttons") {
    @Previewable @Environment(\.theme) var theme

    VStack(spacing: theme.spacing.md) {
        Button("Continue") {}
            .buttonStyle(.primary)

        Button("Restore purchases") {}
            .buttonStyle(.secondary)

        Button("Continue") {}
            .buttonStyle(.primary)
            .disabled(true)
    }
    .padding(theme.spacing.xl)
    .frame(maxHeight: .infinity)
    .background(theme.color.background)
}
