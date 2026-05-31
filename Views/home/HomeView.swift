//
//  HomeView.swift
//  POV
//
//  Created by Feda on 12/05/2026.
//
import SwiftUI

struct HomeView: View {

    @Environment(\.selectedPOVTab) private var selectedTab
    @Environment(\.selectedPOVTab) private var selectedPOVTab
    @Environment(\.pendingLens) private var pendingLens
    
    @State private var homeModel = HomeModel()

    var body: some View {
        ZStack {
            Color("background 1").ignoresSafeArea()

            VStack {
                Ellipse()
                    .fill(homeModel.moodGlowColor)
                    .blur(radius: 80)
                    .frame(width: 350, height: 250)
                    .padding(.top, 400)
            }
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 4) {

                    VStack(alignment: .leading, spacing: 2) {
                        Text(homeModel.dateTitle)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color("text 2"))
                            .tracking(1.5)
                        Text("How do you want today to feel?")
                            .font(.custom("Georgia-Italic", size: 20))
                            .foregroundStyle(Color("text 1"))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)

                    MoodSelectorView(moods: POVData.moods, selectedMood: $homeModel.selectedMood)
                        .padding(.top, 10)

                    Spacer().frame(height: 20)

                    Text("Explore directors lenses")
                        .font(.custom("Georgia-Bold", size: 16))
                        .foregroundStyle(Color("text 1"))
                        .padding(.horizontal, 17)

                    Spacer().frame(height: 10)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 18) {
                            ForEach(homeModel.directorsForSelectedMood) { director in
                                Button {
                                    homeModel.selectDirector(director)
                                } label: {
                                    DirectorCard(director: director)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer().frame(height: 24)

                    Rectangle()
                        .frame(maxWidth: .infinity)
                        .frame(height: 0.5)
                        .foregroundStyle(Color.white.opacity(0.15))
                        .padding(.horizontal, 24)

                    Spacer().frame(height: 16)

                    // MARK: - Insights Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your generated insights will appear here!")
                            .font(.custom("Georgia-Italic", size: 16))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 12) {
                           /*       Text("\u{201C}This week you reached for slower lenses than the week before.\u{201D}")
                                        .font(.custom("Georgia-Italic", size: 18))
                                        .foregroundColor(.white)
                                        .lineSpacing(4)
*/
                                    Spacer()

                                /*    Text("-compared to last week")
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
                                 */
                                }
                                .padding(20)
                                .frame(width: 165, height: 250, alignment: .topLeading)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )

                             /*   VStack { Spacer() }
                                    .frame(width: 165, height: 250)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.02)]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )  */
                            }
                            .padding(.horizontal, 24)
                            
                        }
                    }

                    Spacer().frame(height: 120)
                }
            }
            .ignoresSafeArea()
            // MARK: - Updated fullScreenCover
            .fullScreenCover(isPresented: Binding(
                get: { homeModel.pendingBrief != nil },
                set: { if !$0 { homeModel.pendingBrief = nil } }
            )) {
                if let brief = homeModel.pendingBrief {
                    DirectorBriefView(mood: brief.mood, director: brief.director) {
                        pendingLens.wrappedValue = (mood: brief.mood, lens: brief.director)
                        selectedPOVTab.wrappedValue = .record
                    }
                }
            }
            .task {
                homeModel.refreshDate()
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(60))
                    homeModel.refreshDate()
                }
            }
        }
    }
}

// MARK: - Director Card
private struct DirectorCard: View {
    let director: DirectorLens

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(director.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 165, height: 130)
                .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(director.name)
                    .font(.custom("Georgia-Bold", size: 16))
                    .foregroundStyle(Color("text 1"))
                    .lineLimit(1)

                Text(director.nationality)
                    .font(.system(size: 11))
                    .foregroundStyle(Color("text 2"))
                    .lineLimit(1)

                Text(director.styleDescription)
                    .font(.system(size: 12))
                    .foregroundStyle(Color("text 2"))
                    .lineLimit(3)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 14)
        }
        .frame(width: 165, height: 250, alignment: .top)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.12), Color.white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }
}

#Preview {
    HomeView()
}

