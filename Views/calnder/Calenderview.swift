//
//  CalendarView.swift
//  POV
//
//  Created by Feda on 10/05/2026.
//

import SwiftUI
import UIKit

struct CalendarView: View {

    @Environment(\.selectedPOVTab) private var selectedPOVTab

    @State private var calendarModel: CalendarModel

    init(months: [MemoryMonth] = MemoryMonth.sampleMonths) {
        _calendarModel = State(initialValue: CalendarModel(months: months))
    }

    var body: some View {
        ZStack {
            Color("background 1").ignoresSafeArea()

            if let selectedId = calendarModel.selectedCapsuleId,
               let selectedEntry = calendarModel.activeEntry {
                Ellipse()
                    .fill(RadialGradient(
                        colors: [selectedEntry.mood.color.opacity(0.18), .clear],
                        center: .center, startRadius: 30, endRadius: 300
                    ))
                    .frame(width: 420, height: 420)
                    .blur(radius: 90)
                    .offset(y: -330)
                    .id(selectedId)
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
                ForEach(calendarModel.recentEntries) { entry in
                    capsule(entry)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private var cardStack: some View {
        ZStack(alignment: .top) {
            ForEach(Array(calendarModel.visibleMonths.enumerated()), id: \.element.id) { index, month in
                memoryCard(month, index: index)
                    .offset(y: CGFloat(index) * cardStackStep)
                    .zIndex(Double(index))
            }
        }
        .frame(height: cardStackHeight, alignment: .top)
        .padding(.horizontal, 24)
    }

    private var cardStackStep: CGFloat {
        104
    }

    private var cardStackHeight: CGFloat {
        210 + CGFloat(max(calendarModel.visibleMonths.count - 1, 0)) * cardStackStep
    }

    private func capsule(_ entry: MemoryEntry) -> some View {
        let isSelected = calendarModel.isSelectedCapsule(entry)

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                calendarModel.selectCapsule(entry)
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.shortDate)
                    .font(.custom("Lora-Italic", size: 10))
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
        let isSelected = calendarModel.isSelectedMonth(month)

        return ZStack(alignment: .bottomLeading) {
            coverBackground(for: month, index: index)
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            LinearGradient(
                colors: [Color.black.opacity(0.4), Color.clear, Color.black.opacity(0.55)],
                startPoint: .top, endPoint: .bottom
            )

            VStack {
                HStack(alignment: .top) {
                    Text(month.month.uppercased())
                        .font(.custom("Georgia-Regular", size: 14))
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
                .stroke(Color.white.opacity(isSelected ? 0.28 : 0.12), lineWidth: 1)
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: calendarModel.selectedMonthId)
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                calendarModel.selectMonth(month)
                selectedPOVTab.wrappedValue = .archive
            }
        }
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
        let isActive = calendarModel.isSelectedMonth(month)

        return ZStack {
            if isActive {
                LinearGradient(
                    colors: [month.dominantMood.color, month.dominantMood.color.opacity(0.2)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                RadialGradient(
                    colors: [month.dominantMood.accentColor.opacity(0.48), .clear],
                    center: .topTrailing, startRadius: 12, endRadius: 220
                )
            } else {
                Color(white: 0.12)
            }

            Rectangle()
                .fill(.white.opacity(0.04))
                .frame(height: 90)
                .rotationEffect(.degrees(index.isMultiple(of: 2) ? -8 : 10))
                .offset(y: CGFloat(index % 3) * 28 - 20)
                .blur(radius: 2)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: isActive)
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

#Preview {
    CalendarView()
}
