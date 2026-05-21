//
//  ContentView.swift
//  POV
//
//  Created by Fay  on 05/05/2026.
//
import SwiftUI
import SwiftData

// MARK: - Content View (App Root)
struct ContentView: View {

    @State private var selectedTab: POVTab = .record
    @State private var hideTabBar: Bool = false
    @State private var savedEntryDate: Date? = nil     // ← add this

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {

                Group {
                    switch selectedTab {
                    case .record:
                        NavigationStack {
                            RecordingView(hideTabBar: $hideTabBar)
                        }
                        .transition(.opacity)

                    case .home:
                        HomeView()
                            .transition(.opacity)

                    case .archive:
                        NavigationStack {
                            CalendarView(initialEntryDate: savedEntryDate)  // ← pass date
                        }
                        .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: selectedTab)

                if !hideTabBar {
                    POVTabBar(selectedTab: $selectedTab, isRecording: false)
                        .padding(.bottom, geo.safeAreaInsets.bottom + 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.22), value: hideTabBar)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .ignoresSafeArea(edges: .bottom)
        .environment(\.selectedPOVTab, $selectedTab)
        .environment(\.onSaveComplete, {          // ← add this environment action
            hideTabBar = false
            savedEntryDate = Date()
            selectedTab = .archive
        })
    }
}

// MARK: - Environment Key for selectedTab
struct SelectedPOVTabKey: EnvironmentKey {
    static let defaultValue: Binding<POVTab> = .constant(.record)
}

struct OnSaveCompleteKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var onSaveComplete: () -> Void {
        get { self[OnSaveCompleteKey.self] }
        set { self[OnSaveCompleteKey.self] = newValue }
    }
}

extension EnvironmentValues {
    var selectedPOVTab: Binding<POVTab> {
        get { self[SelectedPOVTabKey.self] }
        set { self[SelectedPOVTabKey.self] = newValue }
    }
}

#Preview {
    ContentView()
}
