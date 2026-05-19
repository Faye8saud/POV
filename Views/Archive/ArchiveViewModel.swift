//
//  ArchiveViewModel.swift
//  POV
//
//  Created by Fajer alQahtani on 02/12/1447 AH.
//
import Foundation
import SwiftUI
import SwiftData
import Combine

// MARK: - Archive Tab

enum ArchiveTab: String, CaseIterable {
    case days     = "Days"
    case lenses   = "Lenses"
    case feelings = "Feelings"
}

// MARK: - ArchiveViewModel

@MainActor
final class ArchiveViewModel: ObservableObject {

    @Published var selectedTab: ArchiveTab = .days
    @Published var currentMonth: Date = Calendar.current.startOfMonth(for: .now)

    // MARK: - Entry filters

    func dayEntries(from entries: [EntryModel]) -> [EntryModel] {
        entries
            .filter { isInCurrentMonth($0.date) && $0.isCompleted }
            .sorted { $0.date > $1.date }
    }

    func lensGroups(from entries: [EntryModel]) -> [(lensName: String, entries: [EntryModel])] {
        let filtered = entries.filter { isInCurrentMonth($0.date) && $0.isCompleted }
        let grouped = Dictionary(grouping: filtered) { $0.lensName }
        return grouped
            .map { (lensName: $0.key, entries: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.lensName < $1.lensName }
    }

    func feelingGroups(from entries: [EntryModel]) -> [(moodName: String, entries: [EntryModel])] {
        let filtered = entries.filter { isInCurrentMonth($0.date) && $0.isCompleted }
        let grouped = Dictionary(grouping: filtered) { $0.moodName }
        return grouped
            .map { (moodName: $0.key, entries: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.moodName < $1.moodName }
    }

    // MARK: - Month navigation

    var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f.string(from: currentMonth)
    }

    func goToPreviousMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }

    func goToNextMonth() {
        let next = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        if next <= Calendar.current.startOfMonth(for: .now) {
            currentMonth = next
        }
    }

    var canGoForward: Bool {
        currentMonth < Calendar.current.startOfMonth(for: .now)
    }

    private func isInCurrentMonth(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }
}

// MARK: - Calendar helper

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
