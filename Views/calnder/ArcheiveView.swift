//
//  ArcheiveView.swift
//  POV
//
//  Created by Fay  on 19/05/2026.
//

import SwiftUI
import SwiftData

// MARK: - Archive View
/*struct ArchiveView: View {

    @Environment(\.selectedPOVTab) private var selectedTab
    @Query(sort: \DayEntry.date, order: .reverse) private var entries: [DayEntry]

    var body: some View {
        NavigationStack {
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
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 12) {
                                ForEach(entries) { entry in
                                    NavigationLink(destination: ArchiveDetailView(entry: entry)) {
                                        ArchiveEntryRow(entry: entry)
                                    }
                                    .buttonStyle(.plain)
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
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Archive Entry Row
struct ArchiveEntryRow: View {
    let entry: DayEntry

    private var hasReflection: Bool {
        !entry.reflectionAnswer1.isEmpty || !entry.reflectionAnswer2.isEmpty
    }

    var body: some View {
        HStack(spacing: 14) {

            // Thumbnail placeholder (swap for real thumbnail later)
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

                HStack(spacing: 8) {
                    Text(entry.moodName.uppercased())
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                        .tracking(1.2)

                    // Reflection badge
                    if !hasReflection {
                        Text("REFLECT")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color(white: 0.06))
                            .tracking(1.0)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule().fill(.white.opacity(0.6))
                            )
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.2))
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
