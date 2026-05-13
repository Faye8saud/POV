//
//  CameraControlsBar.swift
//  POV
//
//  Created by Fay  on 11/05/2026.
//

import SwiftUI
 
// MARK: - Vertical Camera Controls Bar
struct CameraControlsBar: View {
 
    @ObservedObject var camera: CameraManager
 
    var body: some View {
        VStack(spacing: 0) {
            // Flash / Torch
            ControlButton(
                icon: camera.torchIsOn ? "bolt.fill" : "bolt.slash",
                label: camera.torchIsOn ? "On" : "Off",
                isActive: camera.torchIsOn
            ) {
                camera.toggleTorch()
            }
 
            divider
 
            // Flip camera
            ControlButton(icon: "arrow.triangle.2.circlepath", label: "Flip") {
                camera.flipCamera()
            }
 
            divider
 
            // Aspect ratio
            ControlButton(
                icon: "aspectratio",
                label: camera.aspectRatio.rawValue
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    camera.cycleAspectRatio()
                }
            }
 
            divider
 
            // Zoom
            ZoomControl(zoomFactor: camera.zoomFactor) { newZoom in
                camera.setZoom(newZoom)
            }
        }
        .padding(.vertical, 14)
        .frame(width: 52)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
 
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.10), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
 
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(.white.opacity(0.14), lineWidth: 1)
            }
        )
        .shadow(color: .black.opacity(0.4), radius: 14, y: 4)
    }
 
    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.1))
            .frame(height: 1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
    }
}
 
// MARK: - Generic Control Button
private struct ControlButton: View {
 
    let icon: String
    var label: String = ""
    var isActive: Bool = false
    let action: () -> Void
 
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(isActive ? Color.yellow : .white)
 
                if !label.isEmpty {
                    Text(label)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .frame(width: 52, height: 42)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
 
// MARK: - Zoom Toggle (1× / 2× / 0.5×)
private struct ZoomControl: View {
 
    let zoomFactor: CGFloat
    let onZoom: (CGFloat) -> Void
 
    private let levels: [CGFloat] = [1.0, 2.0, 0.5]
 
    var body: some View {
        Button {
            let currentIdx = levels.firstIndex(of: zoomFactor) ?? 0
            let nextZoom = levels[(currentIdx + 1) % levels.count]
            onZoom(nextZoom)
        } label: {
            VStack(spacing: 3) {
                Text(zoomLabel)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text("zoom")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(width: 52, height: 42)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
 
    private var zoomLabel: String {
        switch zoomFactor {
        case 0.5: return ".5×"
        case 2.0: return "2×"
        default:  return "1×"
        }
    }
}
 
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        HStack {
            Spacer()
            CameraControlsBar(camera: CameraManager())
                .padding(.trailing, 12)
        }
    }
}
