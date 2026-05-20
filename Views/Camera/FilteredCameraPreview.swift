//
//  FilteredCameraPreview.swift
//  POV
//
//  Created by Fay  on 19/05/2026.
//
import SwiftUI
import AVFoundation
import CoreImage
import MetalKit

// MARK: - FilteredCameraPreview
struct FilteredCameraPreview: UIViewRepresentable {

    let session: AVCaptureSession
    let aspectRatio: CameraManager.AspectRatio
    let look: LensLook

    func makeUIView(context: Context) -> FilteredPreviewView {
        let view = FilteredPreviewView()
        view.configure(session: session)
        return view
    }

    func updateUIView(_ uiView: FilteredPreviewView, context: Context) {
        // Only update the look — never touch the session or Metal setup here
        uiView.updateLook(look)
    }
}

// MARK: - FilteredPreviewView
final class FilteredPreviewView: MTKView {

    // MARK: - Shared Metal resources
    // Created once as static constants — CIContext is extremely expensive to init
    private static let metalDevice: MTLDevice? = MTLCreateSystemDefaultDevice()
    private static let ciContext: CIContext? = {
        guard let device = metalDevice else { return nil }
        return CIContext(
            mtlDevice: device,
            options: [
                .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
                .outputColorSpace:  CGColorSpaceCreateDeviceRGB(),
                .useSoftwareRenderer: false
            ]
        )
    }()

    // MARK: - State (shared between outputQueue and Metal render thread)
    private let imageLock    = NSLock()
    private var latestImage: CIImage?
    private var currentLook: LensLook = .none

    // MARK: - AVFoundation
    private let videoOutput = AVCaptureVideoDataOutput()
    private let outputQueue = DispatchQueue(
        label: "com.pov.videoOutput",
        qos: .userInteractive
    )

    // MARK: - Init
    init() {
        super.init(frame: .zero, device: FilteredPreviewView.metalDevice)
        setupMetal()
    }

    required init(coder: NSCoder) { fatalError() }

    // MARK: - Metal Setup
    private func setupMetal() {
        guard let device = FilteredPreviewView.metalDevice else { return }
        self.device           = device
        delegate              = self           // MTKViewDelegate drives the render loop
        framebufferOnly       = false          // required so CIContext can write to the texture
        colorPixelFormat      = .bgra8Unorm
        contentScaleFactor    = UIScreen.main.scale
        contentMode           = .scaleAspectFill
        autoresizingMask      = [.flexibleWidth, .flexibleHeight]
        backgroundColor       = .black

        // Metal drives redraws at 30fps — matches camera output, no manual draw() calls needed
        isPaused              = false
        enableSetNeedsDisplay = false
        preferredFramesPerSecond = 30
    }

    // MARK: - Session Configuration
    func configure(session: AVCaptureSession) {
        session.beginConfiguration()

        // Remove any stale video data outputs to avoid duplicates on reconfigure
        session.outputs
            .compactMap { $0 as? AVCaptureVideoDataOutput }
            .forEach { session.removeOutput($0) }

        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: outputQueue)

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        // Rotate frames to portrait orientation
        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
        }

        session.commitConfiguration()
    }

    // Called from updateUIView — safe from any thread
    func updateLook(_ look: LensLook) {
        imageLock.lock()
        currentLook = look
        imageLock.unlock()
    }
}

// MARK: - MTKViewDelegate
// Metal calls draw(in:) at preferredFramesPerSecond automatically.
// We never call draw() manually — that was causing the frozen frame + lag.
extension FilteredPreviewView: MTKViewDelegate {

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // No action needed — transform is recalculated per frame
    }

    func draw(in view: MTKView) {
        // Grab the latest frame and look atomically
        imageLock.lock()
        guard var image = latestImage else {
            imageLock.unlock()
            return      // no frame yet — skip this draw cycle silently
        }
        let look = currentLook
        imageLock.unlock()

        // Apply the director's color grade (GPU-side, stays off main thread)
        image = look.grade(image, look.intensity)

        guard
            let ciContext = FilteredPreviewView.ciContext,
            let device    = self.device,
            let cmdQueue  = device.makeCommandQueue(),
            let cmdBuffer = cmdQueue.makeCommandBuffer(),
            let drawable  = view.currentDrawable
        else { return }

        let drawableSize = view.drawableSize

        // Scale to fill, centered — same logic as before but calculated fresh each frame
        let scaleX = drawableSize.width  / image.extent.width
        let scaleY = drawableSize.height / image.extent.height
        let scale  = max(scaleX, scaleY)

        let scaledW = image.extent.width  * scale
        let scaledH = image.extent.height * scale
        let offsetX = (drawableSize.width  - scaledW) / 2
        let offsetY = (drawableSize.height - scaledH) / 2

        let transformed = image
            .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            .transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))

        let destination = CIRenderDestination(
            width:  Int(drawableSize.width),
            height: Int(drawableSize.height),
            pixelFormat: view.colorPixelFormat,
            commandBuffer: cmdBuffer,
            mtlTextureProvider: { drawable.texture }
        )

        do {
            try ciContext.startTask(toRender: transformed, to: destination)
        } catch {
            return  // frame drop — not fatal
        }

        cmdBuffer.present(drawable)
        cmdBuffer.commit()
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension FilteredPreviewView: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Build the CIImage on outputQueue — stays off the main thread entirely.
        // MTKViewDelegate.draw() picks it up on the next Metal frame via the lock.
        // No DispatchQueue.main.async — that was the main bottleneck in the old version.
        let image = CIImage(cvPixelBuffer: pixelBuffer)

        imageLock.lock()
        latestImage = image
        imageLock.unlock()
    }
}
