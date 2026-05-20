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
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {

            // ── Always-visible controls ──────────────────────────────
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
                    camera.toggleAspectRatio()
                }
            }

            divider

            // Zoom
            ZoomControl(zoomFactor: camera.zoomFactor) { newZoom in
                camera.setZoom(newZoom)
            }

            // ── Expander chevron ─────────────────────────────────────
            divider

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .frame(width: 50, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // ── Expandable controls ──────────────────────────────────
            if isExpanded {
                divider

                // Slow Motion
                ControlButton(
                    icon: camera.isSlowMotionEnabled ? "gauge.with.dots.needle.67percent" : "gauge.with.dots.needle.33percent",
                    label: "Slo-Mo",
                    isActive: camera.isSlowMotionEnabled
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        camera.toggleSlowMotion()
                    }
                }

                divider

                // Countdown Timer
                CountdownButton(mode: camera.countdownMode) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        camera.cycleCountdownMode()
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .frame(width: 50)
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
        // Clip so the expanding section doesn't bleed outside the pill
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        // Overlay the countdown bubble centered above the bar
        .overlay(alignment: .top) {
            if camera.isCountingDown {
                CountdownOverlay(remaining: camera.countdownRemaining)
                    .offset(y: -54)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7),
                               value: camera.countdownRemaining)
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.1))
            .frame(height: 1)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
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
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(isActive ? Color.yellow : .white)

                if !label.isEmpty {
                    Text(label)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .frame(width: 50, height: 40)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Countdown Button
private struct CountdownButton: View {

    let mode: CameraManager.CountdownMode
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: "timer")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(mode == .off ? .white : Color.yellow)

                Text(mode.label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(width: 50, height: 40)
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
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text("zoom")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(width: 50, height: 40)
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

// MARK: - Countdown Overlay Bubble
private struct CountdownOverlay: View {

    let remaining: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(.black.opacity(0.80))
                .frame(width: 56, height: 56)
                .overlay(
                    Circle()
                        .strokeBorder(.white.opacity(0.3), lineWidth: 1.5)
                )

            Text("\(remaining)")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText(countsDown: true))
                .animation(.spring(response: 0.3), value: remaining)
        }
        .shadow(color: .black.opacity(0.5), radius: 8)
    }
}
