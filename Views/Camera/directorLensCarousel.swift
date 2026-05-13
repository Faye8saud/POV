//
//  directorLensCarousel.swift
//  POV
//
//  Created by Fay  on 11/05/2026.
//
import SwiftUI

// MARK: - Director Lens Row
/// Four director avatar circles that live to the RIGHT of the shutter button.
/// The leftmost (index 0) is the active/selected lens; the others trail off at
/// decreasing size and opacity — exactly like a filter strip.
/// Tap any avatar to select; swipe left/right to cycle.
struct DirectorLensRow: View {

    let lenses: [DirectorLens]
    @Binding var selectedLens: DirectorLens?

    @State private var currentIndex: Int = 0
    @State private var dragOffset:   CGFloat = 0

    private let activeSize:   CGFloat = 58
    private let inactiveSize: CGFloat = 44
    private let spacing:      CGFloat = 10

    var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            ForEach(Array(lenses.prefix(4).enumerated()), id: \.element.id) { idx, lens in
                let rel      = idx - currentIndex
                let isActive = rel == 0
                let visible  = rel >= 0 && rel <= 3

                if visible {
                    let size = isActive
                        ? activeSize
                        : max(28, inactiveSize - CGFloat(rel - 1) * 5)

                    DirectorAvatarCircle(lens: lens, isActive: isActive, size: size)
                        .opacity(isActive ? 1.0 : max(0.25, 0.65 - Double(rel - 1) * 0.2))
                        .onTapGesture { select(idx) }
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentIndex)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.leading, 16)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { v in dragOffset = v.translation.width }
                .onEnded { v in
                    if v.translation.width < -30 { select(min(currentIndex + 1, lenses.count - 1)) }
                    else if v.translation.width > 30 { select(max(currentIndex - 1, 0)) }
                    dragOffset = 0
                }
        )
        .onAppear        { currentIndex = 0; selectedLens = lenses.first }
        .onChange(of: lenses) { newLenses in
            currentIndex = 0
            selectedLens = newLenses.first
        }
    }

    private func select(_ idx: Int) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            currentIndex = idx
            selectedLens = lenses[safe: idx]
        }
    }
}

// MARK: - Avatar Circle
struct DirectorAvatarCircle: View {

    let lens:     DirectorLens
    let isActive: Bool
    let size:     CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: size, height: size)

            // Real photo if the asset exists, otherwise initials fallback
            if UIImage(named: lens.imageName) != nil {
                Image(lens.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Text(initials(lens.name))
                    .font(.system(size: isActive ? 15 : 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Circle()
                .strokeBorder(
                    isActive ? Color.white.opacity(0.95) : Color.white.opacity(0.28),
                    lineWidth: isActive ? 2.5 : 1.2
                )
                .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(isActive ? 0.5 : 0.2), radius: isActive ? 8 : 3, y: 2)
    }

    private func initials(_ name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined()
    }
}

// MARK: - Safe subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        HStack(alignment: .center, spacing: 0) {
            Circle()
                .strokeBorder(.white, lineWidth: 3)
                .frame(width: 76, height: 76)
 
            DirectorLensRow(
                lenses: POVData.lenses(for: POVData.moods[0]),
                selectedLens: .constant(nil)
            )
            .frame(width: 200)
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}
 
