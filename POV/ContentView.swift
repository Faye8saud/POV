//
//  ContentView.swift
//  POV
//
//  Created by Fay  on 05/05/2026.
//

import SwiftUI
 
// MARK: - Content View (App Root)
/// Hosts RecordingView as the starting screen.
/// Replace the placeholder stubs with real HomeView / ArchiveView when built.
struct ContentView: View {
 
    @State private var selectedTab: POVTab = .record
 
    var body: some View {
        ZStack {
            switch selectedTab {
            case .record:
                RecordingView()
                    .transition(.opacity)
 
            case .home:
                // TODO: Replace with real HomeView()
                placeholderScreen(title: "Home", icon: "house.fill")
                    .transition(.opacity)
 
            case .archive:
                // TODO: Replace with real ArchiveView()
                placeholderScreen(title: "Archive", icon: "calendar")
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedTab)
        // Expose tab selection to child views via environment if needed
        .environment(\.selectedPOVTab, $selectedTab)
    }
 
    @ViewBuilder
    private func placeholderScreen(title: String, icon: String) -> some View {
        ZStack {
            Color(white: 0.06).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.3))
                Text(title)
                    .font(.custom("Georgia-Italic", size: 22))
                    .foregroundStyle(.white.opacity(0.5))
                Button("Back to Camera") {
                    withAnimation { selectedTab = .record }
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.top, 8)
            }
        }
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
 
