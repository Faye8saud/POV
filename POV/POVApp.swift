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

    // MARK: - Cloud container (DayEntry — synced to CloudKit)
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

    var body: some Scene {
        WindowGroup {
            ContentView()
                // cloudContainer is primary so @Query(DayEntry) works in CalendarView
                .modelContainer(cloudContainer)
                // localContainer passed explicitly for RecordingView
                .environment(\.localModelContainer, localContainer)
                .environment(\.cloudModelContext, cloudContainer.mainContext)
                .environment(\.cloudContainer, cloudContainer)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Environment Key: local ModelContainer (clips + sessions)
// Uses Optional to avoid a try! at declaration time
struct LocalModelContainerKey: EnvironmentKey {
    static let defaultValue: ModelContainer? = nil
}

extension EnvironmentValues {
    var localModelContainer: ModelContainer? {
        get { self[LocalModelContainerKey.self] }
        set { self[LocalModelContainerKey.self] = newValue }
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
    static let defaultValue: ModelContainer? = nil
}

extension EnvironmentValues {
    var cloudContainer: ModelContainer? {
        get { self[CloudModelContainerKey.self] }
        set { self[CloudModelContainerKey.self] = newValue }
    }
}
