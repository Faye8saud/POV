//
//  RecordingSession.swift
//  POV
//
//  Created by Fay  on 13/05/2026.
//
import Foundation
import Combine

// MARK: - Recorded Clip
struct RecordedClip: Identifiable, Codable {
    let id: UUID
    let url: URL
    let promptIndex: Int        // which prompt this clip was shot for
    let directorName: String
    let moodName: String
    let date: Date

    init(url: URL, promptIndex: Int, directorName: String, moodName: String) {
        self.id = UUID()
        self.url = url
        self.promptIndex = promptIndex
        self.directorName = directorName
        self.moodName = moodName
        self.date = Date()
    }
}

// MARK: - Session State
enum SessionPhase: String, Codable {
    case idle           // no recording started, mood picker visible
    case shooting       // recording in progress, prompts showing
    case wrapping       // all prompts done, wrap-up message
}

// MARK: - Recording Session (persisted)
final class RecordingSession: ObservableObject, Codable {

    // MARK: Published
    @Published var phase: SessionPhase      = .idle
    @Published var clips: [RecordedClip]    = []
    @Published var currentPromptIndex: Int  = 0
    @Published var activeMoodName: String   = ""
    @Published var activeLensName: String   = ""

    // MARK: - Computed
    var isIdle: Bool       { phase == .idle }
    var isShooting: Bool   { phase == .shooting }
    var isWrapping: Bool   { phase == .wrapping }

    var currentPrompt: String? {
        guard let prompts = currentPrompts, currentPromptIndex < prompts.count else { return nil }
        return prompts[currentPromptIndex]
    }

    var promptsRemaining: Int {
        (currentPrompts?.count ?? 0) - currentPromptIndex
    }

    var currentPrompts: [String]? {
        POVData.moods
            .first { $0.name == activeMoodName }
            .flatMap { POVData.lenses(for: $0).first { $0.name == activeLensName } }
            .map { $0.shootingPrompts }
    }

    // MARK: - Actions

    /// Call when user taps a lens to begin a session
    func startSession(mood: Mood, lens: DirectorLens) {
        // Switching director always clears clips
        clips = []
        currentPromptIndex = 0
        activeMoodName = mood.name
        activeLensName = lens.name
        phase = .shooting
        save()
    }

    /// Call after a clip finishes recording
    func addClip(url: URL) {
        let clip = RecordedClip(
            url: url,
            promptIndex: currentPromptIndex,
            directorName: activeLensName,
            moodName: activeMoodName
        )
        clips.append(clip)

        // Advance to next prompt
        let total = currentPrompts?.count ?? 0
        if currentPromptIndex + 1 >= total {
            phase = .wrapping
        } else {
            currentPromptIndex += 1
        }
        save()
    }

    /// Delete a clip; if all clips removed go back to idle
    func deleteClip(_ clip: RecordedClip) {
        // Remove file from disk
        try? FileManager.default.removeItem(at: clip.url)
        clips.removeAll { $0.id == clip.id }

        if clips.isEmpty {
            phase = .idle
            currentPromptIndex = 0
        }
        save()
    }

    /// Reset everything back to idle
    func reset() {
        clips.forEach { try? FileManager.default.removeItem(at: $0.url) }
        clips = []
        currentPromptIndex = 0
        activeMoodName = ""
        activeLensName = ""
        phase = .idle
        save()
    }

    // MARK: - Persistence

    private static let saveURL: URL = {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("pov_session.json")
    }()

    func save() {
        try? JSONEncoder().encode(self).write(to: Self.saveURL)
    }

    static func load() -> RecordingSession {
        guard
            let data = try? Data(contentsOf: saveURL),
            let session = try? JSONDecoder().decode(RecordingSession.self, from: data)
        else { return RecordingSession() }
        return session
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case phase, clips, currentPromptIndex, activeMoodName, activeLensName
    }

    init() {}

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        phase              = try c.decode(SessionPhase.self,   forKey: .phase)
        clips              = try c.decode([RecordedClip].self, forKey: .clips)
        currentPromptIndex = try c.decode(Int.self,            forKey: .currentPromptIndex)
        activeMoodName     = try c.decode(String.self,         forKey: .activeMoodName)
        activeLensName     = try c.decode(String.self,         forKey: .activeLensName)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(phase,              forKey: .phase)
        try c.encode(clips,              forKey: .clips)
        try c.encode(currentPromptIndex, forKey: .currentPromptIndex)
        try c.encode(activeMoodName,     forKey: .activeMoodName)
        try c.encode(activeLensName,     forKey: .activeLensName)
    }
}
