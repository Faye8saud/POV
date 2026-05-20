//
//  RecordingSession.swift
//  POV
//
//  Created by Fay  on 13/05/2026.
//
import Foundation
import SwiftData
import Combine

// MARK: - Session Phase
enum SessionPhase: String, Codable {
    case idle
    case shooting
    case wrapping
}

// MARK: - Session Manager (ObservableObject wrapping SwiftData model)
//
// RecordingSessionModel is the persisted @Model.
// This class is the ObservableObject your views already use — it stays as @StateObject.
// It holds a reference to the single RecordingSessionModel row and proxies
// all reads/writes through it, so RecordingView needs almost zero changes.

@MainActor
final class RecordingSession: ObservableObject {

    // MARK: Published (mirrors the SwiftData model for view reactivity)
    @Published var phase: SessionPhase      = .idle
    @Published var clips: [RecordedClipModel] = []
    @Published var currentPromptIndex: Int  = 0
    @Published var activeMoodName: String   = ""
    @Published var activeLensName: String   = ""

    var recordedAspectRatio: CameraManager.AspectRatio = .ratio5_3
    
    // MARK: SwiftData
    private let modelContext: ModelContext
    private var model: RecordingSessionModel

    // MARK: - Init
    init(modelContext: ModelContext) {
        self.modelContext = modelContext

        // Fetch existing session or create one
        let descriptor = FetchDescriptor<RecordingSessionModel>()
        if let existing = try? modelContext.fetch(descriptor).first {
            self.model = existing
        } else {
            let fresh = RecordingSessionModel()
            modelContext.insert(fresh)
            try? modelContext.save()
            self.model = fresh
        }

        // Sync published state from persisted model
        self.syncFromModel()
    }

    // MARK: - Computed (unchanged from original)
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

    func startSession(mood: Mood, lens: DirectorLens) {
        // Delete old clips from disk + model
        model.clips.forEach { try? FileManager.default.removeItem(at: $0.url) }
        model.clips.removeAll()

        model.currentPromptIndex = 0
        model.activeMoodName = mood.name
        model.activeLensName = lens.name
        model.phase = .shooting
        save()
        syncFromModel()
    }

    func addClip(url: URL) {
        let clip = RecordedClipModel(
            url: url,
            promptIndex: currentPromptIndex,
            directorName: activeLensName,
            moodName: activeMoodName
        )
        modelContext.insert(clip)
        model.clips.append(clip)

        let total = currentPrompts?.count ?? 0
        if model.currentPromptIndex + 1 >= total {
            model.phase = .wrapping
        } else {
            model.currentPromptIndex += 1
        }
        save()
        syncFromModel()
    }

    func deleteClip(_ clip: RecordedClipModel) {
        try? FileManager.default.removeItem(at: clip.url)
        model.clips.removeAll { $0.id == clip.id }
        modelContext.delete(clip)

        if model.clips.isEmpty {
            model.phase = .idle
            model.currentPromptIndex = 0
        }
        save()
        syncFromModel()
    }

    func reset() {
        model.clips.forEach { try? FileManager.default.removeItem(at: $0.url) }
        model.clips.removeAll()
        model.currentPromptIndex = 0
        model.activeMoodName = ""
        model.activeLensName = ""
        model.phase = .idle
        save()
        syncFromModel()
    }

    // MARK: - Internals

    private func syncFromModel() {
        phase              = model.phase
        clips              = model.clips.sorted { $0.date < $1.date }
        currentPromptIndex = model.currentPromptIndex
        activeMoodName     = model.activeMoodName
        activeLensName     = model.activeLensName
    }

    private func save() {
        try? modelContext.save()
    }
}



