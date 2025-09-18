//
//  InternalAppStoreApp.swift
//  InternalAppStore
//
//  Created by Tariq AlMazyad on 18/09/2025.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        Auth.auth().signInAnonymously()
        return true
    }
}


@main
struct InternalAppStoreApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            AppsListView()
        }
    }
}
