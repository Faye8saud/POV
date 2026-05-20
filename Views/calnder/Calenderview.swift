//
//  CalendarView.swift
//  POV
//
//  Created by Feda on 10/05/2026.
//
import SwiftUI
import SwiftData

// MARK: - CalendarView
// Reads DayEntry from SwiftData and groups them into months for the card stack.

struct CalendarView: View {

    @Query(sort: \DayEntry.date, order: .reverse) private var entries: [DayEntry]

    // Months with entries
    private var recordedMonths: [MonthGroup] {
        MonthGroup.build(from: entries)
    }

    // Full deck: current + next 5 months on top, then past recorded months below
    private var allMonths: [MonthGroup] {
        let recorded = recordedMonths
        let recordedKeys = Set(recorded.map { "\($0.monthName)-\($0.year)" })

        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"

        // Current month + next 5 (6 total), recorded or placeholder
        var upcomingAndCurrent: [MonthGroup] = []
        for offset in 0..<6 {
            guard let date = calendar.date(byAdding: .month, value: offset, to: Date()) else { continue }
            let name = formatter.string(from: date)
            let year = calendar.component(.year, from: date)
            let key = "\(name)-\(year)"
            if let existing = recorded.first(where: { "\($0.monthName)-\($0.year)" == key }) {
                upcomingAndCurrent.append(existing)
            } else {
                upcomingAndCurrent.append(MonthGroup(monthName: name, year: year, entries: []))
            }
        }

        // Past recorded months that aren't in the upcoming window
        let upcomingKeys = Set(upcomingAndCurrent.map { "\($0.monthName)-\($0.year)" })
        let pastRecorded = recorded.filter { !upcomingKeys.contains("\($0.monthName)-\($0.year)") }

        // Current month first, then future months, then past recorded at the bottom
        return upcomingAndCurrent + pastRecorded
    }

    var body: some View {
        ZStack {
            Color("background 1").ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.top, 82)
                        .padding(.bottom, 22)

                    if allMonths.isEmpty {
                        emptyState
                    } else {
                        cardStack
                    }
                }
                .padding(.bottom, 120) // clears persistent tab bar
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var header: some View {
        Text("Your calendar")
            .font(.custom("Georgia-Italic", size: 26))
            .foregroundColor(Color("text 1"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "film")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Color("text 2").opacity(0.35))
            Text("No videos yet")
                .font(.custom("Georgia-Italic", size: 18))
                .foregroundStyle(Color("text 2").opacity(0.65))
            Text("Finish your first vlog to see it here.")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Color("text 2").opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
        .padding(.horizontal, 40)
    }

    // MARK: - Card Stack

    private var cardStack: some View {
        ZStack(alignment: .top) {
            ForEach(Array(allMonths.enumerated()), id: \.element.id) { index, month in
                Group {
                    if month.entries.isEmpty {
                        // Empty/upcoming month — gray, not tappable
                        monthCard(month, index: index)
                    } else {
                        // Recorded month — tappable, navigates to archive
                        NavigationLink(destination: ArchiveView(month: month)) {
                            monthCard(month, index: index)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .offset(y: CGFloat(index) * 104)
                .zIndex(Double(index))
            }
        }
        .frame(height: cardStackHeight, alignment: .top)
        .padding(.horizontal, 24)
    }

    private var cardStackHeight: CGFloat {
        210 + CGFloat(max(allMonths.count - 1, 0)) * 104
    }

    // MARK: - Month Card

    private func monthCard(_ month: MonthGroup, index: Int) -> some View {
        let height = cardHeight(for: index)
        let dominantMood = month.dominantMood

        return ZStack(alignment: .bottomLeading) {
            // Background — dominant mood color gradient
            ZStack {
                if month.entries.isEmpty {
                    // Empty month — flat gray
                    Color(white: 0.13)
                } else if let mood = dominantMood {
                    LinearGradient(
                        colors: [mood.color, mood.color.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    RadialGradient(
                        colors: [mood.accentColor.opacity(0.45), .clear],
                        center: .topTrailing,
                        startRadius: 10,
                        endRadius: 220
                    )
                } else {
                    Color(white: 0.13)
                }

                // Subtle texture stripe
                Rectangle()
                    .fill(.white.opacity(month.entries.isEmpty ? 0.02 : 0.04))
                    .frame(height: 90)
                    .rotationEffect(.degrees(index.isMultiple(of: 2) ? -8 : 10))
                    .offset(y: CGFloat(index % 3) * 28 - 20)
                    .blur(radius: 2)
            }
            .frame(height: height)
            .frame(maxWidth: .infinity)

            // Gradient overlay for text legibility
            LinearGradient(
                colors: [Color.black.opacity(0.35), Color.clear, Color.black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Card content
            VStack {
                HStack(alignment: .top) {
                    Text(month.monthName.uppercased())
                        .font(.custom("Georgia-Italic", size: 14))
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
                    if month.entries.isEmpty {
                        Text("Nothing yet")
                            .font(.custom("Georgia-Italic", size: 16))
                            .foregroundColor(.white.opacity(0.25))
                    } else if let mood = dominantMood {
                        Text(mood.name)
                            .font(.custom("Georgia-Italic", size: 18))
                            .foregroundColor(.white.opacity(0.95))
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 7, weight: .bold))
                            Text("\(month.entries.count) \(month.entries.count == 1 ? "day" : "days")")
                                .font(.custom("Georgia-Italic", size: 12))
                        }
                        .foregroundColor(.white.opacity(0.75))
                    }
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
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 6)
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

// MARK: - MonthGroup
// Groups DayEntry records by calendar month for display in CalendarView.

struct MonthGroup: Identifiable, Hashable {
    let id: UUID = UUID()
    let monthName: String   // e.g. "May"
    let year: Int
    let entries: [DayEntry]

    // The mood that appears most in this month's entries
    var dominantMood: Mood? {
        let counts = entries.reduce(into: [String: Int]()) { $0[$1.moodName, default: 0] += 1 }
        guard let topName = counts.max(by: { $0.value < $1.value })?.key else { return nil }
        return POVData.moods.first { $0.name == topName }
    }

    static func build(from entries: [DayEntry]) -> [MonthGroup] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let calendar = Calendar.current

        // Key: "May-2026"
        var grouped: [(key: String, monthName: String, year: Int, entries: [DayEntry])] = []
        var seen: [String: Int] = [:]

        for entry in entries {
            let name = formatter.string(from: entry.date)
            let year = calendar.component(.year, from: entry.date)
            let key = "\(name)-\(year)"
            if let idx = seen[key] {
                grouped[idx].entries.append(entry)
            } else {
                seen[key] = grouped.count
                grouped.append((key: key, monthName: name, year: year, entries: [entry]))
            }
        }

        return grouped.map { MonthGroup(monthName: $0.monthName, year: $0.year, entries: $0.entries) }
    }

    // Hashable / Equatable by id
    static func == (lhs: MonthGroup, rhs: MonthGroup) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

#Preview {
    NavigationStack {
        CalendarView()
    }
    .modelContainer(for: [DayEntry.self, RecordedClipModel.self, RecordingSessionModel.self], inMemory: true)
}
