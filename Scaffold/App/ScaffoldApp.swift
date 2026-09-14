//
//  ScaffoldApp.swift
//  Scaffold
//

import SwiftUI

@main
struct ScaffoldApp: App {
    @UIApplicationDelegateAdaptor var appDelegate: ScaffoldAppDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
