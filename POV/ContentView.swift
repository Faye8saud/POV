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
    @State private var savedEntryDate: Date? = nil
    @State private var pendingLens: (mood: Mood, lens: DirectorLens)? = nil
    @StateObject private var onboardingVM = OnboardingViewModel()

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {

                // Keep ALL tab views alive at all times so onAppear/onChange
                // fire correctly when pendingLens is set from HomeView.
                // Visibility is controlled by opacity — not by recreating views.
                ZStack {
                    NavigationStack {
                        RecordingView(hideTabBar: $hideTabBar, pendingLens: $pendingLens)
                    }
                    .opacity(selectedTab == .record ? 1 : 0)
                    .allowsHitTesting(selectedTab == .record)
                    .zIndex(selectedTab == .record ? 1 : 0)

                    HomeView()
                        .opacity(selectedTab == .home ? 1 : 0)
                        .allowsHitTesting(selectedTab == .home)
                        .zIndex(selectedTab == .home ? 1 : 0)

                    NavigationStack {
                        CalendarView(initialEntryDate: savedEntryDate)
                    }
                    .opacity(selectedTab == .archive ? 1 : 0)
                    .allowsHitTesting(selectedTab == .archive)
                    .zIndex(selectedTab == .archive ? 1 : 0)
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

            if onboardingVM.showOnboarding {
                OnboardingView(viewModel: onboardingVM)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.4), value: onboardingVM.showOnboarding)
                    .zIndex(999)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .environment(\.selectedPOVTab, $selectedTab)
        .environment(\.pendingLens, $pendingLens)
        .environment(\.onSaveComplete, {
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

// MARK: - Environment Key for onSaveComplete
struct OnSaveCompleteKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

// MARK: - Environment Key for pendingLens
struct PendingLensKey: EnvironmentKey {
    static let defaultValue: Binding<(mood: Mood, lens: DirectorLens)?> = .constant(nil)
}

extension EnvironmentValues {
    var selectedPOVTab: Binding<POVTab> {
        get { self[SelectedPOVTabKey.self] }
        set { self[SelectedPOVTabKey.self] = newValue }
    }

    var onSaveComplete: () -> Void {
        get { self[OnSaveCompleteKey.self] }
        set { self[OnSaveCompleteKey.self] = newValue }
    }

    var pendingLens: Binding<(mood: Mood, lens: DirectorLens)?> {
        get { self[PendingLensKey.self] }
        set { self[PendingLensKey.self] = newValue }
    }
}

#Preview {
    ContentView()
}
