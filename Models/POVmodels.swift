//
//  POCModels.swift
//  POV
//
//  Created by Fay  on 11/05/2026.
//
import SwiftUI

// MARK: - Mood Model
struct Mood: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let color: Color
    let accentColor: Color
}

// MARK: - Director / Lens Model
struct DirectorLens: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let nationality: String
    let styleDescription: String
    let imageName: String           // Asset name — add real photos to xcassets using these names
    let shootingPrompts: [String]   // 4 prompts for what to film today
    let tags: [String]
    let brief: String               // Director's daily brief (spoken directly to user)
    let question1: String           // Yes/no/in own words reflection question
    let question2: String           // Open-ended reflection question
}

// MARK: - JSON Decodable Intermediates
private struct POVDataJSON: Decodable {
    let moods: [MoodJSON]
}

private struct MoodJSON: Decodable {
    let name: String
    let description: String
    let color: String
    let accentColor: String
    let directors: [DirectorJSON]
}

private struct DirectorJSON: Decodable {
    let name: String
    let nationality: String
    let styleDescription: String
    let imageName: String
    let shootingPrompts: [String]
    let tags: [String]
    let brief: String
    let question1: String
    let question2: String
}

// MARK: - Static Data Store
struct POVData {

    // MARK: Loaded data
    static let moods: [Mood] = loaded.map { moodJSON in
        Mood(
            name: moodJSON.name,
            description: moodJSON.description,
            color: Color(hex: moodJSON.color),
            accentColor: Color(hex: moodJSON.accentColor)
        )
    }

    static let lensesByMood: [String: [DirectorLens]] = {
        var dict = [String: [DirectorLens]]()
        for moodJSON in loaded {
            dict[moodJSON.name] = moodJSON.directors.map { d in
                DirectorLens(
                    name: d.name,
                    nationality: d.nationality,
                    styleDescription: d.styleDescription,
                    imageName: d.imageName,
                    shootingPrompts: d.shootingPrompts,
                    tags: d.tags,
                    brief: d.brief,
                    question1: d.question1,
                    question2: d.question2
                )
            }
        }
        return dict
    }()

    static func lenses(for mood: Mood) -> [DirectorLens] {
        lensesByMood[mood.name] ?? []
    }

    // MARK: JSON loader
    private static let loaded: [MoodJSON] = {
        guard
            let url = Bundle.main.url(forResource: "pov_data", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode(POVDataJSON.self, from: data)
        else {
            assertionFailure("POVData: pov_data.json not found in bundle. Add it to the target.")
            return []
        }
        return decoded.moods
    }()
}

// MARK: - Color Hex Helper
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
