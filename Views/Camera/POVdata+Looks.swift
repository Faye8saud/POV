//
//  POVdata+Looks.swift
//  POV
//
//  Created by Fay  on 19/05/2026.
//
import Foundation

// MARK: - POVData + Looks
/// All directors not listed here return LensLook.none (no filter applied).
extension POVData {

    /// Returns the LensLook for a given director lens.
    /// Call this when the user selects a lens to set camera.activeLook.
    static func look(for lens: DirectorLens) -> LensLook {
        switch lens.name {

        // ── Tender ─────────────────────────────────────────────────────────
        case "Wong Kar-wai":
            // Neon greens/cyan, warm crushed shadows, heavy vignette + subtle grain
            return .wongKarWai

        // Sofia Coppola — about light and distance, not color → no filter
        // Hirokazu Kore-eda — naturalistic, no grade needed
        // Céline Sciamma — precise, cool, but the precision is framing not color

        // ── Restless ───────────────────────────────────────────────────────
        case "Lynne Ramsay":
            // Desaturated, gritty, textural — heavy vignette + grain
            return .lynneRamsay

        // Darren Aronofsky — visceral through movement/closeness, not color
        // Xavier Dolan — emotional but color varies widely per film
        // Park Chan-wook — precise color but requires scene-specific grade, not a blanket filter

        // ── Wandering ──────────────────────────────────────────────────────
        case "Wim Wenders":
            // Cold blue, faded, road-film melancholy
            return .wimWenders

        // Agnès Varda — warm and natural, a filter would betray her observational honesty
        // Richard Linklater — no grade, it's about real-time conversation
        // Jim Jarmusch — deadpan and cool but the color is deliberately flat/neutral

        // ── Charged ────────────────────────────────────────────────────────
        case "David Fincher":
            // Cold, blue-green, high contrast, artificial light
            return .davidFincher

        // Christopher Nolan — epic through scale + editing, not color
        // Denis Villeneuve — vast and quiet, color is restrained and context-specific
        // Paul Thomas Anderson — operatic but warm and naturalistic, no blanket grade

        // ── Playful ────────────────────────────────────────────────────────
        case "Wes Anderson":
            // Pastel warm, lifted blacks, flat light, letterbox bars
            return .wesAnderson

        // Michel Gondry — handmade/lo-fi, effect is about physical props not color
        // Bong Joon-ho — genre-mixing, contrast varies intentionally
        // Edgar Wright — rhythmic/kinetic, color is secondary to editing energy

        default:
            return .none
        }
    }

    /// Convenience: returns true if this lens has a visual filter applied.
    static func hasLook(for lens: DirectorLens) -> Bool {
        look(for: lens).name != "None"
    }
}
