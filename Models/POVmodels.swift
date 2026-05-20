//
//  POCModels.swift
//  POV
//
//  Created by Fay  on 11/05/2026.
//
import SwiftUI
import Foundation
import SwiftData

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

//SwiftData models
/// MARK: - RecordedClip (SwiftData Model — local only)
@Model
final class RecordedClipModel {
    var id: UUID
    var urlString: String
    var promptIndex: Int
    var directorName: String
    var moodName: String
    var date: Date
 
    var session: RecordingSessionModel?
 
    init(url: URL, promptIndex: Int, directorName: String, moodName: String) {
        self.id = UUID()
        self.urlString = url.absoluteString
        self.promptIndex = promptIndex
        self.directorName = directorName
        self.moodName = moodName
        self.date = Date()
    }
 
    var url: URL { URL(string: urlString) ?? FileManager.default.temporaryDirectory }
}
 
// MARK: - RecordingSession (SwiftData Model — local only)
@Model
final class RecordingSessionModel {
    var phaseRaw: String
    var currentPromptIndex: Int
    var activeMoodName: String
    var activeLensName: String
 
    @Relationship(deleteRule: .cascade, inverse: \RecordedClipModel.session)
    var clips: [RecordedClipModel] = []
 
    var phase: SessionPhase {
        get { SessionPhase(rawValue: phaseRaw) ?? .idle }
        set { phaseRaw = newValue.rawValue }
    }
 
    init() {
        self.phaseRaw = SessionPhase.idle.rawValue
        self.currentPromptIndex = 0
        self.activeMoodName = ""
        self.activeLensName = ""
        self.clips = []
    }
}
 
// MARK: - DayEntry (SwiftData Model — synced to CloudKit)
//
// Represents one completed day vlog entry.
// Only metadata is stored here; the actual video lives on-device at mergedVideoURL.
// All properties are optional-compatible so CloudKit sync works without issues.
@Model
final class DayEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var moodName: String = ""
    var directorName: String = ""
    var directorStyle: String = ""
    var reflectionAnswer1: String = ""
    var reflectionAnswer2: String = ""
    var mergedVideoURL: String = ""

    init(
        date: Date,
        moodName: String,
        directorName: String,
        directorStyle: String,
        reflectionAnswer1: String = "",
        reflectionAnswer2: String = "",
        mergedVideoURL: String
    ) {
        self.id = UUID()
        self.date = date
        self.moodName = moodName
        self.directorName = directorName
        self.directorStyle = directorStyle
        self.reflectionAnswer1 = reflectionAnswer1
        self.reflectionAnswer2 = reflectionAnswer2
        self.mergedVideoURL = mergedVideoURL
    }

    var videoURL: URL? {
        URL(string: mergedVideoURL)
    }

    var hasReflection: Bool {
        !reflectionAnswer1.isEmpty || !reflectionAnswer2.isEmpty
    }
}
