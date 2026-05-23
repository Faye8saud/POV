//
//  VideoView.swift
//  POV
//
//  Created by Fay  on 17/05/2026.
//
import SwiftUI
import AVKit
import Combine
import SwiftData

// MARK: - Video View
struct VideoView: View {

    let clips: [RecordedClipModel]
    let lens: DirectorLens
    let date: Date
    let aspectRatio: CameraManager.AspectRatio
    let onStartReflecting: () -> Void
    let onSaveComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.cloudModelContext) private var cloudContext
    @Environment(\.selectedPOVTab) private var selectedTab

    @StateObject private var playerHolder = QueuePlayerHolder()
    @StateObject private var merger = VideoMerger()

    @State private var navigateToReflection = false
    @State private var showSkipAlert = false

    var body: some View {
        ZStack {
            Color(white: 0.06).ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: Nav
                HStack {
                    Button {
                        playerHolder.player.pause()
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(.white.opacity(0.1)))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button { showSkipAlert = true } label: {
                        Text("Save & Skip")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Spacer()

                // MARK: Date
                Text(formattedDate.uppercased())
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.45))
                    .kerning(1.5)
                    .padding(.bottom, 14)

                // MARK: Video Player
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.black)
                        .frame(height: 420)

                    if merger.isMerging {
                        VStack(spacing: 12) {
                            ProgressView().tint(.white)
                            Text("Preparing your film…")
                                .font(.custom("Georgia-Italic", size: 14))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    } else if clips.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "film")
                                .font(.system(size: 36))
                                .foregroundStyle(.white.opacity(0.3))
                            Text("No clips recorded")
                                .font(.custom("Georgia-Italic", size: 16))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    } else {
                        VideoPlayer(player: playerHolder.player)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .frame(height: 420)
                .padding(.horizontal, 24)

                // MARK: Meta
                VStack(spacing: 6) {
                    Text("A film of your day")
                        .font(.custom("Georgia-Italic", size: 20))
                        .italic()
                        .foregroundStyle(.white)
                    Text("In the lens of \(lens.name)")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(.white.opacity(0.5))
                    Text("\(clips.count) shot\(clips.count == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .light, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                        .padding(.top, 2)
                }
                .padding(.top, 20)

                Spacer()

                // MARK: CTA
                Button {
                    playerHolder.player.pause()
                    navigateToReflection = true
                } label: {
                    Text("Start reflecting")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(white: 0.06))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.white)
                        .cornerRadius(27)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
                .disabled(merger.isMerging)
                .opacity(merger.isMerging ? 0.4 : 1)
            }

            // Hidden NavigationLink to ReflectionView
            NavigationLink(
                destination: ReflectionView(
                    lens: lens,
                    date: date,
                    mergedVideoURL: merger.mergedURL,
                    moodName: clips.first?.moodName ?? "",
                    onSaveComplete: onSaveComplete
                ),
                isActive: $navigateToReflection
            ) { EmptyView() }
                .hidden()
        }
        .navigationBarHidden(true)
        .onAppear {
            playerHolder.setupWithClips(clips)
            playerHolder.player.play()
            merger.merge(clips: clips, aspectRatio: aspectRatio)
        }
        .onDisappear {
            playerHolder.player.pause()
        }
        .onChange(of: merger.mergedURL) { url in
            guard let url else { return }
            playerHolder.switchToMerged(url: url)
        }
        .alert("Save without reflecting?", isPresented: $showSkipAlert) {
            Button("Save & go to archive") {
                saveEntryAndGoToArchive(answer1: "", answer2: "")
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your film will be saved. You can always come back to it later.")
        }
    }

    // MARK: - Save & Skip (no reflection)
    private func saveEntryAndGoToArchive(answer1: String, answer2: String) {
        guard let context = cloudContext else { return }

        let entry = DayEntry(
            date: date,
            moodName: clips.first?.moodName ?? "",
            directorName: lens.name,
            directorStyle: lens.styleDescription,
            reflectionAnswer1: answer1,
            reflectionAnswer2: answer2,
            mergedVideoURL: merger.mergedURL?.lastPathComponent ?? ""
        )
        context.insert(entry)
        try? context.save()
        onSaveComplete()
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE · MMMM d"
        return f.string(from: date)
    }
}

// MARK: - Queue Player Holder
final class QueuePlayerHolder: ObservableObject {
    let player = AVQueuePlayer()
    private var looper: AVPlayerLooper?

    func setupWithClips(_ clips: [RecordedClipModel]) {
        looper = nil
        player.removeAllItems()
        let sorted = clips.sorted { $0.date < $1.date }
        sorted.map { AVPlayerItem(url: $0.url) }.forEach { player.insert($0, after: nil) }
    }

    func switchToMerged(url: URL) {
        looper = nil
        player.removeAllItems()
        let item = AVPlayerItem(url: url)
        looper = AVPlayerLooper(player: player, templateItem: item)
        player.play()
    }
}

// MARK: - Video Merger
@MainActor
final class VideoMerger: ObservableObject {
    @Published var isMerging = false
    @Published var mergedURL: URL? = nil
    @Published var error: Error? = nil

    func merge(clips: [RecordedClipModel], aspectRatio: CameraManager.AspectRatio = .ratio5_3) {
        guard !clips.isEmpty, mergedURL == nil else { return }
        isMerging = true

        let sorted = clips.sorted { $0.date < $1.date }

        Task.detached(priority: .userInitiated) { [weak self] in
            do {
                let url = try await Self.mergeClips(sorted, aspectRatio: aspectRatio)
                await MainActor.run {
                    self?.mergedURL = url
                    self?.isMerging = false
                }
            } catch {
                await MainActor.run {
                    self?.error = error
                    self?.isMerging = false
                }
            }
        }
    }

    private static func mergeClips(
        _ clips: [RecordedClipModel],
        aspectRatio: CameraManager.AspectRatio
    ) async throws -> URL {
        let composition = AVMutableComposition()

        guard
            let videoTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ),
            let audioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            )
        else { throw MergeError.trackCreationFailed }

        var currentTime = CMTime.zero
        var naturalSize = CGSize(width: 1920, height: 1080)
        var storedTransform = CGAffineTransform.identity

        for clip in clips {
            let asset = AVURLAsset(url: clip.url)
            let duration = try await asset.load(.duration)
            let timeRange = CMTimeRange(start: .zero, duration: duration)

            if let srcVideo = try await asset.loadTracks(withMediaType: .video).first {
                try videoTrack.insertTimeRange(timeRange, of: srcVideo, at: currentTime)
                if currentTime == .zero {
                    let size = try await srcVideo.load(.naturalSize)
                    let transform = try await srcVideo.load(.preferredTransform)
                    // Only use if valid
                    if size.width > 0 && size.height > 0 {
                        naturalSize = size
                        storedTransform = transform
                    }
                }
            }

            if let srcAudio = try await asset.loadTracks(withMediaType: .audio).first {
                try audioTrack.insertTimeRange(timeRange, of: srcAudio, at: currentTime)
            }

            currentTime = CMTimeAdd(currentTime, duration)
        }

        let videoComposition = try await buildVideoComposition(
            for: composition,
            naturalSize: naturalSize,
            preferredTransform: storedTransform,
            aspectRatio: aspectRatio
        )

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputURL = docs.appendingPathComponent("pov_\(UUID().uuidString).mov")
        try? FileManager.default.removeItem(at: outputURL)

        guard let exporter = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else { throw MergeError.exporterCreationFailed }

        exporter.outputURL = outputURL
        exporter.outputFileType = .mov
        exporter.shouldOptimizeForNetworkUse = false
        exporter.videoComposition = videoComposition

        await exporter.export()

        guard exporter.status == .completed else {
            throw exporter.error ?? MergeError.exportFailed
        }

        return outputURL
    }

    private static func buildVideoComposition(
        for composition: AVMutableComposition,
        naturalSize: CGSize,
        preferredTransform: CGAffineTransform,
        aspectRatio: CameraManager.AspectRatio
    ) async throws -> AVMutableVideoComposition {

        guard let videoTrack = composition.tracks(withMediaType: .video).first else {
            throw MergeError.trackCreationFailed
        }

        let t = preferredTransform
        let isPortrait = abs(t.b) == 1 && abs(t.c) == 1

        let displaySize: CGSize = isPortrait
            ? CGSize(width: naturalSize.height, height: naturalSize.width)
            : naturalSize

        // Guard against zero/invalid dimensions
        guard displaySize.width > 0 && displaySize.height > 0 else {
            throw MergeError.trackCreationFailed
        }

        let correctedTransform: CGAffineTransform
        if t.a == 0 && t.b == 1 && t.c == -1 && t.d == 0 {
            correctedTransform = CGAffineTransform(a: 0, b: 1, c: -1, d: 0,
                                                   tx: naturalSize.height, ty: 0)
        } else if t.a == 0 && t.b == -1 && t.c == 1 && t.d == 0 {
            correctedTransform = CGAffineTransform(a: 0, b: -1, c: 1, d: 0,
                                                   tx: 0, ty: naturalSize.width)
        } else if t.a == -1 && t.b == 0 && t.c == 0 && t.d == -1 {
            correctedTransform = CGAffineTransform(a: -1, b: 0, c: 0, d: -1,
                                                   tx: naturalSize.width, ty: naturalSize.height)
        } else {
            correctedTransform = .identity
        }

        let outputSize: CGSize = {
            switch aspectRatio {
            case .ratioFull, .ratio16_9:
                return displaySize
            case .ratio5_3:
                let targetHeight = displaySize.width * (3.0 / 5.0)
                return CGSize(width: displaySize.width,
                              height: min(targetHeight, displaySize.height))
            case .ratio1_1:
                let side = min(displaySize.width, displaySize.height)
                return CGSize(width: side, height: side)
            }
        }()

        // Guard against zero output size
        guard outputSize.width > 0 && outputSize.height > 0 else {
            throw MergeError.trackCreationFailed
        }

        let cropOffsetX = (displaySize.width  - outputSize.width)  / 2
        let cropOffsetY = (displaySize.height - outputSize.height) / 2

        var finalTransform = correctedTransform
        finalTransform.tx -= cropOffsetX
        finalTransform.ty -= cropOffsetY

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = outputSize
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        layerInstruction.setTransform(finalTransform, at: .zero)

        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        return videoComposition
    }

    enum MergeError: Error {
        case trackCreationFailed
        case exporterCreationFailed
        case exportFailed
    }
}
