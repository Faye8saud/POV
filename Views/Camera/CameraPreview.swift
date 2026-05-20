//
//  CameraPreview.swift
//  POV
//
//  Created by Fay  on 11/05/2026.
//
import SwiftUI
import AVFoundation

// MARK: - Camera Preview Layer (UIKit bridge)
struct CameraPreview: UIViewRepresentable {

    let session: AVCaptureSession
    var aspectRatio: CameraManager.AspectRatio

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.videoGravity = .resizeAspectFill
    }

    // MARK: - UIView subclass exposing the AVCaptureVideoPreviewLayer
    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
