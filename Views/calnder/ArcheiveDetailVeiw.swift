//
//  ArcheiveDetailVeiw.swift
//  POV
//
//  Created by Fay  on 19/05/2026.
//
import SwiftUI
import AVKit
import SwiftData
import Combine

// MARK: - Archive Detail View
struct ArchiveDetailView: View {

    let entry: DayEntry

    @Environment(\.dismiss) private var dismiss
    @StateObject private var playerHolder = ArchivePlayerHolder()
    @State private var navigateToReflection = false

    private var lens: DirectorLens {
        POVData.moods
            .flatMap { POVData.lenses(for: $0) }
            .first { $0.name == entry.directorName }
            ?? DirectorLens(
                name: entry.directorName,
                nationality: "",
                styleDescription: entry.directorStyle,
                imageName: "",
                shootingPrompts: [],
                tags: [],
                brief: "",
                question1: "Did today feel like what you expected?",
                question2: "What would you want to remember most about today?"
            )
    }

    private var videoURL: URL? {
        guard !entry.mergedVideoURL.isEmpty else { return nil }
        // Try as-is first (full URL string), then as a bare path
        if let url = URL(string: entry.mergedVideoURL), url.scheme != nil {
            return url
        }
        return URL(fileURLWithPath: entry.mergedVideoURL)
    }

    var body: some View {
        ZStack {
            Color(white: 0.06).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // MARK: Nav
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(.white.opacity(0.1)))
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Text(formattedDate(entry.date).uppercased())
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                            .kerning(1.5)

                        Spacer()
                        Color.clear.frame(width: 36, height: 36)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                    // MARK: Video Player
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.black)
                            .frame(height: 420)

                        if playerHolder.isReady, let player = playerHolder.player {
                            VideoPlayer(player: player)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .frame(height: 420)
                        } else if videoURL != nil {
                            // Loading state
                            VStack(spacing: 12) {
                                ProgressView().tint(.white)
                                Text("Loading film…")
                                    .font(.custom("Georgia-Italic", size: 14))
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                        } else {
                            // No video saved
                            VStack(spacing: 12) {
                                Image(systemName: "film")
                                    .font(.system(size: 36))
                                    .foregroundStyle(.white.opacity(0.3))
                                Text("Film unavailable")
                                    .font(.custom("Georgia-Italic", size: 15))
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                        }
                    }
                    .frame(height: 420)
                    .padding(.horizontal, 24)

                    // MARK: Meta
                    VStack(spacing: 5) {
                        Text("A film of your day")
                            .font(.custom("Georgia-Italic", size: 20))
                            .foregroundStyle(.white)
                        Text("In the lens of \(entry.directorName)")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(entry.moodName.uppercased())
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.3))
                            .tracking(1.5)
                            .padding(.top, 2)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 36)

                    // MARK: Reflection
                    if entry.hasReflection {
                        ReflectionAnswersSection(
                            lens: lens,
                            answer1: entry.reflectionAnswer1,
                            answer2: entry.reflectionAnswer2
                        )
                        .padding(.horizontal, 24)
                        .padding(.bottom, 120)
                    } else {
                        NoReflectionSection {
                            navigateToReflection = true
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 120)
                    }
                }
            }

            // NavigationLink to ReflectionView for late reflection
            NavigationLink(
                destination: ReflectionView(
                    lens: lens,
                    date: entry.date,
                    mergedVideoURL: videoURL,
                    moodName: entry.moodName
                ),
                isActive: $navigateToReflection
            ) { EmptyView() }
                .hidden()
        }
        .navigationBarHidden(true)
        .onAppear {
            if let url = videoURL {
                playerHolder.setup(url: url)
            }
        }
        .onDisappear {
            playerHolder.pause()
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE · MMMM d"
        return f.string(from: date)
    }
}

// MARK: - Archive Player Holder
// Separate class so the player persists across body re-renders
final class ArchivePlayerHolder: ObservableObject {
    @Published var isReady = false
    private(set) var player: AVPlayer?
    private var looper: AVPlayerLooper?
    private var observation: NSKeyValueObservation?

    func setup(url: URL) {
        // Verify file exists on disk
        let path = url.path
        guard FileManager.default.fileExists(atPath: path) else {
            print("⚠️ Video file not found at: \(path)")
            return
        }

        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer(playerItem: item)
        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)

        // Observe status to show player only when ready
        observation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                if item.status == .readyToPlay {
                    self?.isReady = true
                    queuePlayer.play()
                }
            }
        }

        player = queuePlayer
    }

    func pause() {
        player?.pause()
    }
}

// MARK: - Reflection Answers Section
private struct ReflectionAnswersSection: View {
    let lens: DirectorLens
    let answer1: String
    let answer2: String

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Rectangle().fill(.white.opacity(0.1)).frame(height: 1)
                Text("Reflection")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
                    .tracking(1.5)
                Rectangle().fill(.white.opacity(0.1)).frame(height: 1)
            }
            .padding(.bottom, 24)

            VStack(spacing: 16) {
                if !answer1.isEmpty {
                    ReflectionCard(question: lens.question1, answer: answer1, isYesNo: true)
                }
                if !answer2.isEmpty {
                    ReflectionCard(question: lens.question2, answer: answer2, isYesNo: false)
                }
            }
        }
    }
}

// MARK: - Reflection Card
private struct ReflectionCard: View {
    let question: String
    let answer: String
    let isYesNo: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question)
                .font(.custom("Georgia-Italic", size: 15))
                .foregroundStyle(.white.opacity(0.55))
                .lineSpacing(3)

            if isYesNo {
                Text(answer)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(white: 0.06))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.white))
            } else {
                Text(answer)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - No Reflection Section
private struct NoReflectionSection: View {
    let onStartReflecting: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                Rectangle().fill(.white.opacity(0.1)).frame(height: 1)
                Text("Reflection")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
                    .tracking(1.5)
                Rectangle().fill(.white.opacity(0.1)).frame(height: 1)
            }

            VStack(spacing: 8) {
                Text("You haven't reflected on this day yet.")
                    .font(.custom("Georgia-Italic", size: 16))
                    .foregroundStyle(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                Text("Take a moment to revisit it.")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(.white.opacity(0.3))
                    .multilineTextAlignment(.center)
            }

            Button { onStartReflecting() } label: {
                Text("Start reflecting")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(white: 0.06))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white)
                    .cornerRadius(27)
            }
            .buttonStyle(.plain)
        }
    }
}
