//
//  MoodSelectorView.swift
//  POV
//
//  Created by Fay  on 11/05/2026.
//
import SwiftUI

// MARK: - Mood Selector Strip
struct MoodSelectorView: View {

    let moods: [Mood]
    @Binding var selectedMood: Mood

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(moods) { mood in
                    MoodPill(mood: mood, isSelected: selectedMood.id == mood.id)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                selectedMood = mood
                            }
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Single Mood Pill
private struct MoodPill: View {

    let mood: Mood
    let isSelected: Bool

    var body: some View {
        Text(mood.name)
            .font(.custom("Georgia-Italic", size: 14))
            .foregroundStyle(isSelected ? .white : mood.accentColor)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(isSelected ? mood.color : mood.color.opacity(0.18))
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                isSelected ? mood.accentColor.opacity(0.6) : mood.color.opacity(0.4),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        MoodSelectorView(
            moods: POVData.moods,
            selectedMood: .constant(POVData.moods[0])
        )
    }
}
