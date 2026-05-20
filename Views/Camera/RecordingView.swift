//
//  RecordingView.swift
//  POV
//
//  Created by Fay  on 10/05/2026.
//
import SwiftUI
import AVFoundation

// MARK: - Recording View (entry point — injects modelContext into inner view)
struct RecordingView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        RecordingViewInner(session: RecordingSession(modelContext: modelContext))
    }
}

// MARK: - Recording View Inner
private struct RecordingViewInner: View {

    @StateObject var session: RecordingSession
    @StateObject private var camera = CameraManager()

    @State private var selectedMood: Mood          = POVData.moods[0]
    @State private var selectedLens: DirectorLens? = nil

    @Environment(\.selectedPOVTab) private var selectedTab

    @State private var showDiscardSheet     = false
    @State private var showWrapSheet        = false
    @State private var navigateToVideo      = false
    @State private var showExpandedControls = false   // right-side collapsible menu

    // MARK: Body
    var body: some View {
        rootStack
            .ignoresSafeArea()
            .confirmationDialog("Discard today's film?", isPresented: $showDiscardSheet, titleVisibility: .visible) {
                Button("Keep", role: .cancel) {}
                Button("Discard", role: .destructive) { handleDiscard() }
            } message: {
                Text("Your captures from today will be deleted. This can't be undone.")
            }
            .confirmationDialog("Wrap the day?", isPresented: $showWrapSheet, titleVisibility: .visible) {
                wrapDialogButtons
            } message: {
                Text("Save your film and reflect, or keep filming a little longer.")
            }
            .onChange(of: session.phase) { handlePhaseChange($0) }
            .onChange(of: navigateToVideo) { handleNavigationChange($0) }
            .onChange(of: selectedMood) { _ in handleMoodChange() }
            .onChange(of: selectedLens) { handleLensChange($0) }
            .onAppear { handleAppear() }
    }

    // MARK: - Root Stack
    private var rootStack: some View {
        ZStack {
            cameraBackground
            mainContent
            countdownOverlay
            navigationLink
        }
    }

    // MARK: - Wrap Dialog Buttons
    @ViewBuilder
    private var wrapDialogButtons: some View {
        if let lens = selectedLens, POVData.hasLook(for: lens) {
            Button("Save with look") {
                camera.bakeFilterOnExport = true
                navigateToVideo = true
            }
            Button("Save raw (no filter)") {
                camera.bakeFilterOnExport = false
                navigateToVideo = true
            }
        } else {
            Button("Save") { navigateToVideo = true }
        }
        Button("Resume", role: .cancel) {}
    }

    // MARK: - Event Handlers
    private func handleDiscard() {
        camera.stopRecording { _ in }
        withAnimation { session.reset() }
        selectedLens = POVData.lenses(for: selectedMood).first
    }

    private func handlePhaseChange(_ newPhase: SessionPhase) {
        if newPhase == .wrapping {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                navigateToVideo = true
            }
        }
    }

    private func handleNavigationChange(_ isNavigating: Bool) {
        if !isNavigating && session.isWrapping {
            withAnimation { session.reset() }
            selectedLens = POVData.lenses(for: selectedMood).first
        }
    }

    private func handleMoodChange() {
        if session.isIdle {
            selectedLens = POVData.lenses(for: selectedMood).first
        }
    }

    private func handleLensChange(_ lens: DirectorLens?) {
        guard let lens else { return }
        camera.setLook(POVData.look(for: lens))
    }

    private func handleAppear() {
        if session.isWrapping {
            session.reset()
            selectedLens = POVData.lenses(for: selectedMood).first
            if let lens = selectedLens { camera.setLook(POVData.look(for: lens)) }
            return
        }
        if session.isShooting || session.isWrapping,
           let mood = POVData.moods.first(where: { $0.name == session.activeMoodName }) {
            selectedMood = mood
            selectedLens = POVData.lenses(for: mood).first { $0.name == session.activeLensName }
        } else {
            selectedLens = POVData.lenses(for: selectedMood).first
        }
        if let lens = selectedLens { camera.setLook(POVData.look(for: lens)) }
    }

    // MARK: - Main Content Stack
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.top, topSafeAreaPad)
                .padding(.horizontal, 20)
            if session.isIdle {
                MoodSelectorView(moods: POVData.moods, selectedMood: $selectedMood)
                    .padding(.top, topBarBottomPad)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            if !camera.isRecording {
                topCard
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
            }
            Spacer()
            bottomStack
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: session.phase)
        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: camera.isRecording)
    }

    // MARK: - Bottom Stack
    @ViewBuilder
    private var bottomStack: some View {
        if !session.clips.isEmpty && !camera.isRecording {
            ClipTray(clips: session.clips) { clip in
                withAnimation { session.deleteClip(clip) }
            }
            .padding(.bottom, 12)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        if session.isIdle, let lens = selectedLens {
            VStack(spacing: 3) {
                Text(lens.name)
                    .font(.custom("Georgia-Italic", size: 15))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 12)
            .transition(.opacity)
            .id(lens.id)
        }
        if session.isShooting && !camera.isRecording {
            zoomPill
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
        lensAndRecordRow
            .padding(.bottom, 22)
        POVTabBar(selectedTab: selectedTab, isRecording: camera.isRecording)
            .padding(.bottom, bottomSafeAreaPad + 4)
    }

    // MARK: - Countdown Overlay
    @ViewBuilder
    private var countdownOverlay: some View {
        if camera.isCountingDown {
            let bottomPad: CGFloat = bottomSafeAreaPad + 118
            // Centered on screen
            CountdownBubble(remaining: camera.countdownRemaining)
                .transition(.scale(scale: 0.7).combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.7),
                           value: camera.countdownRemaining)
        }
    }

    // MARK: - Navigation Link
    @ViewBuilder
    private var navigationLink: some View {
        if let lens = selectedLens {
            NavigationLink(
                destination: VideoView(
                    clips: session.clips,
                    lens: lens,
                    date: Date(),
                    aspectRatio: session.recordedAspectRatio,
                    onStartReflecting: { },
                    onSaveComplete: { session.reset() }
                ),
                isActive: $navigateToVideo
            ) {
                EmptyView()
            }
            .hidden()
        }
    }

    // MARK: - Top bar bottom padding
    private var topBarBottomPad: CGFloat { session.isIdle ? 10 : 0 }

    // MARK: - Camera Background
    @ViewBuilder
    private var cameraBackground: some View {
        if camera.permissionGranted {
            GeometryReader { geo in
                let previewFrame = frameForRatio(camera.aspectRatio, in: geo.size)

                FilteredCameraPreview(
                    session: camera.session,
                    aspectRatio: camera.aspectRatio,
                    look: camera.activeLook
                )
                .frame(width: previewFrame.width, height: previewFrame.height)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    LensOverlayView(look: camera.activeLook)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                )
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .ignoresSafeArea()
            .background(Color.black.ignoresSafeArea())
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

    // MARK: - Aspect Ratio Frame Calculator
    private func frameForRatio(_ ratio: CameraManager.AspectRatio, in size: CGSize) -> CGSize {
        switch ratio {
        case .ratioFull:  return size
        case .ratio16_9:  return size
        case .ratio5_3:
            let h = size.width * (3.0 / 5.0)
            return CGSize(width: size.width, height: min(h, size.height))
        case .ratio1_1:
            let s = min(size.width, size.height)
            return CGSize(width: s, height: s)
        }
    }

    // MARK: - Top Bar
    @ViewBuilder
    private var topBar: some View {
        if session.isIdle {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedDate.uppercased())
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.55))
                        .tracking(1.5)
                    Text("How do you want today to feel?")
                        .font(.custom("Georgia-Italic", size: 20))
                        .foregroundStyle(.white)
                }
                Spacer()
            }
            .transition(.opacity.combined(with: .move(edge: .top)))

        } else {
            // Shooting mode top bar — X always visible, checkmark only when clips exist
            // Hide everything during active recording to keep screen clean
            if !camera.isRecording {
                HStack {
                    Button {
                        if camera.isRecording { camera.stopRecording { _ in } }
                        showDiscardSheet = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(.black.opacity(0.35)))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    if let lens = selectedLens {
                        directorPill(lens: lens)
                    }

                    Spacer()

                    Button {
                        if camera.isRecording { camera.stopRecording { _ in } }
                        showWrapSheet = true
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(.black.opacity(0.35)))
                    }
                    .buttonStyle(.plain)
                    .opacity(session.clips.isEmpty ? 0 : 1)
                    .disabled(session.clips.isEmpty)
                    .animation(.easeInOut(duration: 0.25), value: session.clips.isEmpty)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Top Card
    @ViewBuilder
    private var topCard: some View {
        if session.isIdle, let lens = selectedLens {
            VStack(alignment: .leading, spacing: 8) {
                Text("In the lens of \(lens.name)")
                    .font(.custom("Georgia-Italic", size: 18))
                    .foregroundStyle(.white)
                Text(lens.styleDescription)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(.white.opacity(0.6))
                    .italic()
                    .tracking(0.2)
                if !lens.tags.isEmpty {
                    Text(lens.tags.joined(separator: ", "))
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(.white.opacity(0.4))
                        .tracking(0.3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.black.opacity(0.45))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .id(lens.id)
            .transition(.opacity.combined(with: .move(edge: .top)))

        } else if session.isShooting, let prompt = session.currentPrompt {
            // Prompt card — hidden during active recording (guarded at call site)
            VStack(spacing: 14) {
                Text("\(session.currentPromptIndex + 1) of \(session.currentPrompts?.count ?? 4)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
                    .tracking(1.5)
                Text(prompt)
                    .font(.custom("Georgia-Italic", size: 20))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .id(session.currentPromptIndex)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal:   .opacity.combined(with: .move(edge: .top))
                    ))
                Text("Tap the button to record")
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(.white.opacity(0.3))
                    .tracking(0.3)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.black.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .transition(.opacity.combined(with: .move(edge: .top)))

        } else if session.isWrapping {
            VStack(spacing: 12) {
                Text("That's a wrap.")
                    .font(.custom("Georgia-Italic", size: 24))
                    .foregroundStyle(.white)
                Text("You captured \(session.clips.count) shot\(session.clips.count == 1 ? "" : "s").")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.black.opacity(0.45))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(selectedMood.accentColor.opacity(0.3), lineWidth: 1)
                    )
            )
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    // MARK: - Director Pill
    private func directorPill(lens: DirectorLens) -> some View {
        HStack(spacing: 8) {
            Group {
                if UIImage(named: lens.imageName) != nil {
                    Image(lens.imageName).resizable().scaledToFill()
                } else {
                    Circle().fill(.ultraThinMaterial)
                        .overlay(
                            Text(initials(lens.name))
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        )
                }
            }
            .frame(width: 28, height: 28)
            .clipShape(Circle())

            Text(lens.name)
                .font(.custom("Georgia-Italic", size: 14))
                .foregroundStyle(.white)
                .lineLimit(1)

            if POVData.hasLook(for: lens) {
                Circle()
                    .fill(Color.yellow.opacity(0.85))
                    .frame(width: 5, height: 5)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(.black.opacity(0.55))
                .overlay(Capsule().strokeBorder(.white.opacity(0.2), lineWidth: 1))
        )
    }

    // MARK: - Zoom Pill (above record row in shooting mode)
    private var zoomPill: some View {
        Button {
            let levels: [CGFloat] = [1.0, 2.0, 0.5]
            let idx = levels.firstIndex(of: camera.zoomFactor) ?? 0
            camera.setZoom(levels[(idx + 1) % levels.count])
        } label: {
            Text(zoomLabel)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(.black.opacity(0.5))
                        .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
    }

    private var zoomLabel: String {
        switch camera.zoomFactor {
        case 0.5: return ".5×"
        case 2.0: return "2×"
        default:  return "1×"
        }
    }

    // MARK: - Lens + Record Row
    private var lensAndRecordRow: some View {
        GeometryReader { geo in
            recordRowContent(totalWidth: geo.size.width)
        }
        .frame(height: 100)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func recordRowContent(totalWidth: CGFloat) -> some View {
        let shutterSize: CGFloat = 80
        let gap: CGFloat         = 16
        let sideWidth: CGFloat   = (totalWidth - shutterSize) / 2 - gap
        let centerX: CGFloat     = totalWidth / 2
        let leftMid: CGFloat     = sideWidth / 2
        let rightStart: CGFloat  = centerX + shutterSize / 2 + gap
        let rightMid: CGFloat    = rightStart + sideWidth / 2
        let midY: CGFloat        = 50

        ZStack(alignment: .leading) {
            if session.isIdle {
                // Lens strip to the right of the shutter
                InactiveLensStrip(
                    lenses: POVData.lenses(for: selectedMood),
                    selectedLens: $selectedLens,
                    isRecording: false
                )
                .frame(width: sideWidth + gap, height: shutterSize)
                .position(x: rightStart + (sideWidth + gap) / 2, y: midY)
                .transition(.opacity)

            } else {
                // Left side: flash + flip (hidden during recording)
                if !camera.isRecording {
                    leftControls
                        .frame(width: sideWidth, height: shutterSize)
                        .position(x: leftMid, y: midY)
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }

                // Right side: aspect ratio + menu
                rightControls
                    .frame(width: sideWidth, height: shutterSize)
                    .position(x: rightMid, y: midY)
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
            }

            // Shutter — always centred
            recordButton
                .frame(width: shutterSize, height: shutterSize)
                .position(x: centerX, y: midY)
        }
    }

    private var leftControls: some View {
        HStack(spacing: 12) {
            Spacer()
            ShootingControlButton(
                icon: camera.torchIsOn ? "bolt.fill" : "bolt.slash",
                isActive: camera.torchIsOn
            ) { camera.toggleTorch() }
            ShootingControlButton(icon: "arrow.triangle.2.circlepath") {
                camera.flipCamera()
            }
        }
    }

    private var rightControls: some View {
        HStack(spacing: 12) {
            Spacer().frame(width: 4)
            aspectRatioButton
            menuToggleButton
            Spacer()
        }
    }

    private var aspectRatioButton: some View {
        let ratioLocked = session.isShooting && !session.clips.isEmpty
        return ShootingControlButton(
            icon: "aspectratio",
            label: camera.aspectRatio.rawValue,
            isActive: false
        ) {
            if !ratioLocked {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    camera.toggleAspectRatio()
                }
            }
        }
        .opacity(camera.isRecording ? 0 : (ratioLocked ? 0.35 : 1.0))
    }

    private var menuToggleButton: some View {
        ZStack {
            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                    showExpandedControls.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(showExpandedControls ? .white.opacity(0.15) : .black.opacity(0.40))
                        .overlay(
                            Circle().strokeBorder(
                                .white.opacity(showExpandedControls ? 0.4 : 0.18),
                                lineWidth: 1
                            )
                        )
                        .frame(width: 46, height: 46)
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .opacity(camera.isRecording ? 0 : 1)
        }
        .overlay(alignment: .bottom) {
            if showExpandedControls {
                expandedControlsPill
                    .offset(y: -52)
                    .transition(.opacity.combined(with: .scale(scale: 0.85, anchor: .bottomTrailing)))
            }
        }
    }

    // Expanded pill rendered as an overlay so it floats above the row without clipping
    private var expandedControlsPill: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    camera.toggleSlowMotion()
                }
            } label: {
                VStack(spacing: 3) {
                    Image(systemName: camera.isSlowMotionEnabled
                          ? "gauge.with.dots.needle.67percent"
                          : "gauge.with.dots.needle.33percent")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(camera.isSlowMotionEnabled ? Color.yellow : .white)
                    Text("Slo-Mo")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(width: 46, height: 44)
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(.white.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    camera.cycleCountdownMode()
                }
            } label: {
                VStack(spacing: 3) {
                    Image(systemName: "timer")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(camera.countdownMode == .off ? .white : Color.yellow)
                    Text(camera.countdownMode.label)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(width: 46, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(LinearGradient(
                        colors: [.white.opacity(0.10), .clear],
                        startPoint: .top, endPoint: .center
                    ))
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(.white.opacity(0.14), lineWidth: 1)
            }
        )
        .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    // MARK: - Record Button
    @ViewBuilder
    private var recordButton: some View {
        if session.isIdle, let lens = selectedLens {
            ActiveLensShutter(lens: lens, isRecording: false, size: 76) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    session.startSession(mood: selectedMood, lens: lens)
                    session.recordedAspectRatio = camera.aspectRatio
                }
            }
        } else if session.isShooting || session.isWrapping {
            Button { handleShutterTap() } label: {
                ZStack {
                    Circle()
                        .strokeBorder(
                            camera.isRecording ? Color.red.opacity(0.8) : Color.white.opacity(0.85),
                            lineWidth: 3
                        )
                        .frame(width: 76, height: 76)
                    RoundedRectangle(cornerRadius: camera.isRecording ? 8 : 31, style: .continuous)
                        .fill(camera.isRecording ? Color.red : Color.white)
                        .frame(
                            width:  camera.isRecording ? 28 : 62,
                            height: camera.isRecording ? 28 : 62
                        )
                        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: camera.isRecording)
                }
            }
            .buttonStyle(.plain)
            .shadow(color: (camera.isRecording ? Color.red : Color.white).opacity(0.35), radius: 12)
        }
    }

    // MARK: - Shutter Logic
    private func handleShutterTap() {
        guard session.isShooting else { return }
        if camera.isRecording || camera.isCountingDown {
            camera.stopRecording { url in
                guard let url else { return }
                withAnimation { session.addClip(url: url) }
            }
        } else {
            camera.startRecording()
        }
    }

    // MARK: - Helpers
    private func initials(_ name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined()
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE · MMMM d"
        return f.string(from: Date())
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

// MARK: - Shooting Control Button (flat icon, left side)
private struct ShootingControlButton: View {
    let icon: String
    var label: String = ""
    var isActive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.black.opacity(0.40))
                    .overlay(Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1))
                    .frame(width: 46, height: 46)
                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(isActive ? Color.yellow : .white)
                    if !label.isEmpty {
                        Text(label)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Expandable Controls Menu (right side, shooting mode)
// Shows an aspect-ratio icon that expands into a small pill containing
// aspect ratio, slow-motion, and timer toggles.
private struct ExpandableControlsMenu: View {

    @ObservedObject var camera: CameraManager
    @Binding var isExpanded: Bool

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            if isExpanded {
                expandedPill
                    .transition(.opacity.combined(with: .scale(scale: 0.85, anchor: .trailing)))
            } else {
                collapsedButton
                    .transition(.opacity.combined(with: .scale(scale: 0.85, anchor: .trailing)))
            }
        }
    }

    // Single icon shown when collapsed
    private var collapsedButton: some View {
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                isExpanded = true
            }
        } label: {
            ZStack {
                Circle()
                    .fill(.black.opacity(0.40))
                    .overlay(Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1))
                    .frame(width: 46, height: 46)
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }

    // Expanded vertical pill with slo-mo + timer only
    private var expandedPill: some View {
        VStack(spacing: 0) {

            // Close button
            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                    isExpanded = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 46, height: 26)
            }
            .buttonStyle(.plain)

            pillDivider

            // Slow motion
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    camera.toggleSlowMotion()
                }
            } label: {
                VStack(spacing: 3) {
                    Image(systemName: camera.isSlowMotionEnabled
                          ? "gauge.with.dots.needle.67percent"
                          : "gauge.with.dots.needle.33percent")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(camera.isSlowMotionEnabled ? Color.yellow : .white)
                    Text("Slo-Mo")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(width: 46, height: 44)
            }
            .buttonStyle(.plain)

            pillDivider

            // Countdown timer
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    camera.cycleCountdownMode()
                }
            } label: {
                VStack(spacing: 3) {
                    Image(systemName: "timer")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(camera.countdownMode == .off ? .white : Color.yellow)
                    Text(camera.countdownMode.label)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(width: 46, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.10), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(.white.opacity(0.14), lineWidth: 1)
            }
        )
        .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var pillDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.1))
            .frame(height: 1)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
    }
}

// MARK: - Countdown Bubble (replaces the old overlay that lived in CameraControlsBar)
private struct CountdownBubble: View {
    let remaining: Int
    var body: some View {
        ZStack {
            Circle()
                .fill(.black.opacity(0.80))
                .frame(width: 64, height: 64)
                .overlay(Circle().strokeBorder(.white.opacity(0.3), lineWidth: 1.5))
            Text("\(remaining)")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText(countsDown: true))
                .animation(.spring(response: 0.3), value: remaining)
        }
        .shadow(color: .black.opacity(0.5), radius: 8)
    }
}

// MARK: - Film Viewfinder Overlay
struct FilmViewfinderOverlay: View {

    private let cornerLength: CGFloat = 28
    private let lineWidth:    CGFloat = 2.2
    private let inset:        CGFloat = 24

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                CornerBracket(corner: .topLeft)
                    .position(x: inset + cornerLength / 2, y: inset + cornerLength / 2)
                CornerBracket(corner: .topRight)
                    .position(x: w - inset - cornerLength / 2, y: inset + cornerLength / 2)
                CornerBracket(corner: .bottomLeft)
                    .position(x: inset + cornerLength / 2, y: h - inset - cornerLength / 2)
                CornerBracket(corner: .bottomRight)
                    .position(x: w - inset - cornerLength / 2, y: h - inset - cornerLength / 2)
            }
        }
    }
}

private enum BracketCorner { case topLeft, topRight, bottomLeft, bottomRight }

private struct CornerBracket: View {
    let corner: BracketCorner
    private let length: CGFloat = 28
    private let lineWidth: CGFloat = 2.2

    var body: some View {
        Canvas { ctx, size in
            let l  = length
            let lw = lineWidth
            var path = Path()

            switch corner {
            case .topLeft:
                path.move(to:    CGPoint(x: lw/2, y: l))
                path.addLine(to: CGPoint(x: lw/2, y: lw/2))
                path.addLine(to: CGPoint(x: l,    y: lw/2))
            case .topRight:
                path.move(to:    CGPoint(x: l - lw/2, y: l))
                path.addLine(to: CGPoint(x: l - lw/2, y: lw/2))
                path.addLine(to: CGPoint(x: 0,         y: lw/2))
            case .bottomLeft:
                path.move(to:    CGPoint(x: lw/2, y: 0))
                path.addLine(to: CGPoint(x: lw/2, y: l - lw/2))
                path.addLine(to: CGPoint(x: l,    y: l - lw/2))
            case .bottomRight:
                path.move(to:    CGPoint(x: l - lw/2, y: 0))
                path.addLine(to: CGPoint(x: l - lw/2, y: l - lw/2))
                path.addLine(to: CGPoint(x: 0,         y: l - lw/2))
            }

            ctx.stroke(path, with: .color(.white.opacity(0.85)),
                       style: StrokeStyle(lineWidth: lw, lineCap: .square))
        }
        .frame(width: length, height: length)
    }
}

// MARK: - Active Lens Shutter
struct ActiveLensShutter: View {
    let lens: DirectorLens
    let isRecording: Bool
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .strokeBorder(Color.white.opacity(0.85), lineWidth: 3)
                    .frame(width: size, height: size)
                if UIImage(named: lens.imageName) != nil {
                    Image(lens.imageName)
                        .resizable().scaledToFill()
                        .frame(width: size - 6, height: size - 6)
                        .clipShape(Circle())
                } else {
                    Circle().fill(.ultraThinMaterial)
                        .frame(width: size - 6, height: size - 6)
                        .overlay(
                            Text(initials(lens.name))
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .shadow(color: Color.white.opacity(0.3), radius: 12)
    }

    private func initials(_ name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined()
    }
}

// MARK: - Inactive Lens Strip
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
                        Circle().fill(.ultraThinMaterial).frame(width: itemSize, height: itemSize)
                        if UIImage(named: lens.imageName) != nil {
                            Image(lens.imageName).resizable().scaledToFill()
                                .frame(width: itemSize, height: itemSize).clipShape(Circle())
                        } else {
                            Text(initials(lens.name))
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        Circle().strokeBorder(Color.white.opacity(0.28), lineWidth: 1.2)
                            .frame(width: itemSize, height: itemSize)
                    }
                    .opacity(max(0.3, 0.7 - Double(idx) * 0.18))
                    .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, 12)
    }

    private func initials(_ name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined()
    }
}

// MARK: - Clip Tray
struct ClipTray: View {
    let clips: [RecordedClipModel]
    let onDelete: (RecordedClipModel) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(clips) { clip in
                    ClipThumb(clip: clip, onDelete: { onDelete(clip) })
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
        }
    }
}

// MARK: - Clip Thumbnail
private struct ClipThumb: View {
    let clip: RecordedClipModel
    let onDelete: () -> Void
    @State private var thumbnail: UIImage? = nil

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let thumb = thumbnail {
                    Image(uiImage: thumb).resizable().scaledToFill()
                } else {
                    Rectangle()
                        .fill(.white.opacity(0.08))
                        .overlay(
                            Image(systemName: "video.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.white.opacity(0.3))
                        )
                }
            }
            .frame(width: 56, height: 76)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
            )

            VStack {
                Spacer()
                HStack {
                    Text("\(clip.promptIndex + 1)")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Capsule().fill(.black.opacity(0.6)))
                        .padding(5)
                    Spacer()
                }
            }
            .frame(width: 56, height: 76)

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.5))
            }
            .buttonStyle(.plain)
            .offset(x: 6, y: -6)
        }
        .onAppear { generateThumbnail() }
    }

    private func generateThumbnail() {
        let asset = AVAsset(url: clip.url)
        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        DispatchQueue.global(qos: .userInitiated).async {
            let img = try? gen.copyCGImage(at: CMTime(seconds: 0.5, preferredTimescale: 600), actualTime: nil)
            DispatchQueue.main.async {
                thumbnail = img.map { UIImage(cgImage: $0) }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(white: 0.08).ignoresSafeArea()
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TUESDAY · MAY 19")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.55))
                        .tracking(1.5)
                    Text("How do you want today to feel?")
                        .font(.custom("Georgia-Italic", size: 20))
                        .foregroundStyle(.white)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            MoodSelectorView(moods: POVData.moods, selectedMood: .constant(POVData.moods[0]))
                .padding(.top, 10)
            Spacer()
        }
    }
}
