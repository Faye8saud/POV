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
    @State private var hideTabBar: Bool = false   // VideoView / ReflectionView raise this

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {

                // MARK: Main Content
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
                            CalendarView()
                        }
                        .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: selectedTab)

                // MARK: Persistent Tab Bar — uses GeometryReader for reliable safe area
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
    }
}

// MARK: - Environment Key for selectedTab
struct SelectedPOVTabKey: EnvironmentKey {
    static let defaultValue: Binding<POVTab> = .constant(.record)
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
