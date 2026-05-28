//
//  TemplateAppApp.swift
//  TemplateApp
//
//

import SwiftUI

@main
struct TemplateAppApp: App {
    @UIApplicationDelegateAdaptor var appDelegate: TemplateAppAppDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
