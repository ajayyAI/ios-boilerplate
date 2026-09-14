//
//  HomeView.swift
//  Scaffold
//

import SwiftUI

/// The starter's one real screen, and the reference for how a screen is built here: a thin
/// parent that composes sections, each section its own `View` with narrow inputs, and every
/// value read off `\.theme` rather than hardcoded.
struct HomeView: View {
    @Environment(\.theme) private var theme
    @State private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                HomeHeader()

                HomeStateView(state: viewModel.state)

                AsyncButton("Refresh") {
                    await viewModel.refresh()
                }
                .buttonStyle(.primary)
                .accessibilityIdentifier("refreshButton")
            }
            .padding(theme.spacing.xl)
            // The container lives on the content, not on the `ScrollView`: making a
            // `ScrollView` an accessibility container files it under `scrollViews` rather
            // than `otherElements`, and the UI test looks for it in the latter.
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("HomeView")
        }
        .background(theme.color.background)
        .scrollBounceBehavior(.basedOnSize)
        // The screen owns its own heading, so the navigation bar would only contribute an
        // empty strip above it.
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Sections

private struct HomeHeader: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("Home")
                .font(theme.font.screenTitle)
                .foregroundStyle(theme.color.textPrimary)

            Text(
                "A worked example of the data layer: a use case, a repository and two data sources, rendered through one state enum.",
            )
            .font(theme.font.body)
            .foregroundStyle(theme.color.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Renders one state. A separate `View` type rather than a computed property so it forms
/// its own invalidation boundary and takes only the state it reads.
private struct HomeStateView: View {
    let state: HomeViewState

    var body: some View {
        switch state {
        case .empty:
            HomeMessage(
                icon: "person.crop.circle.dashed",
                title: "Nothing loaded yet",
                message: "Tap Refresh to pull the sample user through the stack.",
            )
        case .loading:
            HomeUserCardPlaceholder()
        case let .data(userEmailTitle):
            if let userEmailTitle {
                HomeUserCard(email: userEmailTitle)
            } else {
                HomeMessage(
                    icon: "person.crop.circle.badge.questionmark",
                    title: "No user",
                    message: "The request succeeded but came back without one.",
                )
            }
        case let .failed(error):
            HomeMessage(
                icon: "exclamationmark.triangle",
                title: "Couldn't load",
                message: error.message,
                isError: true,
            )
        }
    }
}

/// The loaded state.
///
/// The label is "Example user", not "Signed in as": there is no authentication anywhere in
/// this starter, and copy that implies a session someone has to go and disprove is worse
/// than no copy. `UserRemoteDataSource` returns a fixed address after a one-second sleep.
private struct HomeUserCard: View {
    @Environment(\.theme) private var theme

    let email: String

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text("Example user")
                .font(theme.font.caption)
                .foregroundStyle(theme.color.textSecondary)

            Text(email)
                .font(theme.font.body)
                .foregroundStyle(theme.color.textPrimary)
                .accessibilityIdentifier("userEmailLabel")
        }
        .card()
    }
}

/// The loading state, shaped like the card it is about to become so the layout does not
/// jump when the data lands.
///
/// Deliberately carries no accessibility identifier: a placeholder that answered to
/// `userEmailLabel` would let a UI test read redacted text as if it were the email.
private struct HomeUserCardPlaceholder: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text("Example user")
                .font(theme.font.caption)

            Text(verbatim: "placeholder@example.com")
                .font(theme.font.body)
        }
        .redacted(reason: .placeholder)
        .card()
        .accessibilityElement()
        .accessibilityLabel("Loading")
    }
}

/// Every state that is not the data: empty, no user, failed. One view because they differ
/// only in what they say, and giving each its own layout is how three states drift into
/// three slightly different screens.
private struct HomeMessage: View {
    @Environment(\.theme) private var theme

    let icon: String
    let title: LocalizedStringKey
    let message: String
    var isError = false

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isError ? theme.color.danger : theme.color.textSecondary)

            Text(title)
                .font(theme.font.sectionTitle)
                .foregroundStyle(theme.color.textPrimary)

            Text(message)
                .font(theme.font.caption)
                .foregroundStyle(theme.color.textSecondary)
        }
        .card()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews

#Preview("Data") {
    NavigationStack {
        HomeView(viewModel: .preview(state: .data(userEmailTitle: "hello@example.com")))
    }
}

#Preview("Data — dark") {
    NavigationStack {
        HomeView(viewModel: .preview(state: .data(userEmailTitle: "hello@example.com")))
    }
    .preferredColorScheme(.dark)
}

#Preview("Loading") {
    NavigationStack {
        HomeView(viewModel: .preview(state: .loading))
    }
}

#Preview("Empty") {
    NavigationStack {
        HomeView(viewModel: .preview(state: .empty))
    }
}

#Preview("Error") {
    NavigationStack {
        HomeView(
            viewModel: .preview(
                state: .failed(PresentableError(message: "The Internet connection appears to be offline.")),
            ),
        )
    }
}
