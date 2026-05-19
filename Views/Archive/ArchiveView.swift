//
//  ArchiveView.swift
//  POV
//
//  Created by Fajer alQahtani on 02/12/1447 AH.
//

import SwiftUI
import SwiftData
import AVKit

// MARK: - ArchiveView

struct ArchiveView: View {
    @StateObject private var vm = ArchiveViewModel()
    @Query(sort: \EntryModel.createdAt, order: .reverse) private var entries: [EntryModel]
    @State private var selectedEntry: EntryModel? = nil

    var body: some View {
        ZStack {
            Color("background 1").ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                tabBar
                Divider()
                    .background(Color("text 2").opacity(0.12))

                ScrollView {
                    LazyVStack(spacing: 12) {
                        switch vm.selectedTab {
                        case .days:     daysContent
                        case .lenses:   lensesContent
                        case .feelings: feelingsContent
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(item: $selectedEntry) { entry in
            ArchiveEntryDetailView(entry: entry)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                // Back button
                Button(action: {}) {
                    Circle()
                        .fill(Color("cards"))
                        .frame(width: 38, height: 38)
                        .overlay(
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(Color("text 1"))
                        )
                }

                Spacer()

                // Month chevrons
                HStack(spacing: 20) {
                    Button(action: vm.goToPreviousMonth) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13))
                            .foregroundColor(Color("text 2"))
                    }
                    Button(action: vm.goToNextMonth) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13))
                            .foregroundColor(vm.canGoForward
                                ? Color("text 2")
                                : Color("text 2").opacity(0.25))
                    }
                    .disabled(!vm.canGoForward)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            // Large italic month title
            Text(vm.monthTitle)
                .font(.custom("Georgia-Italic", size: 52))
                .foregroundColor(Color("text 1"))
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 12)
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(ArchiveTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) { vm.selectedTab = tab }
                }) {
                    VStack(spacing: 6) {
                        Text(tab.rawValue)
                            .font(.system(size: 14,
                                          weight: vm.selectedTab == tab ? .medium : .regular))
                            .foregroundColor(vm.selectedTab == tab
                                ? Color("text 1")
                                : Color("text 2"))
                            .frame(maxWidth: .infinity)

                        Rectangle()
                            .fill(vm.selectedTab == tab ? Color("text 1") : Color.clear)
                            .frame(height: 1)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
    }

    // MARK: - Days Tab

    @ViewBuilder
    private var daysContent: some View {
        let list = vm.dayEntries(from: entries)
        if list.isEmpty {
            emptyState(message: "No films recorded in \(vm.monthTitle).")
        } else {
            ForEach(list) { entry in
                EntryCard(entry: entry)
                    .onTapGesture { selectedEntry = entry }
            }
        }
    }

    // MARK: - Lenses Tab

    @ViewBuilder
    private var lensesContent: some View {
        let groups = vm.lensGroups(from: entries)
        if groups.isEmpty {
            emptyState(message: "No films recorded in \(vm.monthTitle).")
        } else {
            ForEach(groups, id: \.lensName) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.lensName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("text 2"))
                        .padding(.top, 8)

                    ForEach(group.entries) { entry in
                        EntryCard(entry: entry)
                            .onTapGesture { selectedEntry = entry }
                    }
                }
            }
        }
    }

    // MARK: - Feelings Tab

    @ViewBuilder
    private var feelingsContent: some View {
        let groups = vm.feelingGroups(from: entries)
        if groups.isEmpty {
            emptyState(message: "No films recorded in \(vm.monthTitle).")
        } else {
            ForEach(groups, id: \.moodName) { group in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        // Mood color dot from POVData
                        if let mood = POVData.moods.first(where: { $0.name == group.moodName }) {
                            Circle()
                                .fill(mood.color)
                                .frame(width: 8, height: 8)
                        }
                        Text(group.moodName.uppercased())
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color("text 2"))
                            .kerning(1.5)
                    }
                    .padding(.top, 8)

                    ForEach(group.entries) { entry in
                        EntryCard(entry: entry)
                            .onTapGesture { selectedEntry = entry }
                    }
                }
            }
        }
    }

    // MARK: - Empty state

    private func emptyState(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "film")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundColor(Color("text 2").opacity(0.35))
            Text(message)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(Color("text 2").opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

// MARK: - Entry Card

private struct EntryCard: View {
    let entry: EntryModel

    // Pull live data from POVData
    private var mood: Mood? {
        POVData.moods.first { $0.name == entry.moodName }
    }
    private var lens: DirectorLens? {
        POVData.lensesByMood.values.flatMap { $0 }.first { $0.name == entry.lensName }
    }

    private var dayString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d"
        return f.string(from: entry.date)
    }

    // First tag from DirectorLens as the style label
    private var styleTag: String {
        lens?.tags.first ?? ""
    }

    var body: some View {
        HStack(spacing: 14) {

            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(mood?.color.opacity(0.35) ?? Color("cards"))
                    .frame(width: 110, height: 80)

                if let url = entry.videoURL {
                    VideoThumbnailView(url: url)
                        .frame(width: 110, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: "play.circle")
                        .font(.system(size: 22, weight: .ultraLight))
                        .foregroundColor(.white.opacity(0.35))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(mood?.color.opacity(0.6) ?? Color.clear, lineWidth: 2)
            )

            // Meta
            VStack(alignment: .leading, spacing: 5) {
                Text(dayString)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color("text 1"))

                if !styleTag.isEmpty {
                    Text("\(entry.lensName) • \(styleTag)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color("text 2"))
                } else {
                    Text(entry.lensName)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color("text 2"))
                }

                Text(entry.moodName.uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(mood?.color ?? Color("text 2"))
                    .kerning(1.2)
                    .padding(.top, 2)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("cards"))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(mood?.accentColor.opacity(0.2) ?? Color.clear, lineWidth: 1)
                )
        )
    }
}

// MARK: - Video Thumbnail

private struct VideoThumbnailView: View {
    let url: URL
    @State private var thumbnail: UIImage? = nil

    var body: some View {
        Group {
            if let image = thumbnail {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color("cards").onAppear { generateThumbnail() }
            }
        }
    }

    private func generateThumbnail() {
        Task.detached(priority: .background) {
            let asset = AVAsset(url: url)
            let gen = AVAssetImageGenerator(asset: asset)
            gen.appliesPreferredTrackTransform = true
            gen.maximumSize = CGSize(width: 220, height: 160)
            if let cgImage = try? gen.copyCGImage(at: .zero, actualTime: nil) {
                let img = UIImage(cgImage: cgImage)
                await MainActor.run { thumbnail = img }
            }
        }
    }
}

// MARK: - Entry Detail Sheet

struct ArchiveEntryDetailView: View {
    let entry: EntryModel
    @Environment(\.dismiss) private var dismiss

    private var mood: Mood? {
        POVData.moods.first { $0.name == entry.moodName }
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: entry.date).uppercased()
    }

    var body: some View {
        ZStack {
            Color("background 1").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Close
                    HStack {
                        Button(action: { dismiss() }) {
                            Circle()
                                .fill(Color("cards"))
                                .frame(width: 38, height: 38)
                                .overlay(
                                    Image(systemName: "xmark")
                                        .font(.system(size: 13, weight: .light))
                                        .foregroundColor(Color("text 1"))
                                )
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                    // Date
                    Text(formattedDate)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color("text 2"))
                        .kerning(1.5)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 6)

                    // Lens
                    Text("In the lens of \(entry.lensName)")
                        .font(.custom("Georgia-Italic", size: 22))
                        .foregroundColor(Color("text 1"))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                    // Mood badge
                    Text(entry.moodName.uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(mood?.color ?? Color("text 2"))
                        .kerning(1.5)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)

                    // Reflections
                    if !entry.reflections.isEmpty {
                        VStack(alignment: .leading, spacing: 24) {
                            ForEach(entry.reflections) { reflection in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(reflection.questionText)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color("text 2"))

                                    Text(reflection.answerText)
                                        .font(.system(size: 16, weight: .light))
                                        .foregroundColor(Color("text 1"))
                                        .lineSpacing(4)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ArchiveView()
        .modelContainer(
            for: [EntryModel.self, RecordedClipModel.self, ReflectionAnswer.self],
            inMemory: true
        )
}
