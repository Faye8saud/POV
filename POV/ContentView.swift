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
    @Environment(\.cloudContainer) private var cloudContainer

    var body: some View {
        ZStack {
            switch selectedTab {
            case .record:
                NavigationStack {
                    RecordingView()
                }
                .transition(.opacity)

            case .home:
                HomeView()
                    .transition(.opacity)

            case .archive:
                // Inject cloud container so @Query inside ArchiveView finds DayEntry
                ArchiveView()
                    .modelContainer(cloudContainer)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedTab)
        .environment(\.selectedPOVTab, $selectedTab)
    }
}

// MARK: - Archive View
// Functional stub — fetches real DayEntry records from CloudKit.
// Replace the list with your full calendar design later.
/*struct ArchiveView: View {

    @Environment(\.selectedPOVTab) private var selectedTab
    @Query(sort: \DayEntry.date, order: .reverse) private var entries: [DayEntry]

    var body: some View {
        ZStack {
            Color(white: 0.06).ignoresSafeArea()

            VStack(spacing: 0) {

                // Header
                HStack {
                    Text("Archive")
                        .font(.custom("Georgia-Italic", size: 28))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 20)

                if entries.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "film.stack")
                            .font(.system(size: 42))
                            .foregroundStyle(.white.opacity(0.2))
                        Text("No entries yet")
                            .font(.custom("Georgia-Italic", size: 18))
                            .foregroundStyle(.white.opacity(0.35))
                        Text("Finish your first vlog to see it here.")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(.white.opacity(0.25))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(entries) { entry in
                                ArchiveEntryRow(entry: entry)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 120)
                    }
                }

                Spacer()

                POVTabBar(selectedTab: selectedTab, isRecording: false)
                    .padding(.bottom, 34)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Archive Entry Row
private struct ArchiveEntryRow: View {
    let entry: DayEntry

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.white.opacity(0.08))
                .frame(width: 80, height: 60)
                .overlay(
                    Image(systemName: "play.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.4))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate(entry.date))
                    .font(.custom("Georgia-Italic", size: 16))
                    .foregroundStyle(.white)
                Text("\(entry.directorName) · \(entry.directorStyle)")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
                Text(entry.moodName.uppercased())
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
                    .tracking(1.2)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d"
        return f.string(from: date)
    }
}
*/
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
