//
//  ArchiveModel.swift
//  POV
//
//  Created by Fajer alQahtani on 02/12/1447 AH.
//

import Foundation
import SwiftData
 
// MARK: - EntryModel
@Model
class EntryModel {
    var id: UUID
    var date: Date
    var moodName: String        // matches Mood.name  e.g. "Tender"
    var lensName: String        // matches DirectorLens.name  e.g. "Wong Kar-wai"
    var clips: [RecordedClipModel]
    var reflections: [ReflectionAnswer]
    var videoURL: URL?
    var createdAt: Date
 
    init(
        id: UUID = UUID(),
        date: Date = .now,
        moodName: String,
        lensName: String,
        clips: [RecordedClipModel] = [],
        reflections: [ReflectionAnswer] = [],
        videoURL: URL? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.moodName = moodName
        self.lensName = lensName
        self.clips = clips
        self.reflections = reflections
        self.videoURL = videoURL
        self.createdAt = createdAt
    }
 
    var isCompleted: Bool { !reflections.isEmpty }
 
    /// Lookup matching DirectorLens from POVData
    var directorLens: DirectorLens? {
        POVData.lensesByMood.values
            .flatMap { $0 }
            .first { $0.name == lensName }
    }
 
    /// Lookup matching Mood from POVData
    var mood: Mood? {
        POVData.moods.first { $0.name == moodName }
    }
}
 
// MARK: - RecordedClipModel
/*@Model
class RecordedClipModel {
    var id: UUID
    var url: URL
    var promptIndex: Int
    var promptText: String
    var duration: TimeInterval
    var entryID: UUID
 
    init(
        id: UUID = UUID(),
        url: URL,
        promptIndex: Int,
        promptText: String,
        duration: TimeInterval,
        entryID: UUID
    ) {
        self.id = id
        self.url = url
        self.promptIndex = promptIndex
        self.promptText = promptText
        self.duration = duration
        self.entryID = entryID
    }
}
 */
// MARK: - ReflectionAnswer
@Model
class ReflectionAnswer {
    var id: UUID
    var questionText: String
    var answerText: String
    var entryID: UUID
    var lensName: String
    var moodName: String
    var createdAt: Date
 
    init(
        id: UUID = UUID(),
        questionText: String,
        answerText: String,
        entryID: UUID,
        lensName: String,
        moodName: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.questionText = questionText
        self.answerText = answerText
        self.entryID = entryID
        self.lensName = lensName
        self.moodName = moodName
        self.createdAt = createdAt
    }
}
