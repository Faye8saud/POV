//
//  CalendarModel.swift
//  POV
//
//  Created by Feda on 19/05/2026.
//

import SwiftUI

struct CalendarModel {
    private(set) var orderedMonths: [MemoryMonth]
    private(set) var recentEntries: [MemoryEntry]
    private(set) var selectedCapsuleId: UUID?
    private(set) var selectedMonthId: UUID?

    init(entries: [EntryModel] = []) {
        let videoEntries = entries
            .filter { $0.videoURL != nil }
            .sorted { $0.createdAt > $1.createdAt }

        self.recentEntries = Self.makeRecentEntries(from: Array(videoEntries.prefix(7)))
        self.orderedMonths = Self.makeMonths(from: videoEntries)
        self.selectedMonthId = orderedMonths.first?.id
        self.selectedCapsuleId = recentEntries.first?.id
    }

    var activeEntry: MemoryEntry? {
        guard let selectedCapsuleId else { return nil }
        return recentEntries.first { $0.id == selectedCapsuleId }
    }

    var visibleMonths: [MemoryMonth] {
        guard let selectedMonthId,
              let selectedMonth = orderedMonths.first(where: { $0.id == selectedMonthId }) else {
            return orderedMonths
        }

        return [selectedMonth] + orderedMonths.filter { $0.id != selectedMonthId }
    }

    mutating func update(entries: [EntryModel]) {
        let previousCapsuleId = selectedCapsuleId
        let previousMonthId = selectedMonthId
        let updated = CalendarModel(entries: entries)

        orderedMonths = updated.orderedMonths
        recentEntries = updated.recentEntries
        selectedCapsuleId = recentEntries.contains { $0.id == previousCapsuleId }
            ? previousCapsuleId
            : recentEntries.first?.id
        selectedMonthId = orderedMonths.contains { $0.id == previousMonthId }
            ? previousMonthId
            : orderedMonths.first?.id
    }

    mutating func selectCapsule(_ entry: MemoryEntry) {
        selectedCapsuleId = entry.id
    }

    mutating func selectMonth(_ month: MemoryMonth) {
        selectedMonthId = month.id
    }

    func isSelectedCapsule(_ entry: MemoryEntry) -> Bool {
        selectedCapsuleId == entry.id
    }

    func isSelectedMonth(_ month: MemoryMonth) -> Bool {
        selectedMonthId == month.id
    }

    private static func makeRecentEntries(from entries: [EntryModel]) -> [MemoryEntry] {
        entries.map { entry in
            MemoryEntry(
                id: entry.id,
                shortDate: Self.shortDateFormatter.string(from: entry.date).uppercased(),
                mood: MemoryMood(mood: entry.mood),
                clipCount: max(entry.clips.count, 1)
            )
        }
    }

    private static func makeMonths(from entries: [EntryModel]) -> [MemoryMonth] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.dateComponents([.year, .month], from: entry.date)
        }

        return grouped.compactMap { components, entries in
            guard let monthStart = calendar.date(from: components) else { return nil }
            let sortedEntries = entries.sorted { $0.createdAt > $1.createdAt }
            let monthMood = dominantMoodName(in: sortedEntries)
            let mood = MemoryMood(moodName: monthMood)

            return MemoryMonth(
                id: Self.monthId(for: components),
                month: Self.monthFormatter.string(from: monthStart),
                year: components.year ?? calendar.component(.year, from: monthStart),
                coverImage: "",
                dominantMood: mood,
                entries: makeRecentEntries(from: sortedEntries)
            )
        }
        .sorted { lhs, rhs in
            guard let lhsDate = monthDate(month: lhs), let rhsDate = monthDate(month: rhs) else {
                return lhs.year > rhs.year
            }
            return lhsDate > rhsDate
        }
    }

    private static func dominantMoodName(in entries: [EntryModel]) -> String {
        Dictionary(grouping: entries) { $0.moodName }
            .max { lhs, rhs in lhs.value.count < rhs.value.count }?
            .key ?? entries.first?.moodName ?? POVData.moods.first?.name ?? "Tender"
    }

    private static func monthId(for components: DateComponents) -> UUID {
        let year = components.year ?? 0
        let month = components.month ?? 0
        return UUID(uuidString: String(format: "00000000-0000-0000-0000-%04d%08d", year, month)) ?? UUID()
    }

    private static func monthDate(month: MemoryMonth) -> Date? {
        var components = DateComponents()
        components.year = month.year
        components.month = monthFormatter.shortMonthSymbols.firstIndex(of: month.month).map { $0 + 1 }
        return Calendar.current.date(from: components)
    }

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()
}

struct MemoryMood: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let color: Color
    let accentColor: Color

    init(name: String, color: Color, accentColor: Color) {
        self.name = name
        self.color = color
        self.accentColor = accentColor
    }

    init(mood: Mood?) {
        self.init(
            name: mood?.name ?? "Tender",
            color: mood?.color ?? Color(hex: "A76D78"),
            accentColor: mood?.accentColor ?? Color(hex: "F2B5C0")
        )
    }

    init(moodName: String) {
        self.init(mood: POVData.moods.first { $0.name == moodName })
    }
}

struct MemoryEntry: Identifiable, Hashable {
    let id: UUID
    let shortDate: String
    let mood: MemoryMood
    let clipCount: Int
}

struct MemoryMonth: Identifiable, Hashable {
    let id: UUID
    let month: String
    let year: Int
    let coverImage: String
    let dominantMood: MemoryMood
    let entries: [MemoryEntry]
}
