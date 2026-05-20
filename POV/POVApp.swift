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

    // MARK: - Local container (session + clips — never synced)
    let localContainer: ModelContainer = {
        let schema = Schema([
            RecordingSessionModel.self,
            RecordedClipModel.self
        ])
        do {
            let config = ModelConfiguration(
                "POVLocal",
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            print("Local container failed: \(error)")
            return try! ModelContainer(
                for: schema,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }
    }()

    let cloudContainer: ModelContainer = {
        let schema = Schema([DayEntry.self])
        do {
            let config = ModelConfiguration(
                "POVCloud",
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            print("CloudKit container failed: \(error)")
            return try! ModelContainer(
                for: schema,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }
    }()
    init() {
           print("Local container: \(localContainer)")
           print("Cloud container: \(cloudContainer)")
       }
    
    var body: some Scene {
        WindowGroup {
            ContentView()

                .modelContainer(localContainer)
                .environment(\.cloudModelContext, cloudContainer.mainContext)
                .environment(\.cloudContainer, cloudContainer)

                .preferredColorScheme(.dark)
                .modelContainer(for: [EntryModel.self, RecordedClipModel.self, ReflectionAnswer.self])

        }
    }
}

// MARK: - Environment Key: cloud ModelContext
struct CloudModelContextKey: EnvironmentKey {
    static let defaultValue: ModelContext? = nil
}

extension EnvironmentValues {
    var cloudModelContext: ModelContext? {
        get { self[CloudModelContextKey.self] }
        set { self[CloudModelContextKey.self] = newValue }
    }
}

// MARK: - Environment Key: cloud ModelContainer
struct CloudModelContainerKey: EnvironmentKey {
    // Safe non-optional default using an in-memory DayEntry container
    static let defaultValue: ModelContainer = try! ModelContainer(
        for: DayEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
}

extension EnvironmentValues {
    var cloudContainer: ModelContainer {
        get { self[CloudModelContainerKey.self] }
        set { self[CloudModelContainerKey.self] = newValue }
    }
}
