//
//  TurkcellCase_UnalCelikApp.swift
//  TurkcellCase-UnalCelik
//
//  Created by Ünal Çelik on 18.09.2026.
//

import SwiftUI
import CoreData

@main
struct TurkcellCase_UnalCelikApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
