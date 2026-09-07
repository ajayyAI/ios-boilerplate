//
//  RootView.swift
//  Scaffold
//

import FactoryKit
import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStack {
            HomeView(viewModel: HomeViewModel(getUser: Container.shared.getUserUseCase()))
        }
        // The one place the app is themed. Point this at your own `Theme` and every screen
        // follows; nothing below reads a colour or a metric from anywhere else. See
        // `Shared/UI/DesignSystem/Theme.swift`.
        .environment(\.theme, .scaffold)
    }
}

#Preview {
    RootView()
}
