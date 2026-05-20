//
//  HomeView.swift
//  POV
//
//  Created by Feda on 12/05/2026.
//

import SwiftUI

struct HomeView: View {

    @Environment(\.selectedPOVTab) private var selectedPOVTab

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
            
            // جعلنا الـ VStack الأساسي قابل للتمرير بالكامل إذا كبرت العناصر
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 4) {

                    Text(homeModel.dateTitle)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color("text 2"))
                        .tracking(1.5)
                        .padding(.horizontal, 24)

                    Text("How do you want to feel?")
                        .font(.custom("Georgia-Italic", size: 24))
                        .foregroundStyle(Color("text 1"))
                        .padding(.horizontal, 24)

                    MoodSelectorView(moods: POVData.moods, selectedMood: $homeModel.selectedMood)
                        .padding(.top, 24)

                    Spacer().frame(height: 16)

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
                    
                    // MARK: - Insights Section (تم نقله إلى المكان الصحيح)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("A new insight is ready!")
                            .font(.custom("Lora-Italic", size: 16))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                
                                // الكارد الأول (النشط اللي فيه النص)
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("“This week you reached for slower lenses than the week before.”")
                                        .font(.custom("Georgia-Italic", size: 18))
                                        .foregroundColor(.white)
                                        .lineSpacing(4)
                                    
                                    Spacer()
                                    
                                    Text("-compared to last week")
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
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
                                
                                // الكارد الثاني (الفارغ أو التالي)
                                VStack {
                                    Spacer()
                                }
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
                                )
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    Spacer().frame(height: 40) // مساحة إضافية بالأسفل
                }
                .padding(.top, 90)
            }
        }
        .ignoresSafeArea()
        .fullScreenCover(item: $homeModel.selectedDirector) { director in
            DirectorBriefView(mood: homeModel.selectedMood, director: director) {
                homeModel.startDay()
                selectedPOVTab.wrappedValue = .record
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
