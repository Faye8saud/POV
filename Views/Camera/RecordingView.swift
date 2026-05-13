//
//  RecordingView.swift
//  POV
//
//  Created by Fay  on 10/05/2026.
//
import SwiftUI
import AVFoundation

// MARK: - Recording View
struct RecordingView: View {

    @StateObject private var camera = CameraManager()

    @State private var selectedMood: Mood        = POVData.moods[0]
    @State private var selectedLens: DirectorLens? = nil
    @State private var selectedTab: POVTab       = .record

    // MARK: Body
    var body: some View {
        ZStack {
            cameraBackground

            VStack(spacing: 0) {

                topInfoBar
                    .padding(.top, topSafeAreaPad)

                MoodSelectorView(moods: POVData.moods, selectedMood: $selectedMood)
                    .padding(.top, 10)

                Spacer()

                lensNameLabel
                    .padding(.bottom, 12)

                lensAndRecordRow
                    .padding(.bottom, 22)

                POVTabBar(selectedTab: $selectedTab, isRecording: camera.isRecording)
                    .padding(.bottom, bottomSafeAreaPad + 4)
            }

            HStack {
                Spacer()
                CameraControlsBar(camera: camera)
                    .padding(.trailing, 14)
            }
            .padding(.top, 150)
            .padding(.bottom, 200)
        }
        .ignoresSafeArea()
        .onChange(of: selectedMood) { _ in
            selectedLens = POVData.lenses(for: selectedMood).first
        }
        .onAppear {
            selectedLens = POVData.lenses(for: selectedMood).first
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var cameraBackground: some View {
        if camera.permissionGranted {
            CameraPreview(session: camera.session, aspectRatio: camera.aspectRatio)
                .ignoresSafeArea()
        } else {
            Rectangle()
                .fill(Color(white: 0.08))
                .ignoresSafeArea()
                .overlay(
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(.white.opacity(0.35))
                        Text("Camera access needed")
                            .font(.custom("Georgia-Italic", size: 16))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                )
        }
    }

    private var topInfoBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(formattedDate.uppercased())
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.55))
                    .tracking(1.5)
                Text(headerTitle)
                    .font(.custom("Georgia-Italic", size: 20))
                    .foregroundStyle(.white)
            }
            Spacer()
            if camera.isRecording {
                RecordingBadge(duration: camera.formattedDuration)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .animation(.spring(response: 0.35), value: camera.isRecording)
    }

    @ViewBuilder
    private var lensNameLabel: some View {
        if let lens = selectedLens {
            VStack(spacing: 3) {
                Text(lens.name)
                    .font(.custom("Georgia-Italic", size: 15))
                    .foregroundStyle(.white)
          //      Text(lens.styleDescription)
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(0.4)
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            .id(lens.id)
            .animation(.spring(response: 0.3), value: lens.id)
        }
    }

    /// Active lens = record button. Inactive lenses fan out to the right.
    private var lensAndRecordRow: some View {
        GeometryReader { geo in
            let totalWidth  = geo.size.width
            let activeSize: CGFloat = 76          // active lens matches old shutter size
            let leftPad:    CGFloat = 24
            // Center the active lens the same way the old shutter was centered
            let activeX     = totalWidth / 2
            let stripStartX = activeX + activeSize / 2 + 10  // right edge + gap

            ZStack(alignment: .leading) {

                // ── Active lens / shutter ──────────────────────────────
                if let lens = selectedLens {
                    ActiveLensShutter(
                        lens: lens,
                        isRecording: camera.isRecording,
                        size: activeSize
                    ) {
                        camera.toggleRecording()
                    }
                    .position(x: activeX, y: geo.size.height / 2)
                }

                // ── Inactive lenses strip ──────────────────────────────
                InactiveLensStrip(
                    lenses: POVData.lenses(for: selectedMood),
                    selectedLens: $selectedLens,
                    isRecording: camera.isRecording
                )
                .frame(width: totalWidth - stripStartX - leftPad, height: geo.size.height)
                .position(
                    x: stripStartX + (totalWidth - stripStartX - leftPad) / 2,
                    y: geo.size.height / 2
                )
            }
        }
        .frame(height: 76)
        .padding(.horizontal, 24)
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE · MMMM d"
        return f.string(from: Date())
    }

    private var headerTitle: String {
        if camera.isRecording {
            return "Recording with \(selectedLens?.name ?? "")…"
        }
        return "How do you want today to feel?"
    }

    private var topSafeAreaPad: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 44
    }

    private var bottomSafeAreaPad: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 34
    }
}

// MARK: - Active Lens Shutter
/// The selected director's avatar — acts as the record button.
struct ActiveLensShutter: View {

    let lens: DirectorLens
    let isRecording: Bool
    let size: CGFloat
    let action: () -> Void

    @State private var pulsing = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer ring — white normally, pulses red when recording
                Circle()
                    .strokeBorder(
                        isRecording ? Color.red.opacity(pulsing ? 0.4 : 1) : Color.white.opacity(0.85),
                        lineWidth: 3
                    )
                    .frame(width: size, height: size)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulsing)

                // Director photo or initials
                if UIImage(named: lens.imageName) != nil {
                    Image(lens.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size - 6, height: size - 6)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: size - 6, height: size - 6)
                        .overlay(
                            Text(initials(lens.name))
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        )
                }

                // Recording overlay — small red square in corner
                if isRecording {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(Color.red)
                                .frame(width: 14, height: 14)
                                .padding(6)
                        }
                    }
                    .frame(width: size, height: size)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(.plain)
        .shadow(color: (isRecording ? Color.red : .white).opacity(0.4), radius: 14)
        .animation(.spring(response: 0.4, dampingFraction: 0.65), value: isRecording)
        .onChange(of: isRecording) { recording in
            pulsing = recording
        }
    }

    private func initials(_ name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined()
    }
}

// MARK: - Inactive Lens Strip
/// All lenses except the currently selected one, fanning right.
/// Tapping one switches it to active (and stops recording if in progress).
struct InactiveLensStrip: View {

    let lenses: [DirectorLens]
    @Binding var selectedLens: DirectorLens?
    let isRecording: Bool

    private let size: CGFloat    = 44
    private let spacing: CGFloat = 10

    private var others: [DirectorLens] {
        lenses.filter { $0.id != selectedLens?.id }
    }

    var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            ForEach(Array(others.prefix(3).enumerated()), id: \.element.id) { idx, lens in
                let itemSize = max(30, size - CGFloat(idx) * 5)

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedLens = lens
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: itemSize, height: itemSize)

                        if UIImage(named: lens.imageName) != nil {
                            Image(lens.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: itemSize, height: itemSize)
                                .clipShape(Circle())
                        } else {
                            Text(initials(lens.name))
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        }

                        Circle()
                            .strokeBorder(Color.white.opacity(0.28), lineWidth: 1.2)
                            .frame(width: itemSize, height: itemSize)
                    }
                    .opacity(max(0.3, 0.7 - Double(idx) * 0.18))
                    .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .padding(.leading, 40)  // ← this is the fix: breathing room between active and inactive
    }

    private func initials(_ name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined()
    }
}

// MARK: - Recording Badge
private struct RecordingBadge: View {

    let duration: String
    @State private var pulsing = false

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(.red)
                .frame(width: 7, height: 7)
                .opacity(pulsing ? 0.25 : 1)
                .animation(.easeInOut(duration: 0.8).repeatForever(), value: pulsing)
            Text(duration)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(.black.opacity(0.45))
                .overlay(Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 1))
        )
        .onAppear { pulsing = true }
    }
}

// MARK: - Preview
#Preview {
    RecordingView()
}
