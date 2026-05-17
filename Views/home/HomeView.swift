//
//  HomeView.swift
//  POV
//
//  Created by Feda on 12/05/2026.
//
import SwiftUI

struct HomeView: View {

    @State private var selectedMood: Mood = POVData.moods[0]

    var body: some View {
        ZStack {
            Color("background 1").ignoresSafeArea()

            VStack {
                Spacer()
                Ellipse()
                    .fill(selectedMood.color.opacity(0.35))
                    .blur(radius: 80)
                    .frame(width: 350, height: 250)
            }
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 4) {

                Text("MONDAY · MAY 12")
                    .font(.custom("Georgia-Italic", size: 16))
                    .foregroundStyle(Color("text 2"))
                    .padding(.horizontal, 24)

                Text("How do you want to feel?")
                    .font(.custom("Georgia-Italic", size: 24))
                    .foregroundStyle(Color("text 1"))
                    .padding(.horizontal, 24)

                MoodSelectorView(moods: POVData.moods, selectedMood: $selectedMood)
                    .padding(.top, 24)

                Spacer().frame(height: 16)

                Text("Explore directors lenses")
                    .font(.custom("Georgia-Bold", size: 16))
                    .foregroundStyle(Color("text 1"))
                    .padding(.horizontal, 17)
                
                Spacer().frame(height: 10)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 18) {
                        ForEach(POVData.lenses(for: selectedMood)) { director in
                            DirectorCard(director: director)
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()
            }
            .padding(.top, 60)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
    }
}

private struct DirectorCard: View {
    let director: DirectorLens

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(director.name)
                .font(.custom("Georgia-Italic", size: 18))
                .foregroundStyle(Color("text 1"))

            Text(director.nationality)
                .font(.custom("", size: 13))
                .foregroundStyle(Color("text 2"))

            Text(director.tags.joined(separator: ", "))
                .font(.custom("Lora-Italic", size: 13))
                .foregroundStyle(Color("text 2"))

                .lineLimit(3)
        }
        .padding(18)
        .frame(width: 288)
        .background(Color("cards"))
        .clipShape(RoundedRectangle(cornerRadius: 19))
    }
}


#Preview {
    HomeView()
}
