//
//  RootView.swift
//  TemplateApp
//
//

import SwiftUI
import FactoryKit

struct RootView: View {
    var body: some View {
        NavigationStack {
            HomeView(viewModel: HomeViewModel(getUser: Container.shared.getUserUseCase()))
        }
    }
}

#Preview {
    RootView()
}
