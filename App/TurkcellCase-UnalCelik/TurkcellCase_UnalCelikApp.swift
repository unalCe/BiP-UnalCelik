//
//  TurkcellCase_UnalCelikApp.swift
//  TurkcellCase-UnalCelik
//
//  Created by Ünal Çelik on 18.09.2026.
//

import AppFeature
import SwiftUI

/// Thin shell. Everything below this line lives in Packages/AppModules —
/// the app target owns only the bundle: entry point, assets, Info.plist,
/// entitlements and signing.
@main
struct TurkcellCase_UnalCelikApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .ignoresSafeArea()
        }
    }
}
