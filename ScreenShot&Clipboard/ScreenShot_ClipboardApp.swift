//
//  ScreenShot_ClipboardApp.swift
//  ScreenShot&Clipboard
//
//  Created by 原神高手 on 3/24/2026.
//

import SwiftUI
import SwiftData

@main
struct ScreenShot_ClipboardApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
