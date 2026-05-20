//
//  HomeModel.swift
//  POV
//
//  Created by Feda on 20/05/2026.
//

import Foundation
import SwiftUI

struct HomeModel {
    var selectedMood: Mood
    var selectedDirector: DirectorLens?
    private var currentDate: Date

    init(
        selectedMood: Mood = POVData.moods.first ?? Mood.fallback,
        selectedDirector: DirectorLens? = nil,
        currentDate: Date = .now
    ) {
        self.selectedMood = selectedMood
        self.selectedDirector = selectedDirector
        self.currentDate = currentDate
    }

    var dateTitle: String {
        Self.dateFormatter.string(from: currentDate).uppercased()
    }

    var directorsForSelectedMood: [DirectorLens] {
        POVData.lenses(for: selectedMood)
    }

    var moodGlowColor: Color {
        selectedMood.color.opacity(0.35)
    }

    mutating func selectDirector(_ director: DirectorLens) {
        selectedDirector = director
    }

    mutating func startDay() {
        selectedDirector = nil
    }

    mutating func refreshDate(_ date: Date = .now) {
        currentDate = date
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE · MMMM d"
        return formatter
    }()
}

private extension Mood {
    static let fallback = Mood(
        name: "Tender",
        description: "soft edges, warm light, quiet attention",
        color: Color(hex: "A76D78"),
        accentColor: Color(hex: "F2B5C0")
    )
}
