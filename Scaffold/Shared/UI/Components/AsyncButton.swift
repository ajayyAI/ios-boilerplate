//
//  AsyncButton.swift
//  Scaffold
//

import SwiftUI

/// A `Button` whose action is `async`.
///
/// The button disables itself for the duration of the action and swaps its label for a
/// spinner only once the action outruns ``progressDelay``, so work that finishes quickly
/// never flashes one.
struct AsyncButton<Label: View>: View {
    /// Under this, a spinner reads as a flicker rather than as feedback.
    private static var progressDelay: Duration {
        .milliseconds(150)
    }

    private let role: ButtonRole?
    private let action: () async -> Void
    private let label: Label

    /// A fresh id per press, `nil` when idle. Both `.task` modifiers below key off it, so
    /// SwiftUI owns starting and cancelling the work — including when the button is torn
    /// down mid-flight, which a hand-rolled `Task` would leak.
    @State private var runID: UUID?
    @State private var showsProgress = false

    init(
        role: ButtonRole? = nil,
        action: @escaping () async -> Void,
        @ViewBuilder label: () -> Label,
    ) {
        self.role = role
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button(role: role) {
            runID = UUID()
        } label: {
            label
                .opacity(showsProgress ? 0 : 1)
                .overlay {
                    if showsProgress {
                        ProgressView()
                    }
                }
        }
        .disabled(runID != nil)
        .task(id: runID) {
            guard runID != nil else { return }
            await action()
            showsProgress = false
            runID = nil
        }
        // Clearing `runID` above cancels this one, so a short action never reaches the
        // assignment and the spinner stays off.
        .task(id: runID) {
            guard runID != nil else { return }
            guard await (try? Task.sleep(for: Self.progressDelay)) != nil else { return }
            showsProgress = true
        }
    }
}

extension AsyncButton where Label == Text {
    init(
        _ titleKey: LocalizedStringKey,
        role: ButtonRole? = nil,
        action: @escaping () async -> Void,
    ) {
        self.init(role: role, action: action) {
            Text(titleKey)
        }
    }
}

#Preview("Slow enough to show a spinner") {
    AsyncButton("Refresh") {
        try? await Task.sleep(for: .seconds(3))
    }
    .buttonStyle(.borderedProminent)
}

#Preview("Too fast to show a spinner") {
    AsyncButton("Refresh") {
        try? await Task.sleep(for: .milliseconds(50))
    }
    .buttonStyle(.borderedProminent)
}

#Preview("Destructive role") {
    AsyncButton(role: .destructive) {
        try? await Task.sleep(for: .seconds(3))
    } label: {
        Label("Delete", systemImage: "trash")
    }
    .buttonStyle(.bordered)
}
