//
//  CalendarModel.swift
//  POV
//
//  Created by Feda on 19/05/2026.
//

import SwiftUI

struct CalendarModel {
    private(set) var orderedMonths: [MemoryMonth]
    private(set) var selectedCapsuleId: UUID?
    private(set) var selectedMonthId: UUID?

    init(months: [MemoryMonth] = MemoryMonth.sampleMonths) {
        self.orderedMonths = months
        self.selectedMonthId = months.first?.id
        self.selectedCapsuleId = months.flatMap(\.entries).first?.id
    }

    var recentEntries: [MemoryEntry] {
        orderedMonths.flatMap(\.entries)
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
}

struct MemoryEntry: Identifiable, Hashable {
    let id = UUID()
    let shortDate: String
    let mood: MemoryMood
    let clipCount: Int
}

struct MemoryMonth: Identifiable, Hashable {
    let id = UUID()
    let month: String
    let year: Int
    let coverImage: String
    let dominantMood: MemoryMood
    let entries: [MemoryEntry]
}

private extension MemoryMood {
    static let tender = MemoryMood(name: "Tender", color: Color(hex: "A76D78"), accentColor: Color(hex: "F2B5C0"))
    static let restless = MemoryMood(name: "Restless", color: Color(hex: "5F5390"), accentColor: Color(hex: "9FA8DA"))
    static let wandering = MemoryMood(name: "Wandering", color: Color(hex: "688181"), accentColor: Color(hex: "A8C5B5"))
    static let charged = MemoryMood(name: "Charged", color: Color(hex: "A62228"), accentColor: Color(hex: "C23441"))
    static let playful = MemoryMood(name: "Playful", color: Color(hex: "CA792B"), accentColor: Color(hex: "C89452"))
}

extension MemoryMonth {
    static let sampleMonths: [MemoryMonth] = [
        MemoryMonth(month: "Aug", year: 2026, coverImage: "calendar-august", dominantMood: .tender, entries: [
            MemoryEntry(shortDate: "AUG 5", mood: .tender, clipCount: 8),
            MemoryEntry(shortDate: "AUG 20", mood: .playful, clipCount: 4)
        ]),
        MemoryMonth(month: "Apr", year: 2026, coverImage: "calendar-april", dominantMood: .restless, entries: [
            MemoryEntry(shortDate: "APR 30", mood: .restless, clipCount: 5),
            MemoryEntry(shortDate: "APR 5", mood: .wandering, clipCount: 3)
        ]),
        MemoryMonth(month: "May", year: 2026, coverImage: "calendar-may", dominantMood: .charged, entries: [
            MemoryEntry(shortDate: "MAY 1", mood: .charged, clipCount: 12),
            MemoryEntry(shortDate: "MAY 18", mood: .tender, clipCount: 6)
        ]),
        MemoryMonth(month: "Jun", year: 2026, coverImage: "calendar-june", dominantMood: .wandering, entries: [
            MemoryEntry(shortDate: "JUN 8", mood: .wandering, clipCount: 7),
            MemoryEntry(shortDate: "JUN 21", mood: .playful, clipCount: 9)
        ])
    ]
}
