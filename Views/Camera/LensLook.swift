//
//  LensLook.swift
//  POV
//
//  Created by Fay  on 19/05/2026.
//
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Overlay Descriptor
/// Declarative description of a SwiftUI overlay to render on top of the camera preview.
struct LensOverlay {
    enum Kind {
        case vignette(intensity: Double)          // radial dark edge
        case grain(intensity: Double)             // animated film grain
        case letterbox(ratio: Double)             // black bars (ratio = bar height / screen height)
        case colorBleed(color: Color, opacity: Double) // subtle color cast overlay
    }
    let kind: Kind
}

// MARK: - Lens Look
/// Encapsulates the full visual identity of a director lens:
/// a Core Image filter chain for color grading + SwiftUI overlay descriptors.
struct LensLook {

    /// Human-readable name shown in the UI (e.g. "Wong Kar-wai Look")
    let name: String

    /// 0.0 – 1.0 global intensity multiplier. 1.0 = full effect, 0.0 = bypass.
    var intensity: Float = 1.0

    /// Ordered list of SwiftUI overlays to layer on top of the preview.
    let overlays: [LensOverlay]

    /// Applies the color grade to a `CIImage` and returns the result.
    /// All filter parameters are pre-baked per director; `intensity` blends with the original.
    let grade: (CIImage, Float) -> CIImage

    // MARK: - Director Looks

    /// Wong Kar-wai — saturated greens/cyan, warm crushed shadows, slight blur haze
    static let wongKarWai = LensLook(
        name: "Wong Kar-wai",
        overlays: [
            LensOverlay(kind: .vignette(intensity: 0.55)),
            LensOverlay(kind: .grain(intensity: 0.18)),
            LensOverlay(kind: .colorBleed(color: Color(red: 0.05, green: 0.9, blue: 0.6), opacity: 0.06))
        ],
        grade: { image, intensity in
            var result = image

            // 1. Boost saturation — vivid, almost over-saturated
            let saturate = CIFilter.colorControls()
            saturate.inputImage   = result
            saturate.saturation   = 1.0 + (0.65 * intensity)   // +65% saturation
            saturate.brightness   = -0.03 * intensity
            saturate.contrast     = 1.0 + (0.08 * intensity)
            result = saturate.outputImage ?? result

            // 2. Push green channel, pull red slightly — the WKW neon teal signature
            let colorMatrix = CIFilter.colorMatrix()
            colorMatrix.inputImage  = result
            // rVector, gVector, bVector, aVector — each is (r,g,b,a) multiplier for that channel
            colorMatrix.rVector = CIVector(x: 0.92, y: 0.0,  z: 0.0,  w: 0.0)   // reduce red
            colorMatrix.gVector = CIVector(x: 0.0,  y: 1.12, z: 0.05, w: 0.0)   // boost green, hint of blue
            colorMatrix.bVector = CIVector(x: 0.05, y: 0.08, z: 1.10, w: 0.0)   // boost blue/cyan
            colorMatrix.aVector = CIVector(x: 0.0,  y: 0.0,  z: 0.0,  w: 1.0)
            colorMatrix.biasVector = CIVector(x: 0.0, y: 0.0, z: 0.0, w: 0.0)
            result = colorMatrix.outputImage ?? result

            // 3. Warm the shadows (orange/amber shadow lift)
            let curves = CIFilter.toneCurve()
            curves.inputImage = result
            curves.point0 = CGPoint(x: 0.0,  y: 0.04)   // lift blacks (warm shadow base)
            curves.point1 = CGPoint(x: 0.25, y: 0.22)
            curves.point2 = CGPoint(x: 0.5,  y: 0.50)
            curves.point3 = CGPoint(x: 0.75, y: 0.76)
            curves.point4 = CGPoint(x: 1.0,  y: 1.0)
            result = curves.outputImage ?? result

            // 4. Blend with original based on intensity
            if intensity < 1.0 {
                let blend = CIFilter.dissolveTransition()
                blend.inputImage  = image
                blend.targetImage = result
                blend.time        = Float(CGFloat(intensity))
                result = blend.outputImage ?? result
            }

            return result
        }
    )

    /// Lynne Ramsay — desaturated, gritty, heavy vignette, muted mids
    static let lynneRamsay = LensLook(
        name: "Lynne Ramsay",
        overlays: [
            LensOverlay(kind: .vignette(intensity: 0.72)),
            LensOverlay(kind: .grain(intensity: 0.30)),
        ],
        grade: { image, intensity in
            var result = image

            // 1. Desaturate significantly — muted, almost monochrome but not quite
            let saturate = CIFilter.colorControls()
            saturate.inputImage = result
            saturate.saturation = 1.0 - (0.55 * intensity)   // -55% saturation
            saturate.contrast   = 1.0 + (0.12 * intensity)
            saturate.brightness = -0.05 * intensity
            result = saturate.outputImage ?? result

            // 2. Cool the image — slightly blue-grey cast
            let colorMatrix = CIFilter.colorMatrix()
            colorMatrix.inputImage = result
            colorMatrix.rVector = CIVector(x: 0.95, y: 0.0,  z: 0.0,  w: 0.0)
            colorMatrix.gVector = CIVector(x: 0.0,  y: 0.97, z: 0.02, w: 0.0)
            colorMatrix.bVector = CIVector(x: 0.02, y: 0.03, z: 1.05, w: 0.0)
            colorMatrix.aVector = CIVector(x: 0.0,  y: 0.0,  z: 0.0,  w: 1.0)
            colorMatrix.biasVector = CIVector(x: 0.0, y: 0.0, z: 0.0, w: 0.0)
            result = colorMatrix.outputImage ?? result

            // 3. Crush the blacks — no lifted shadows, she shoots into darkness
            let curves = CIFilter.toneCurve()
            curves.inputImage = result
            curves.point0 = CGPoint(x: 0.0,  y: 0.0)
            curves.point1 = CGPoint(x: 0.2,  y: 0.12)   // crush low mids
            curves.point2 = CGPoint(x: 0.5,  y: 0.48)
            curves.point3 = CGPoint(x: 0.75, y: 0.74)
            curves.point4 = CGPoint(x: 1.0,  y: 0.96)   // pull down highlights slightly
            result = curves.outputImage ?? result

            if intensity < 1.0 {
                let blend = CIFilter.dissolveTransition()
                blend.inputImage  = image
                blend.targetImage = result
                blend.time        = Float(CGFloat(intensity))
                result = blend.outputImage ?? result
            }

            return result
        }
    )

    /// Wim Wenders — faded, wide, cold-blue, melancholic road film
    static let wimWenders = LensLook(
        name: "Wim Wenders",
        overlays: [
            LensOverlay(kind: .vignette(intensity: 0.35)),
            LensOverlay(kind: .colorBleed(color: Color(red: 0.6, green: 0.75, blue: 1.0), opacity: 0.05))
        ],
        grade: { image, intensity in
            var result = image

            // 1. Slight desaturation — faded, not dead
            let saturate = CIFilter.colorControls()
            saturate.inputImage = result
            saturate.saturation = 1.0 - (0.28 * intensity)
            saturate.contrast   = 1.0 - (0.05 * intensity)   // slight contrast reduction = faded
            saturate.brightness = 0.02 * intensity
            result = saturate.outputImage ?? result

            // 2. Cold blue push — the road film sky cast
            let colorMatrix = CIFilter.colorMatrix()
            colorMatrix.inputImage = result
            colorMatrix.rVector = CIVector(x: 0.93, y: 0.0,  z: 0.0,  w: 0.0)
            colorMatrix.gVector = CIVector(x: 0.0,  y: 0.97, z: 0.03, w: 0.0)
            colorMatrix.bVector = CIVector(x: 0.04, y: 0.04, z: 1.08, w: 0.0)
            colorMatrix.aVector = CIVector(x: 0.0,  y: 0.0,  z: 0.0,  w: 1.0)
            colorMatrix.biasVector = CIVector(x: 0.0, y: 0.0, z: 0.0, w: 0.0)
            result = colorMatrix.outputImage ?? result

            // 3. Lift the shadows to a grey-blue — the faded film look
            let curves = CIFilter.toneCurve()
            curves.inputImage = result
            curves.point0 = CGPoint(x: 0.0,  y: 0.06)   // lift blacks to grey
            curves.point1 = CGPoint(x: 0.25, y: 0.26)
            curves.point2 = CGPoint(x: 0.5,  y: 0.50)
            curves.point3 = CGPoint(x: 0.75, y: 0.74)
            curves.point4 = CGPoint(x: 1.0,  y: 0.97)
            result = curves.outputImage ?? result

            if intensity < 1.0 {
                let blend = CIFilter.dissolveTransition()
                blend.inputImage  = image
                blend.targetImage = result
                blend.time        = Float(CGFloat(intensity))
                result = blend.outputImage ?? result
            }

            return result
        }
    )

    /// David Fincher — cold, high contrast, artificial light, desaturated yellow-green
    static let davidFincher = LensLook(
        name: "David Fincher",
        overlays: [
            LensOverlay(kind: .vignette(intensity: 0.45)),
            LensOverlay(kind: .grain(intensity: 0.10)),
        ],
        grade: { image, intensity in
            var result = image

            // 1. Desaturate with a cold push
            let saturate = CIFilter.colorControls()
            saturate.inputImage = result
            saturate.saturation = 1.0 - (0.35 * intensity)
            saturate.contrast   = 1.0 + (0.15 * intensity)   // higher contrast = sharper, colder
            saturate.brightness = -0.04 * intensity
            result = saturate.outputImage ?? result

            // 2. Pull warmth out, push into blue-green (the Fight Club / Se7en / Fincher grade)
            let colorMatrix = CIFilter.colorMatrix()
            colorMatrix.inputImage = result
            colorMatrix.rVector = CIVector(x: 0.88, y: 0.0,  z: 0.02, w: 0.0)   // reduce red
            colorMatrix.gVector = CIVector(x: 0.02, y: 1.02, z: 0.02, w: 0.0)   // slight green push
            colorMatrix.bVector = CIVector(x: 0.05, y: 0.05, z: 1.06, w: 0.0)   // push blue
            colorMatrix.aVector = CIVector(x: 0.0,  y: 0.0,  z: 0.0,  w: 1.0)
            colorMatrix.biasVector = CIVector(x: 0.0, y: 0.0, z: 0.0, w: 0.0)
            result = colorMatrix.outputImage ?? result

            // 3. Hard S-curve — crushed blacks, pulled highlights
            let curves = CIFilter.toneCurve()
            curves.inputImage = result
            curves.point0 = CGPoint(x: 0.0,  y: 0.0)    // true black
            curves.point1 = CGPoint(x: 0.2,  y: 0.10)   // crush shadows hard
            curves.point2 = CGPoint(x: 0.5,  y: 0.48)
            curves.point3 = CGPoint(x: 0.75, y: 0.73)
            curves.point4 = CGPoint(x: 1.0,  y: 0.95)   // pull highlights down
            result = curves.outputImage ?? result

            if intensity < 1.0 {
                let blend = CIFilter.dissolveTransition()
                blend.inputImage  = image
                blend.targetImage = result
                blend.time        = Float(CGFloat(intensity))
                result = blend.outputImage ?? result
            }

            return result
        }
    )

    /// Wes Anderson — pastel warm, lifted blacks, flat even light, high saturation in mids
    static let wesAnderson = LensLook(
        name: "Wes Anderson",
        overlays: [
            LensOverlay(kind: .letterbox(ratio: 0.055)),
            LensOverlay(kind: .colorBleed(color: Color(red: 1.0, green: 0.85, blue: 0.6), opacity: 0.04))
        ],
        grade: { image, intensity in
            var result = image

            // 1. Warm and slightly boost saturation — pastel means lifted, not dull
            let saturate = CIFilter.colorControls()
            saturate.inputImage = result
            saturate.saturation = 1.0 + (0.20 * intensity)
            saturate.contrast   = 1.0 - (0.08 * intensity)   // lower contrast = flatter, more pastel
            saturate.brightness = 0.04 * intensity
            result = saturate.outputImage ?? result

            // 2. Push warm — amber highlights, slightly pink mids
            let colorMatrix = CIFilter.colorMatrix()
            colorMatrix.inputImage = result
            colorMatrix.rVector = CIVector(x: 1.08, y: 0.0,  z: 0.0,  w: 0.0)   // boost red
            colorMatrix.gVector = CIVector(x: 0.02, y: 1.03, z: 0.0,  w: 0.0)   // slight green warmth
            colorMatrix.bVector = CIVector(x: 0.0,  y: 0.0,  z: 0.90, w: 0.0)   // pull blue down
            colorMatrix.aVector = CIVector(x: 0.0,  y: 0.0,  z: 0.0,  w: 1.0)
            colorMatrix.biasVector = CIVector(x: 0.0, y: 0.0, z: 0.0, w: 0.0)
            result = colorMatrix.outputImage ?? result

            // 3. Lift the blacks to a warm pastel base — no true black in a Wes frame
            let curves = CIFilter.toneCurve()
            curves.inputImage = result
            curves.point0 = CGPoint(x: 0.0,  y: 0.08)   // lifted blacks = pastel
            curves.point1 = CGPoint(x: 0.25, y: 0.28)
            curves.point2 = CGPoint(x: 0.5,  y: 0.52)
            curves.point3 = CGPoint(x: 0.75, y: 0.76)
            curves.point4 = CGPoint(x: 1.0,  y: 1.0)
            result = curves.outputImage ?? result

            if intensity < 1.0 {
                let blend = CIFilter.dissolveTransition()
                blend.inputImage  = image
                blend.targetImage = result
                blend.time        = Float(CGFloat(intensity))
                result = blend.outputImage ?? result
            }

            return result
        }
    )

    /// No filter — identity pass-through for directors without a look
    static let none = LensLook(
        name: "None",
        overlays: [],
        grade: { image, _ in image }
    )
}
