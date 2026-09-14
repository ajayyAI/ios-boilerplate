//
//  Haptics.swift
//  Scaffold
//

import SwiftUI

/// The haptic vocabulary. Six words, each tied to a meaning, so a screen says
/// `.haptic(.success, …)` and never picks an intensity by hand.
///
/// The rule that keeps haptics from becoming noise: a haptic marks a *state change or
/// a decision* — a goal reached, a purchase completed, a destructive confirm, a
/// selection changing under the finger. It does not mark a tap on a navigation link or
/// a scroll. The primary button style plays `.tap` because pressing the one filled
/// button on a screen is a decision; nothing else plays one by default.
///
/// Built on `sensoryFeedback`, so it is declarative, follows the system haptics
/// setting, and does nothing on hardware without a Taptic Engine.
enum Haptic: Equatable, Sendable {
    /// A button press. Light impact, over before the finger lifts.
    case tap
    /// A picker, segmented control or slider moving to a new value.
    case selection
    /// Something the user was working toward is done.
    case success
    /// Something needs attention but is recoverable.
    case warning
    /// Something failed.
    case error

    var feedback: SensoryFeedback {
        switch self {
        case .tap: .impact(weight: .light)
        case .selection: .selection
        case .success: .success
        case .warning: .warning
        case .error: .error
        }
    }
}

extension View {
    /// Plays `haptic` whenever `trigger` changes.
    ///
    /// ```swift
    /// .haptic(.success, trigger: viewModel.state.isEntitled)
    /// ```
    func haptic(_ haptic: Haptic, trigger: some Equatable) -> some View {
        sensoryFeedback(haptic.feedback, trigger: trigger)
    }

    /// Plays `haptic` when `trigger` changes and `condition` approves the transition.
    func haptic<T: Equatable>(
        _ haptic: Haptic,
        trigger: T,
        condition: @escaping (_ oldValue: T, _ newValue: T) -> Bool,
    ) -> some View {
        sensoryFeedback(haptic.feedback, trigger: trigger, condition: condition)
    }
}
