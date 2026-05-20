//
//  CameraManager.swift
//  POV
//
//  Created by Fay  on 11/05/2026.
//

import AVFoundation
import SwiftUI
import Combine
 
// MARK: - Camera Manager
final class CameraManager: NSObject, ObservableObject {
 
    // MARK: Published State
    @Published var isRecording    = false
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var torchIsOn      = false
    @Published var zoomFactor: CGFloat = 1.0
    @Published var aspectRatio: AspectRatio = .ratio4_3
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    @Published var recordingDuration: TimeInterval = 0
    @Published var permissionGranted = false

    var onRecordingFinished: ((URL, TimeInterval) -> Void)?
 
    // MARK: AVFoundation
    let session = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var movieOutput = AVCaptureMovieFileOutput()
    private var sessionQueue = DispatchQueue(label: "com.pov.cameraSession")
 
    // MARK: Recording Timer
    private var timer: AnyCancellable?
 
    // MARK: Aspect Ratio
    enum AspectRatio: String, CaseIterable {
        case ratio4_3  = "4:3"
        case ratio16_9 = "16:9"
        case ratio1_1  = "1:1"
        case ratioFull = "Full"
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
 
            // Video input
            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.cameraPosition),
                let input  = try? AVCaptureDeviceInput(device: device)
            else { self.session.commitConfiguration(); return }
 
            if self.session.canAddInput(input) {
                self.session.addInput(input)
                self.videoDeviceInput = input
            }
 
            // Audio input
            if let audioDevice = AVCaptureDevice.default(for: .audio),
               let audioInput  = try? AVCaptureDeviceInput(device: audioDevice),
               self.session.canAddInput(audioInput) {
                self.session.addInput(audioInput)
            }
 
            // Movie output
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
            startRecording()
        }
    }
 
    private func startRecording() {
        guard !movieOutput.isRecording else { return }
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
 
        movieOutput.startRecording(to: outputURL, recordingDelegate: self)
 
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = true
            self?.recordingDuration = 0
            self?.timer = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in self?.recordingDuration += 1 }
        }
    }
 
    private func stopRecording() {
        movieOutput.stopRecording()
        timer?.cancel()
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
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
 
    func cycleAspectRatio() {
        let all = AspectRatio.allCases
        let idx = (all.firstIndex(of: aspectRatio) ?? 0 + 1) % all.count
        aspectRatio = all[idx]
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
        guard error == nil else {
            print("Recording failed: \(error?.localizedDescription ?? "Unknown error")")
            return
        }

        let duration = recordingDuration
        DispatchQueue.main.async { [weak self] in
            self?.onRecordingFinished?(outputFileURL, duration)
        }
    }
}
