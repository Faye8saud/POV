//
//  POVTabBar.swift
//  POV
//
//  Created by Fay  on 11/05/2026.
//
import SwiftUI

// MARK: - Tab Destinations
enum POVTab {
    case home, record, archive
}

// MARK: - Glassy Tab Bar
struct POVTabBar: View {

    @Binding var selectedTab: POVTab
    var isRecording: Bool

    var body: some View {
        HStack(spacing: 0) {

            // ── Home ───────────────────────────────────────────────────
            TabBarItem(
                icon: "house",
                iconFilled: "house.fill",
                tab: .home,
                selectedTab: $selectedTab
            )

            Spacer()

            // ── Record (camera icon, elevated pill) ────────────────────
            RecordCenterButton(isRecording: isRecording, selectedTab: $selectedTab)

            Spacer()

            // ── Archive ────────────────────────────────────────────────
            TabBarItem(
                icon: "calendar",
                iconFilled: "calendar.badge.clock",
                tab: .archive,
                selectedTab: $selectedTab
            )
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 12)
        .background(
            // Layered glass: blur material + subtle gradient sheen + border
            ZStack {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(.ultraThinMaterial)

                // Soft inner highlight along the top edge
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.10), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )

                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .strokeBorder(.white.opacity(0.14), lineWidth: 1)
            }
        )
        .shadow(color: .black.opacity(0.45), radius: 22, y: 8)
        .padding(.horizontal, 20)
    }
}

// MARK: - Side Tab Item
private struct TabBarItem: View {

    let icon:       String
    let iconFilled: String
    let tab:        POVTab
    @Binding var selectedTab: POVTab

    private var isSelected: Bool { selectedTab == tab }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            Image(systemName: isSelected ? iconFilled : icon)
                .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.45))
                .scaleEffect(isSelected ? 1.12 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
                .frame(width: 44, height: 36)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Center Camera Button
/// A raised, darker pill containing a camera icon — distinct from the shutter button.
private struct RecordCenterButton: View {

    var isRecording: Bool
    @Binding var selectedTab: POVTab

    private var isSelected: Bool { selectedTab == .record }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = .record
            }
        } label: {
            ZStack {
                // Elevated background pill
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.black.opacity(0.55))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(.white.opacity(isSelected ? 0.35 : 0.18), lineWidth: 1)
                    )
                    .frame(width: 62, height: 44)
                    .shadow(color: .black.opacity(0.4), radius: 8, y: 3)

                // Camera icon — pulses red while recording
                Image(systemName: isRecording ? "video.fill" : "video")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isRecording ? Color.red : .white.opacity(isSelected ? 1 : 0.7))
                    .scaleEffect(isRecording ? 1.08 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                               value: isRecording)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        // Simulate camera-like dark bg
        Rectangle()
            .fill(Color(white: 0.1))
            .ignoresSafeArea()

        VStack {
            Spacer()
            POVTabBar(selectedTab: .constant(.record), isRecording: false)
                .padding(.bottom, 30)
        }
    }
}
