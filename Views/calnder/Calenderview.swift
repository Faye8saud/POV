//
//  CalendarView.swift
//  POV
//
//  Created by Feda on 10/05/2026.
//

import SwiftUI
import UIKit

struct MemoryMood: Identifiable, Hashable {
    let id = UUID()
    let displayName: String
    let povMoodName: String

    var name: String {
        displayName
    }

    var color: Color {
        povMood?.color ?? .white
    }

    var accentColor: Color {
        povMood?.accentColor ?? .white
    }

    private var povMood: Mood? {
        POVData.moods.first { $0.name == povMoodName }
    }
}

struct MemoryEntry: Identifiable, Hashable {
    let id = UUID()
    let shortDate: String
    let mood: MemoryMood
    let clipCount: Int
}

struct MemoryMonth: Identifiable, Hashable {
    let id = UUID()
    let month: String
    let year: Int
    let coverImage: String
    let dominantMood: MemoryMood
    let entries: [MemoryEntry]
}

struct CalendarView: View {

    let months: [MemoryMonth]

    @State private var selectedCapsule: UUID?

    init(months: [MemoryMonth] = MemoryMonth.sampleMonths) {
        self.months = months
    }

    var body: some View {
        ZStack {
            Color("background 1")
                .ignoresSafeArea()

            // إضاءة الخلفية العلوية المتفاعلة مع الكبسولة المحددة
            if let selectedId = selectedCapsule,
               let selectedEntry = months.flatMap(\.entries).first(where: { $0.id == selectedId }) {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                selectedEntry.mood.color.opacity(0.18),
                                .clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 300
                        )
                    )
                    .frame(width: 420, height: 420)
                    .blur(radius: 90)
                    .offset(y: -330)
                    .id(selectedId) // يضمن تحديث الأنيميشن عند تغيير الكبسولة
            }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.top, 82)
                        .padding(.bottom, 22)

                    capsuleStrip
                        .padding(.bottom, 36)

                    cardStack
                }
                .padding(.bottom, 96)
            }
            .ignoresSafeArea(edges: .top)
        }
        .environment(\.layoutDirection, .leftToRight)
        .onAppear {
            selectedCapsule = months.flatMap(\.entries).first?.id
        }
    }

    private var header: some View {
        Text("Your calendar")
            .font(.custom("Georgia-Italic", size: 26))
            .foregroundColor(Color("text 1"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
    }

    private var capsuleStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(months.flatMap(\.entries)) { entry in
                    capsule(entry)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private var cardStack: some View {
        LazyVStack(spacing: -35) {
            ForEach(Array(months.enumerated()), id: \.element.id) { index, month in
                memoryCard(month, index: index)
                    .zIndex(Double(months.count - index))
            }
        }
        .padding(.horizontal, 24)
    }

    private func capsule(_ entry: MemoryEntry) -> some View {
        let isSelected = selectedCapsule == entry.id

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                selectedCapsule = entry.id
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.shortDate)
                    .font(.custom("lora-Italic", size: 10))
                    .foregroundColor(.white.opacity(0.62))

                Text(entry.mood.name)
                    .font(.custom("Georgia-Italic", size: 13))
                    .foregroundColor(.white.opacity(0.95))

                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 7, weight: .bold))

                    Text("\(entry.clipCount)")
                        .font(.custom("Georgia-Italic", size: 11))
                }
                .foregroundColor(.white.opacity(0.78))
            }
            .frame(width: 72, height: 68, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(entry.mood.color.opacity(isSelected ? 0.35 : 0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(entry.mood.accentColor.opacity(isSelected ? 0.8 : 0.2), lineWidth: 1)
            )
            .shadow(color: entry.mood.color.opacity(isSelected ? 0.25 : 0), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }

    private func memoryCard(_ month: MemoryMonth, index: Int) -> some View {
        let height = cardHeight(for: index)

        return ZStack(alignment: .bottomLeading) {
            coverBackground(for: month, index: index)
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            
            LinearGradient(
                colors: [
                    Color.black.opacity(0.4),
                    Color.clear,
                    Color.black.opacity(0.55)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack {
                HStack(alignment: .top) {
                    Text(month.month.uppercased())
                        .font(.custom("Georgia-regular", size: 14))
                        .foregroundColor(.white)
                        .tracking(2)

                    Spacer()

                    Text("\(month.year)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(month.dominantMood.name)
                        .font(.custom("Georgia-Italic", size: 18))
                        .foregroundColor(.white.opacity(0.95))

                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 7, weight: .bold))

                        Text("\(month.entries.reduce(0) { $0 + $1.clipCount })")
                            .font(.custom("Georgia-Italic", size: 12))
                    }
                    .foregroundColor(.white.opacity(0.75))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 6)
    }

    @ViewBuilder
    private func coverBackground(for month: MemoryMonth, index: Int) -> some View {
        if UIImage(named: month.coverImage) != nil {
            Image(month.coverImage)
                .resizable()
                .scaledToFill()
                .frame(height: cardHeight(for: index))
                .clipped()
        } else {
            generatedCover(for: month, index: index)
        }
    }

    private func generatedCover(for month: MemoryMonth, index: Int) -> some View {
        ZStack {
            LinearGradient(
                colors: [month.dominantMood.color, month.dominantMood.color.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    month.dominantMood.accentColor.opacity(0.48),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 12,
                endRadius: 220
            )

            Rectangle()
                .fill(.white.opacity(0.06))
                .frame(height: 90)
                .rotationEffect(.degrees(index.isMultiple(of: 2) ? -8 : 10))
                .offset(y: CGFloat(index % 3) * 28 - 20)
                .blur(radius: 2)
        }
    }

    private func cardHeight(for index: Int) -> CGFloat {
        switch index % 4 {
        case 0: return 210
        case 1: return 200
        case 2: return 205
        default: return 215
        }
    }
}


// MARK: - تحديث البيانات التجريبية بالمودز الخمسة المقتبسة من ملف الـ JSON
private extension MemoryMood {
    static let tender = MemoryMood(displayName: "Tender", povMoodName: "Tender")
    static let restless = MemoryMood(displayName: "Restless", povMoodName: "Restless")
    static let wandering = MemoryMood(displayName: "Wandering", povMoodName: "Wandering")
    static let charged = MemoryMood(displayName: "Charged", povMoodName: "Charged")
    static let playful = MemoryMood(displayName: "Playful", povMoodName: "Playful")
}

private extension MemoryMonth {
    static let sampleMonths: [MemoryMonth] = [
        MemoryMonth(month: "Aug", year: 2026, coverImage: "calendar-august", dominantMood: .tender, entries: [
            MemoryEntry(shortDate: "AUG 5", mood: .tender, clipCount: 8),
            MemoryEntry(shortDate: "AUG 20", mood: .playful, clipCount: 4)
        ]),
        MemoryMonth(month: "Apr", year: 2026, coverImage: "calendar-april", dominantMood: .restless, entries: [
            MemoryEntry(shortDate: "APR 30", mood: .restless, clipCount: 5),
            MemoryEntry(shortDate: "APR 5", mood: .wandering, clipCount: 3)
        ]),
        MemoryMonth(month: "May", year: 2026, coverImage: "calendar-may", dominantMood: .charged, entries: [
            MemoryEntry(shortDate: "MAY 1", mood: .charged, clipCount: 12)
        ]),
        MemoryMonth(month: "Jun", year: 2026, coverImage: "calendar-june", dominantMood: .playful, entries: [
            MemoryEntry(shortDate: "JUN 12", mood: .playful, clipCount: 5)
        ]),
        MemoryMonth(month: "Dec", year: 2026, coverImage: "calendar-december", dominantMood: .wandering, entries: [
            MemoryEntry(shortDate: "DEC 12", mood: .wandering, clipCount: 9)
        ])
    ]
}

#Preview {
    CalendarView()
}
