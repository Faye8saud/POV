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

    let month: MonthGroup

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.cloudModelContext) private var cloudContext

    @State private var entryPendingDelete: DayEntry? = nil
    @State private var selectedEntry: DayEntry? = nil

    // Live query filtered to this month — updates instantly when entries are deleted
    @Query private var allEntries: [DayEntry]

    init(month: MonthGroup) {
        self.month = month
        // Filter to entries whose date falls within this month/year
        let cal = Calendar.current
        let startComponents = DateComponents(year: month.year, month: cal.component(.month, from: month.entries.first?.date ?? Date()))
        // Use month name + year to build the date range
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let refDate = formatter.date(from: "\(month.monthName) \(month.year)") ?? Date()
        let start = cal.date(from: cal.dateComponents([.year, .month], from: refDate)) ?? refDate
        let end   = cal.date(byAdding: .month, value: 1, to: start) ?? refDate
        _allEntries = Query(
            filter: #Predicate<DayEntry> { entry in
                entry.date >= start && entry.date < end
            },
            sort: \.date,
            order: .reverse
        )
    }

    private var entries: [DayEntry] { allEntries }

    var body: some View {
        ZStack {
            Color("background 1").ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                if entries.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(entries) { entry in
                            ArchiveEntryRow(entry: entry)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedEntry = entry }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .none) {
                                        entryPendingDelete = entry
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                                .listRowInsets(EdgeInsets(top: 6, leading: 24, bottom: 6, trailing: 24))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        // Bottom padding row so last entry clears the tab bar
                        Color.clear
                            .frame(height: 100)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(item: $selectedEntry) { entry in
            ArchiveDetailView(entry: entry)
        }
        .alert("Delete this film?", isPresented: .init(
            get: { entryPendingDelete != nil },
            set: { if !$0 { entryPendingDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let entry = entryPendingDelete {
                    deleteEntry(entry)
                }
                entryPendingDelete = nil
            }
            Button("Cancel", role: .cancel) {
                entryPendingDelete = nil
            }
        } message: {
            Text("This will permanently remove the film and its reflection. This can't be undone.")
        }
    }

    // MARK: - Delete
    private func deleteEntry(_ entry: DayEntry) {
        // Delete the merged video file from disk
        if !entry.mergedVideoURL.isEmpty {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let filename: String
            if entry.mergedVideoURL.contains("/"),
               let url = URL(string: entry.mergedVideoURL), url.scheme != nil {
                filename = url.lastPathComponent
            } else if entry.mergedVideoURL.contains("/") {
                filename = (entry.mergedVideoURL as NSString).lastPathComponent
            } else {
                filename = entry.mergedVideoURL
            }
            let fileURL = docs.appendingPathComponent(filename)
            try? FileManager.default.removeItem(at: fileURL)
        }

        let context = cloudContext ?? modelContext
        context.delete(entry)
        try? context.save()
    }

    // Derived from live @Query entries so it updates immediately after deletion
    private var liveDominantMood: Mood? {
        var counts: [String: Int] = [:]
        for entry in entries {
            counts[entry.moodName, default: 0] += 1
        }
        guard let topName = counts.max(by: { $0.value < $1.value })?.key else { return nil }
        return POVData.moods.first { $0.name == topName }
    }

    // MARK: - Header
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
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

                Text("\(entries.count) \(entries.count == 1 ? "day" : "days")")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Color("text 2"))
                    .tracking(1)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Text(month.monthName)
                .font(.custom("Georgia-Italic", size: 52))
                .foregroundColor(Color("text 1"))
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom , 14)

            if let dominant = liveDominantMood {
                moodStrip(dominant: dominant)
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 14)
            }

            Divider()
                .background(Color("text 2").opacity(0.12))
        }
    }

    // MARK: - Mood Strip
    private func moodStrip(dominant: Mood) -> some View {
        let counts = moodCounts()
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(counts, id: \.name) { item in
                    HStack(spacing: 5) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 6, height: 6)
                        Text(item.name.uppercased())
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color("text 2"))
                            .kerning(1.2)
                            .fixedSize()
                        Text("×\(item.count)")
                            .font(.system(size: 10))
                            .foregroundColor(Color("text 2").opacity(0.5))
                            .fixedSize()
                    }
                }
            }
        }
    }

    private func moodCounts() -> [(name: String, color: Color, count: Int)] {
        var counts: [String: (Color, Int)] = [:]
        for entry in entries {
            if let mood = POVData.moods.first(where: { $0.name == entry.moodName }) {
                counts[entry.moodName] = (mood.color, (counts[entry.moodName]?.1 ?? 0) + 1)
            }
        }
        return counts.map { (name: $0.key, color: $0.value.0, count: $0.value.1) }
            .sorted { $0.count > $1.count }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "film.stack")
                .font(.system(size: 42))
                .foregroundStyle(Color("text 2").opacity(0.2))
            Text("No films for \(month.monthName)")
                .font(.custom("Georgia-Italic", size: 18))
                .foregroundStyle(Color("text 2").opacity(0.45))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Archive Entry Row
struct ArchiveEntryRow: View {
    let entry: DayEntry

    private var mood: Mood? {
        POVData.moods.first { $0.name == entry.moodName }
    }

    private var lens: DirectorLens? {
        POVData.lensesByMood.values.flatMap { $0 }.first { $0.name == entry.directorName }
    }

    var body: some View {
        HStack(spacing: 14) {

            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(mood?.color.opacity(0.25) ?? Color("cards"))
                    .frame(width: 80, height: 60)

                if let url = entry.videoURL {
                    VideoThumbnailView(url: url)
                        .frame(width: 80, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(mood?.color.opacity(0.5) ?? Color.clear, lineWidth: 1.5)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate(entry.date))
                    .font(.custom("Georgia-Italic", size: 16))
                    .foregroundStyle(Color("text 1"))

                Text("\(entry.directorName) · \(lens?.tags.first ?? entry.directorStyle)")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Color("text 2"))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(entry.moodName.uppercased())
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(mood?.color ?? Color("text 2"))
                        .kerning(1.2)

                    if !entry.hasReflection {
                        Text("REFLECT")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color("background 1"))
                            .kerning(1.0)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(.white.opacity(0.6)))
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color("text 2").opacity(0.3))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color("cards"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(mood?.accentColor.opacity(0.15) ?? Color.clear, lineWidth: 1)
                )
        )
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d"
        return f.string(from: date)
    }
}

// MARK: - Archive Entry Detail Sheet
struct ArchiveEntryDetailView: View {
    let entry: DayEntry
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

                    Text(formattedDate)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color("text 2"))
                        .kerning(1.5)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 6)

                    Text("In the lens of \(entry.directorName)")
                        .font(.custom("Georgia-Italic", size: 22))
                        .foregroundColor(Color("text 1"))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                    Text(entry.moodName.uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(mood?.color ?? Color("text 2"))
                        .kerning(1.5)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)

                    if let url = entry.videoURL {
                        VideoPlayer(player: AVPlayer(url: url))
                            .frame(height: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal, 20)
                            .padding(.bottom, 28)
                    }

                    if entry.hasReflection {
                        VStack(alignment: .leading, spacing: 24) {
                            if !entry.reflectionAnswer1.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Question 1")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color("text 2"))
                                    Text(entry.reflectionAnswer1)
                                        .font(.system(size: 16, weight: .light))
                                        .foregroundColor(Color("text 1"))
                                        .lineSpacing(4)
                                }
                            }
                            if !entry.reflectionAnswer2.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Question 2")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color("text 2"))
                                    Text(entry.reflectionAnswer2)
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
            gen.maximumSize = CGSize(width: 160, height: 120)
            if let cgImage = try? gen.copyCGImage(at: .zero, actualTime: nil) {
                let img = UIImage(cgImage: cgImage)
                await MainActor.run { thumbnail = img }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ArchiveView(month: MonthGroup(monthName: "May", year: 2026, entries: []))
    }
    .modelContainer(for: [DayEntry.self, RecordedClipModel.self, RecordingSessionModel.self], inMemory: true)
}
