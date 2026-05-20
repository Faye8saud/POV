//
//  POVApp.swift
//  POV
//
//  Created by Fay  on 05/05/2026.
//

import SwiftUI
import SwiftData
 
@main
struct POVApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .modelContainer(for: [EntryModel.self, RecordedClipModel.self, ReflectionAnswer.self])
        }
    }
}
