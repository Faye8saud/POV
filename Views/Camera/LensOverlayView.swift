//
//  LensOverlayView.swift
//  POV
//
//  Created by Fay  on 19/05/2026.
//
import SwiftUI

// MARK: - LensOverlayView
/// Renders all SwiftUI overlay layers for a given LensLook on top of the camera preview.
/// Add this as a .overlay() on the FilteredCameraPreview.
struct LensOverlayView: View {

    let look: LensLook
    /// Animated grain seed — increment to animate grain flicker
    @State private var grainPhase: CGFloat = 0

    var body: some View {
        ZStack {
            ForEach(Array(look.overlays.enumerated()), id: \.offset) { _, overlay in
                overlayView(for: overlay)
            }
        }
        .onAppear {
            // Animate grain at ~12fps — cinematic, not smooth
            withAnimation(.linear(duration: 1 / 12).repeatForever(autoreverses: false)) {
                grainPhase = 1
            }
        }
        .allowsHitTesting(false) // never block camera interaction
    }

    @ViewBuilder
    private func overlayView(for overlay: LensOverlay) -> some View {
        switch overlay.kind {

        case .vignette(let intensity):
            VignetteOverlay(intensity: intensity)

        case .grain(let intensity):
            GrainOverlay(intensity: intensity, phase: grainPhase)

        case .letterbox(let ratio):
            LetterboxOverlay(barRatio: ratio)

        case .colorBleed(let color, let opacity):
            color.opacity(opacity)
                .blendMode(.screen)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Vignette
private struct VignetteOverlay: View {
    let intensity: Double

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let longer = max(size.width, size.height)

            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0.35),
                    .init(color: .clear, location: 0.55),
                    .init(color: Color.black.opacity(intensity * 0.5), location: 0.80),
                    .init(color: Color.black.opacity(intensity * 0.85), location: 1.0)
                ]),
                center: .center,
                startRadius: 0,
                endRadius: longer * 0.7
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Film Grain
/// A Canvas-based noise overlay. Re-draws when `phase` changes to animate.
private struct GrainOverlay: View {
    let intensity: Double
    let phase: CGFloat

    var body: some View {
        Canvas { context, size in
            // Generate a grid of random noise dots
            // Seed with phase so grain shifts each frame
            let seed = Int(phase * 1000) % 997   // prime to avoid patterns
            var rng = SeededRNG(seed: seed)

            let dotSize: CGFloat = 1.5
            let step: CGFloat = 3.0
            let cols = Int(size.width  / step) + 1
            let rows = Int(size.height / step) + 1

            for row in 0..<rows {
                for col in 0..<cols {
                    let brightness = rng.nextFloat()
                    guard brightness < Float(intensity) * 0.6 else { continue }

                    let x = CGFloat(col) * step + rng.nextCGFloat() * step
                    let y = CGFloat(row) * step + rng.nextCGFloat() * step
                    let alpha = Double(brightness / (Float(intensity) * 0.6)) * intensity * 0.7

                    let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                    let path = Path(ellipseIn: rect)
                    context.fill(path, with: .color(Color.white.opacity(alpha)))
                }
            }
        }
        .ignoresSafeArea()
        .blendMode(.overlay)
        .allowsHitTesting(false)
    }
}

// MARK: - Letterbox
private struct LetterboxOverlay: View {
    /// Fraction of screen height each bar takes (top and bottom)
    let barRatio: Double

    var body: some View {
        GeometryReader { geo in
            let barHeight = geo.size.height * barRatio
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.black)
                    .frame(height: barHeight)
                Spacer()
                Rectangle()
                    .fill(Color.black)
                    .frame(height: barHeight)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Seeded RNG (deterministic per frame, avoids SwiftUI state churn)
private struct SeededRNG {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed &* 6364136223846793005 &+ 1442695040888963407))
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }

    mutating func nextFloat() -> Float {
        Float(next() >> 33) / Float(0x7FFFFFFF)
    }

    mutating func nextCGFloat() -> CGFloat {
        CGFloat(nextFloat())
    }
}
