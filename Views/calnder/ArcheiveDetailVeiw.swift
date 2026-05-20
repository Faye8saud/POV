//
//  ArcheiveDetailVeiw.swift
//  POV
//
//  Created by Fay  on 19/05/2026.
//
import SwiftUI
import AVKit
import SwiftData

// MARK: - Archive Detail View
// Shows the saved vlog film + reflection answers.
// If both answers are empty (skipped), offers a "Start reflecting" CTA instead.
struct ArchiveDetailView: View {

    let entry: DayEntry

    @Environment(\.dismiss) private var dismiss
    @Environment(\.cloudModelContext) private var cloudContext

    @State private var player: AVPlayer? = nil
    @State private var navigateToReflection = false

    // Derive the lens from stored data so ReflectionView gets the right questions
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

    private var hasReflection: Bool {
        !entry.reflectionAnswer1.isEmpty || !entry.reflectionAnswer2.isEmpty
    }

    private var videoURL: URL? {
        guard !entry.mergedVideoURL.isEmpty else { return nil }
        return URL(string: entry.mergedVideoURL)
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

                        // Spacer to balance chevron
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

                        if let player {
                            VideoPlayer(player: player)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        } else {
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

                    // MARK: Reflection section
                    if hasReflection {
                        ReflectionAnswersSection(
                            lens: lens,
                            answer1: entry.reflectionAnswer1,
                            answer2: entry.reflectionAnswer2
                        )
                        .padding(.horizontal, 24)
                        .padding(.bottom, 52)
                    } else {
                        // No reflections — offer to start
                        NoReflectionSection {
                            navigateToReflection = true
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 52)
                    }
                }
            }

            // Hidden nav link to ReflectionView
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
        .onAppear { setupPlayer() }
        .onDisappear { player?.pause() }
    }

    // MARK: - Helpers

    private func setupPlayer() {
        guard let url = videoURL else { return }
        let item = AVPlayerItem(url: url)
        let avPlayer = AVPlayer(playerItem: item)
        // Loop
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in avPlayer.seek(to: .zero); avPlayer.play() }
        avPlayer.play()
        player = avPlayer
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE · MMMM d"
        return f.string(from: date)
    }
}

// MARK: - Reflection Answers Section
// Shows answered questions with their responses.
private struct ReflectionAnswersSection: View {

    let lens: DirectorLens
    let answer1: String
    let answer2: String

    var body: some View {
        VStack(spacing: 0) {

            // Divider header
            HStack(spacing: 12) {
                Rectangle()
                    .fill(.white.opacity(0.1))
                    .frame(height: 1)
                Text("Reflection")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
                    .tracking(1.5)
                Rectangle()
                    .fill(.white.opacity(0.1))
                    .frame(height: 1)
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

// MARK: - Single Reflection Card
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
                // Render Yes/No as a pill badge
                Text(answer)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(white: 0.06))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.white)
                    )
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
// Shown when the user skipped both reflection questions.
private struct NoReflectionSection: View {

    let onStartReflecting: () -> Void

    var body: some View {
        VStack(spacing: 20) {

            HStack(spacing: 12) {
                Rectangle()
                    .fill(.white.opacity(0.1))
                    .frame(height: 1)
                Text("Reflection")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
                    .tracking(1.5)
                Rectangle()
                    .fill(.white.opacity(0.1))
                    .frame(height: 1)
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

            Button {
                onStartReflecting()
            } label: {
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
