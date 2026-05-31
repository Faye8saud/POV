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

                Text(formattedDate.uppercased())
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.45))
                    .kerning(1.5)
                    .padding(.bottom, 14)

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

            NavigationLink(
                destination: ReflectionView(
                    lens: lens,
                    date: date,
                    mergedVideoURL: merger.mergedURL,
                    moodName: clips.first?.moodName ?? "",
                    existingEntry: nil,
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
                await MainActor.run { self?.mergedURL = url; self?.isMerging = false }
            } catch {
                await MainActor.run { self?.error = error; self?.isMerging = false }
            }
        }
    }

    private static func mergeClips(
        _ clips: [RecordedClipModel],
        aspectRatio: CameraManager.AspectRatio
    ) async throws -> URL {

        let composition = AVMutableComposition()
        guard
            let videoTrack = composition.addMutableTrack(withMediaType: .video,
                                                         preferredTrackID: kCMPersistentTrackID_Invalid),
            let audioTrack = composition.addMutableTrack(withMediaType: .audio,
                                                         preferredTrackID: kCMPersistentTrackID_Invalid)
        else { throw MergeError.trackCreationFailed }

        // MARK: Pass 1 — collect metadata
        struct ClipMeta {
            let asset: AVURLAsset
            let duration: CMTime
            let naturalSize: CGSize
            let preferredTransform: CGAffineTransform
            let nominalFPS: Float
        }

        var metas: [ClipMeta] = []
        for clip in clips {
            let asset    = AVURLAsset(url: clip.url)
            let duration = try await asset.load(.duration)
            guard let srcVideo = try await asset.loadTracks(withMediaType: .video).first else { continue }
            let size      = try await srcVideo.load(.naturalSize)
            let transform = try await srcVideo.load(.preferredTransform)
            let fps       = try await srcVideo.load(.nominalFrameRate)
            metas.append(ClipMeta(asset: asset, duration: duration,
                                  naturalSize: size, preferredTransform: transform,
                                  nominalFPS: fps))
        }
        guard !metas.isEmpty else { throw MergeError.trackCreationFailed }

        // Master = the normal-speed clip with the largest pixel area.
        // Its naturalSize and transform define the composition canvas.
        let master = metas
            .filter { $0.nominalFPS <= 60 }
            .max(by: { $0.naturalSize.width * $0.naturalSize.height < $1.naturalSize.width * $1.naturalSize.height })
            ?? metas[0]

        let masterNaturalSize = master.naturalSize
        let masterTransform   = master.preferredTransform

        // MARK: Compute output (render) size from master
        let masterIsPortrait = abs(masterTransform.b) == 1 && abs(masterTransform.c) == 1
        let masterDisplay: CGSize = masterIsPortrait
            ? CGSize(width: masterNaturalSize.height, height: masterNaturalSize.width)
            : masterNaturalSize

        let renderSize: CGSize = {
            let w = masterDisplay.width, h = masterDisplay.height
            switch aspectRatio {
            case .ratioFull, .ratio16_9: return CGSize(width: w, height: h)
            case .ratio5_3:              return CGSize(width: w, height: min(w * (3.0/5.0), h))
            case .ratio1_1:              let s = min(w,h); return CGSize(width: s, height: s)
            }
        }()

        let cropOffsetX = (masterDisplay.width  - renderSize.width)  / 2
        let cropOffsetY = (masterDisplay.height - renderSize.height) / 2

        // MARK: Pass 2 — insert clips, stretch slow-mo, build per-segment instructions
        var currentTime  = CMTime.zero
        var instructions = [AVMutableVideoCompositionInstruction]()

        for meta in metas {
            let clipTimeRange = CMTimeRange(start: .zero, duration: meta.duration)
            let isSlowMo      = meta.nominalFPS > 60

            guard let srcVideo = try await meta.asset.loadTracks(withMediaType: .video).first else { continue }
            try videoTrack.insertTimeRange(clipTimeRange, of: srcVideo, at: currentTime)

            let effectiveDuration: CMTime
            if isSlowMo {
                let factor    = Float64(meta.nominalFPS) / 30.0
                let stretched = CMTimeMultiplyByFloat64(meta.duration, multiplier: factor)
                videoTrack.scaleTimeRange(
                    CMTimeRange(start: currentTime, duration: meta.duration),
                    toDuration: stretched
                )
                effectiveDuration = stretched
            } else {
                effectiveDuration = meta.duration
                if let srcAudio = try await meta.asset.loadTracks(withMediaType: .audio).first {
                    try? audioTrack.insertTimeRange(clipTimeRange, of: srcAudio, at: currentTime)
                }
            }

            // Build orientation-correcting transform for THIS clip's natural size
            let t = meta.preferredTransform
            var orientTransform: CGAffineTransform
            if      t.a == 0 && t.b == 1  && t.c == -1 && t.d == 0 {
                orientTransform = CGAffineTransform(a: 0, b: 1, c: -1, d: 0,
                                                    tx: meta.naturalSize.height, ty: 0)
            } else if t.a == 0 && t.b == -1 && t.c == 1  && t.d == 0 {
                orientTransform = CGAffineTransform(a: 0, b: -1, c: 1, d: 0,
                                                    tx: 0, ty: meta.naturalSize.width)
            } else if t.a == -1 && t.b == 0  && t.c == 0  && t.d == -1 {
                orientTransform = CGAffineTransform(a: -1, b: 0, c: 0, d: -1,
                                                    tx: meta.naturalSize.width,
                                                    ty: meta.naturalSize.height)
            } else {
                orientTransform = .identity
            }

            // Display size of this clip after orientation
            let clipIsPortrait = abs(t.b) == 1 && abs(t.c) == 1
            let clipDisplay = clipIsPortrait
                ? CGSize(width: meta.naturalSize.height, height: meta.naturalSize.width)
                : meta.naturalSize

            // Scale this clip to fill the master display canvas (aspect-fill)
            let scaleX = masterDisplay.width  / max(clipDisplay.width,  1)
            let scaleY = masterDisplay.height / max(clipDisplay.height, 1)
            let scale  = max(scaleX, scaleY)          // aspect-fill: pick the larger scale

            // Apply scale to the orientation transform's matrix and translation
            var scaled = orientTransform
            scaled.a  *= scale; scaled.b  *= scale
            scaled.c  *= scale; scaled.d  *= scale
            scaled.tx *= scale; scaled.ty *= scale

            // Centre within the master canvas after scaling
            let scaledW = clipDisplay.width  * scale
            let scaledH = clipDisplay.height * scale
            scaled.tx += (masterDisplay.width  - scaledW) / 2
            scaled.ty += (masterDisplay.height - scaledH) / 2

            // Shift for crop
            scaled.tx -= cropOffsetX
            scaled.ty -= cropOffsetY

            let segRange    = CMTimeRange(start: currentTime, duration: effectiveDuration)
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = segRange
            let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
            layer.setTransform(scaled, at: .zero)
            instruction.layerInstructions = [layer]
            instructions.append(instruction)

            currentTime = CMTimeAdd(currentTime, effectiveDuration)
        }

        // Assemble final video composition from per-segment instructions
        let videoComposition           = AVMutableVideoComposition()
        videoComposition.renderSize    = renderSize
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        videoComposition.instructions  = instructions

        // MARK: Export
        let docs      = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputURL = docs.appendingPathComponent("pov_\(UUID().uuidString).mov")
        try? FileManager.default.removeItem(at: outputURL)

        guard let exporter = AVAssetExportSession(asset: composition,
                                                  presetName: AVAssetExportPresetHighestQuality)
        else { throw MergeError.exporterCreationFailed }

        exporter.outputURL                   = outputURL
        exporter.outputFileType              = .mov
        exporter.shouldOptimizeForNetworkUse = false
        exporter.videoComposition            = videoComposition

        await exporter.export()
        guard exporter.status == .completed else {
            throw exporter.error ?? MergeError.exportFailed
        }
        return outputURL
    }

    enum MergeError: Error {
        case trackCreationFailed
        case exporterCreationFailed
        case exportFailed
    }
}
