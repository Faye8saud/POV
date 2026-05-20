//
//  CameraManager.swift
//  POV
//
//  Created by Fay  on 11/05/2026.
//
/*
import AVFoundation
import SwiftUI
import Combine

// MARK: - Camera Manager
final class CameraManager: NSObject, ObservableObject {

    // MARK: Published State
    @Published var isRecording        = false
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var torchIsOn          = false
    @Published var zoomFactor: CGFloat = 1.0
    @Published var aspectRatio: AspectRatio = .ratio5_3
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    @Published var recordingDuration: TimeInterval = 0
    @Published var permissionGranted  = false

    // MARK: Slow Motion
    @Published var isSlowMotionEnabled = false

    // MARK: Countdown Timer
    enum CountdownMode: Int, CaseIterable {
        case off    = 0
        case three  = 3
        case ten    = 10

        var label: String {
            switch self {
            case .off:   return "Off"
            case .three: return "3s"
            case .ten:   return "10s"
            }
        }
    }
    @Published var countdownMode: CountdownMode = .off
    /// > 0 while countdown is running; 0 when idle
    @Published var countdownRemaining: Int = 0
    var isCountingDown: Bool { countdownRemaining > 0 }

    // MARK: AVFoundation
    let session = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var movieOutput = AVCaptureMovieFileOutput()
    private var sessionQueue = DispatchQueue(label: "com.pov.cameraSession")

    // MARK: Timers
    private var recordingTimer: AnyCancellable?
    private var countdownTimer: AnyCancellable?

    // MARK: Completion callback for clip saving
    private var recordingCompletion: ((URL?) -> Void)?

    // MARK: Aspect Ratio
    enum AspectRatio: String, CaseIterable {
        case ratio5_3  = "5:3"
        case ratio16_9 = "16:9"
        case ratio1_1  = "1:1"
        case ratioFull = "Full"

        var value: CGFloat {
            switch self {
            case .ratio5_3:  return 5 / 3
            case .ratio16_9: return 16 / 9
            case .ratio1_1:  return 1
            case .ratioFull: return 0
            }
        }
    }

    // MARK: - Lifecycle
    override init() {
        super.init()
        checkPermissions()
    }

    // MARK: - Permissions
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                    if granted { self?.setupSession() }
                }
            }
        default:
            permissionGranted = false
        }
    }

    // MARK: - Session Setup
    func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.cameraPosition),
                let input  = try? AVCaptureDeviceInput(device: device)
            else { self.session.commitConfiguration(); return }

            if self.session.canAddInput(input) {
                self.session.addInput(input)
                self.videoDeviceInput = input
            }

            if let audioDevice = AVCaptureDevice.default(for: .audio),
               let audioInput  = try? AVCaptureDeviceInput(device: audioDevice),
               self.session.canAddInput(audioInput) {
                self.session.addInput(audioInput)
            }

            if self.session.canAddOutput(self.movieOutput) {
                self.session.addOutput(self.movieOutput)
            }

            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }

    // MARK: - Recording

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecordingWithCountdown()
        }
    }

    /// Starts a countdown (if configured) then fires the actual recording.
    /// Calls `completion` once the recording file is ready.
    func startRecordingWithCountdownAndCompletion(_ completion: @escaping (URL?) -> Void) {
        guard countdownMode == .off else {
            // Run countdown first
            countdownRemaining = countdownMode.rawValue
            countdownTimer = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let self else { return }
                    if self.countdownRemaining > 1 {
                        self.countdownRemaining -= 1
                    } else {
                        self.countdownTimer?.cancel()
                        self.countdownRemaining = 0
                        self.beginCapture(completion: completion)
                    }
                }
            return
        }
        beginCapture(completion: completion)
    }

    private func startRecordingWithCountdown() {
        startRecordingWithCountdownAndCompletion { _ in }
    }

    private func beginCapture(completion: @escaping (URL?) -> Void) {
        guard !movieOutput.isRecording else { return }

        // Configure slow motion on the video device before starting
        configureSlowMotion(enabled: isSlowMotionEnabled)

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        recordingCompletion = completion
        movieOutput.startRecording(to: outputURL, recordingDelegate: self)

        DispatchQueue.main.async { [weak self] in
            self?.isRecording = true
            self?.recordingDuration = 0
            self?.recordingTimer = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in self?.recordingDuration += 1 }
        }
    }

    func stopRecordingWithCompletion(_ completion: @escaping (URL?) -> Void) {
        // Cancel any in-progress countdown
        if isCountingDown {
            countdownTimer?.cancel()
            countdownRemaining = 0
            completion(nil)
            return
        }

        guard movieOutput.isRecording else {
            completion(nil)
            return
        }
        recordingCompletion = completion
        movieOutput.stopRecording()
        recordingTimer?.cancel()
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
        }
    }

    private func stopRecording() {
        stopRecordingWithCompletion { _ in }
    }

    // MARK: - Slow Motion

    func toggleSlowMotion() {
        isSlowMotionEnabled.toggle()
        // If already recording, reconfigure live (best-effort)
        if movieOutput.isRecording {
            configureSlowMotion(enabled: isSlowMotionEnabled)
        }
    }

    /// Attempts to switch to a 120 fps format for slow motion, or back to a default 30 fps configuration.
    private func configureSlowMotion(enabled: Bool) {
        sessionQueue.async { [weak self] in
            guard let self,
                  let device = self.videoDeviceInput?.device,
                  (try? device.lockForConfiguration()) != nil
            else { return }
            defer { device.unlockForConfiguration() }

            func setDeviceFPS(_ fps: Double) {
                // Clamp fps to supported range of active format
                let ranges = device.activeFormat.videoSupportedFrameRateRanges
                guard let bestRange = ranges.max(by: { $0.maxFrameRate < $1.maxFrameRate }) else { return }
                let clampedFPS = min(max(fps, bestRange.minFrameRate), bestRange.maxFrameRate)
                let time = CMTimeMake(value: 1, timescale: Int32(clampedFPS))
                device.activeVideoMinFrameDuration = time
                device.activeVideoMaxFrameDuration = time
            }

            if enabled {
                let targetFPS: Double = 120

                // Pick a format that supports at least targetFPS, prefer higher resolution
                let slowFormat = device.formats
                    .filter { format in
                        format.videoSupportedFrameRateRanges.contains { $0.maxFrameRate >= targetFPS }
                    }
                    .sorted { lhs, rhs in
                        let ld = CMVideoFormatDescriptionGetDimensions(lhs.formatDescription)
                        let rd = CMVideoFormatDescriptionGetDimensions(rhs.formatDescription)
                        return ld.width * ld.height < rd.width * rd.height
                    }
                    .last

                if let fmt = slowFormat {
                    device.activeFormat = fmt
                    setDeviceFPS(targetFPS)
                }
            } else {
                // Choose a reasonable default format (up to 60 fps, >= 1280 width), then set 30 fps
                let defaultFormat = device.formats
                    .filter { format in
                        let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                        let supportsUpTo60 = format.videoSupportedFrameRateRanges.contains { $0.maxFrameRate >= 30 }
                        return dims.width >= 1280 && supportsUpTo60
                    }
                    .sorted { lhs, rhs in
                        let ld = CMVideoFormatDescriptionGetDimensions(lhs.formatDescription)
                        let rd = CMVideoFormatDescriptionGetDimensions(rhs.formatDescription)
                        return ld.width * ld.height < rd.width * rd.height
                    }
                    .last

                if let fmt = defaultFormat {
                    device.activeFormat = fmt
                }
                setDeviceFPS(30)
            }
        }
    }

    // MARK: - Countdown Mode Cycling

    func cycleCountdownMode() {
        switch countdownMode {
        case .off:   countdownMode = .three
        case .three: countdownMode = .ten
        case .ten:   countdownMode = .off
        }
    }

    // MARK: - Camera Controls

    func flipCamera() {
        sessionQueue.async { [weak self] in
            guard let self, let currentInput = self.videoDeviceInput else { return }
            let newPosition: AVCaptureDevice.Position = self.cameraPosition == .back ? .front : .back

            guard
                let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
                let newInput  = try? AVCaptureDeviceInput(device: newDevice)
            else { return }

            self.session.beginConfiguration()
            self.session.removeInput(currentInput)
            if self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.videoDeviceInput = newInput
            }
            self.session.commitConfiguration()

            DispatchQueue.main.async { self.cameraPosition = newPosition }
        }
    }

    func toggleTorch() {
        guard
            let device = videoDeviceInput?.device,
            device.hasTorch,
            (try? device.lockForConfiguration()) != nil
        else { return }
        defer { device.unlockForConfiguration() }

        torchIsOn.toggle()
        device.torchMode = torchIsOn ? .on : .off
    }

    func setZoom(_ factor: CGFloat) {
        guard
            let device = videoDeviceInput?.device,
            (try? device.lockForConfiguration()) != nil
        else { return }
        defer { device.unlockForConfiguration() }

        let clamped = max(1.0, min(factor, device.activeFormat.videoMaxZoomFactor))
        device.videoZoomFactor = clamped
        DispatchQueue.main.async { self.zoomFactor = clamped }
    }

    func toggleAspectRatio() {
        aspectRatio = aspectRatio == .ratio5_3 ? .ratio16_9 : .ratio5_3
    }

    // MARK: - Formatting
    var formattedDuration: String {
        let m = Int(recordingDuration) / 60
        let s = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        let url = error == nil ? outputFileURL : nil
        DispatchQueue.main.async { [weak self] in
            self?.recordingCompletion?(url)
            self?.recordingCompletion = nil
        }
    }
}
*/
import AVFoundation
import SwiftUI
import CoreImage
import Combine

// MARK: - Camera Manager
final class CameraManager: NSObject, ObservableObject {

    // MARK: - Published State
    @Published var isRecording        = false
    @Published var torchIsOn          = false
    @Published var zoomFactor: CGFloat = 1.0
    @Published var aspectRatio: AspectRatio = .ratio5_3
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    @Published var recordingDuration: TimeInterval = 0
    @Published var permissionGranted  = false
    @Published var isSlowMotionEnabled = false
    @Published var activeLook: LensLook = .none
    @Published var bakeFilterOnExport: Bool = true
    @Published var countdownMode: CountdownMode = .off
    @Published var countdownRemaining: Int = 0

    var isCountingDown: Bool { countdownRemaining > 0 }

    // MARK: - Aspect Ratio
    enum AspectRatio: String, CaseIterable {
        case ratio5_3  = "5:3"
        case ratio16_9 = "16:9"
        case ratio1_1  = "1:1"
        case ratioFull = "Full"

        var value: CGFloat {
            switch self {
            case .ratio5_3:  return 5 / 3
            case .ratio16_9: return 16 / 9
            case .ratio1_1:  return 1
            case .ratioFull: return 0
            }
        }
    }

    // MARK: - Countdown Mode
    enum CountdownMode: Int, CaseIterable {
        case off   = 0
        case three = 3
        case ten   = 10

        var label: String {
            switch self {
            case .off:   return "Off"
            case .three: return "3s"
            case .ten:   return "10s"
            }
        }
    }

    // MARK: - AVFoundation
    let session = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var movieOutput = AVCaptureMovieFileOutput()
    private let sessionQueue = DispatchQueue(label: "com.pov.cameraSession")

    // MARK: - Timers
    private var recordingTimer: AnyCancellable?
    private var countdownTimer: AnyCancellable?

    // MARK: - Clip save callback
    private var clipSaveCompletion: ((URL?) -> Void)?

    // MARK: - Lifecycle
    override init() {
        super.init()
        checkPermissions()
    }

    // MARK: - Permissions
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                    if granted { self?.setupSession() }
                }
            }
        default:
            permissionGranted = false
        }
    }

    // MARK: - Session Setup
    func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                     for: .video,
                                                     position: self.cameraPosition),
                let input = try? AVCaptureDeviceInput(device: device)
            else {
                self.session.commitConfiguration()
                return
            }

            if self.session.canAddInput(input) {
                self.session.addInput(input)
                self.videoDeviceInput = input
            }

            if let audioDevice = AVCaptureDevice.default(for: .audio),
               let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
               self.session.canAddInput(audioInput) {
                self.session.addInput(audioInput)
            }

            if self.session.canAddOutput(self.movieOutput) {
                self.session.addOutput(self.movieOutput)
            }

            self.session.commitConfiguration()
            // Fix orientation on initial setup
            self.fixVideoOrientation()
            self.session.startRunning()
        }
    }

    // MARK: - Look
    func setLook(_ look: LensLook) {
        DispatchQueue.main.async { self.activeLook = look }
    }

    // MARK: - Recording: START
    func startRecording() {
        guard !isRecording && !isCountingDown else { return }

        if countdownMode == .off {
            beginCapture()
        } else {
            countdownRemaining = countdownMode.rawValue
            countdownTimer = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let self else { return }
                    if self.countdownRemaining > 1 {
                        self.countdownRemaining -= 1
                    } else {
                        self.countdownTimer?.cancel()
                        self.countdownRemaining = 0
                        self.beginCapture()
                    }
                }
        }
    }

    private func beginCapture() {
        guard !movieOutput.isRecording else { return }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        let wantSlowMo = isSlowMotionEnabled

        sessionQueue.async { [weak self] in
            guard let self else { return }

            if wantSlowMo {
                self.applyFrameRate(fps: 120, to: self.videoDeviceInput?.device)
            }

            // Ensure portrait orientation before recording starts
            self.fixVideoOrientation()

            self.movieOutput.startRecording(to: outputURL, recordingDelegate: self)

            DispatchQueue.main.async {
                self.isRecording = true
                self.recordingDuration = 0
                self.recordingTimer = Timer.publish(every: 1, on: .main, in: .common)
                    .autoconnect()
                    .sink { [weak self] _ in self?.recordingDuration += 1 }
            }
        }
    }

    // MARK: - Recording: STOP
    func stopRecording(completion: @escaping (URL?) -> Void) {
        if isCountingDown {
            countdownTimer?.cancel()
            DispatchQueue.main.async { [weak self] in
                self?.countdownRemaining = 0
            }
            completion(nil)
            return
        }

        guard movieOutput.isRecording else {
            completion(nil)
            return
        }

        let look = activeLook
        let shouldBake = bakeFilterOnExport && !look.overlays.isEmpty

        clipSaveCompletion = { [weak self] rawURL in
            guard let rawURL else { completion(nil); return }
            if shouldBake {
                self?.applyFilter(to: rawURL, look: look, completion: completion)
            } else {
                completion(rawURL)
            }
        }

        movieOutput.stopRecording()

        recordingTimer?.cancel()
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
        }
    }

    // MARK: - Filter Baking
    private func applyFilter(to inputURL: URL,
                             look: LensLook,
                             completion: @escaping (URL?) -> Void) {
        let asset = AVURLAsset(url: inputURL)
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            completion(inputURL)
            return
        }

        let composition = AVVideoComposition(asset: asset) { request in
            let filtered = look.grade(request.sourceImage, look.intensity)
            request.finish(with: filtered, context: nil)
        }

        exportSession.outputURL        = outputURL
        exportSession.outputFileType   = .mov
        exportSession.videoComposition = composition

        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                if exportSession.status == .completed {
                    try? FileManager.default.removeItem(at: inputURL)
                    completion(outputURL)
                } else {
                    completion(inputURL)
                }
            }
        }
    }

    // MARK: - Camera Controls

    func flipCamera() {
        sessionQueue.async { [weak self] in
            guard let self, let currentInput = self.videoDeviceInput else { return }
            let newPosition: AVCaptureDevice.Position = self.cameraPosition == .back ? .front : .back
            guard
                let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                        for: .video,
                                                        position: newPosition),
                let newInput = try? AVCaptureDeviceInput(device: newDevice)
            else { return }

            self.session.beginConfiguration()
            self.session.removeInput(currentInput)
            if self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.videoDeviceInput = newInput
            }
            self.session.commitConfiguration()

            // ── Fix orientation after flip ──────────────────────────────────
            // AVCaptureSession resets the video connection orientation when the
            // input changes, defaulting to landscape on some devices. Force
            // portrait here so the preview and recorded file stay upright.
            self.fixVideoOrientation()

            DispatchQueue.main.async { self.cameraPosition = newPosition }
        }
    }

    /// Forces all video connections (preview + movie output) to portrait orientation.
    /// Must be called on sessionQueue.
    private func fixVideoOrientation() {
        let portraitOrientation = AVCaptureVideoOrientation.portrait
        for output in session.outputs {
            for connection in output.connections {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = portraitOrientation
                }
            }
        }
        // Also fix the preview layer connection if present
        if let previewConnection = session.connections.first(where: {
            $0.isVideoOrientationSupported
        }) {
            previewConnection.videoOrientation = portraitOrientation
        }
    }

    func toggleTorch() {
        guard
            let device = videoDeviceInput?.device,
            device.hasTorch,
            (try? device.lockForConfiguration()) != nil
        else { return }
        defer { device.unlockForConfiguration() }
        torchIsOn.toggle()
        device.torchMode = torchIsOn ? .on : .off
    }

    func setZoom(_ factor: CGFloat) {
        guard
            let device = videoDeviceInput?.device,
            (try? device.lockForConfiguration()) != nil
        else { return }
        defer { device.unlockForConfiguration() }
        let clamped = max(1.0, min(factor, device.activeFormat.videoMaxZoomFactor))
        device.videoZoomFactor = clamped
        DispatchQueue.main.async { self.zoomFactor = clamped }
    }

    func toggleAspectRatio() {
        aspectRatio = aspectRatio == .ratio5_3 ? .ratio16_9 : .ratio5_3
    }

    func toggleSlowMotion() {
        isSlowMotionEnabled.toggle()
    }

    func cycleCountdownMode() {
        switch countdownMode {
        case .off:   countdownMode = .three
        case .three: countdownMode = .ten
        case .ten:   countdownMode = .off
        }
    }

    // MARK: - Frame Rate (slow motion)
    private func applyFrameRate(fps: Double, to device: AVCaptureDevice?) {
        guard
            let device = device,
            (try? device.lockForConfiguration()) != nil
        else { return }
        defer { device.unlockForConfiguration() }

        let wantedWidth: Int32 = 1280
        if let format = device.formats.last(where: {
            CMVideoFormatDescriptionGetDimensions($0.formatDescription).width >= wantedWidth &&
            $0.videoSupportedFrameRateRanges.contains { $0.maxFrameRate >= fps }
        }) {
            device.activeFormat = format
        }

        let timescale = Int32(fps)
        device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: timescale)
        device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: timescale)
    }

    private func restoreFrameRate(on device: AVCaptureDevice?) {
        guard
            let device = device,
            (try? device.lockForConfiguration()) != nil
        else { return }
        defer { device.unlockForConfiguration() }

        if let format = device.formats.last(where: {
            CMVideoFormatDescriptionGetDimensions($0.formatDescription).width >= 1280 &&
            $0.videoSupportedFrameRateRanges.contains { $0.maxFrameRate <= 60 }
        }) {
            device.activeFormat = format
        }
        device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 30)
        device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 30)
    }

    // MARK: - Formatting
    var formattedDuration: String {
        let m = Int(recordingDuration) / 60
        let s = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        if isSlowMotionEnabled {
            sessionQueue.async { [weak self] in
                self?.restoreFrameRate(on: self?.videoDeviceInput?.device)
            }
        }

        let completion = clipSaveCompletion
        clipSaveCompletion = nil

        let url = error == nil ? outputFileURL : nil
        DispatchQueue.main.async {
            completion?(url)
        }
    }
}
