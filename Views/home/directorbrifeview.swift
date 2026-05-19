//
//  directorbrifeview.swift
//  POV
//
//  Created by Feda  on 19/05/2026.
//

import SwiftUI

struct DirectorBriefView: View {
    let mood: Mood
    let director: DirectorLens
    var startAction: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color("background 1").ignoresSafeArea()

            Ellipse()
                .fill(mood.color.opacity(0.28))
                .frame(width: 360, height: 280)
                .blur(radius: 90)
                .offset(y: -260)

            VStack(spacing: 0) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.86))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 54)

                Spacer(minLength: 42)

                Text("Your Intention For The Day")
                    .font(.custom("Georgia-Italic", size: 17))
                    .foregroundStyle(Color("text 2"))
                    .multilineTextAlignment(.center)

                Spacer(minLength: 62)

                Text("\u{201D}\(director.brief)\u{201D}")
                    .font(.custom("Georgia-Italic", size: 34))
                    .foregroundStyle(Color("text 1"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(10)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 42)

                Spacer(minLength: 44)

                Text("-In the lens of \(director.name.lowercased())")
                    .font(.custom("Georgia-Italic", size: 16))
                    .foregroundStyle(Color("text 2"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Spacer()

                Button {
                    startAction()
                    dismiss()
                } label: {
                    Text("Start the day")
                        .font(.custom("Georgia-Bold", size: 18))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 44)
                .padding(.bottom, 52)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    DirectorBriefView(
        mood: POVData.moods[0],
        director: POVData.lenses(for: POVData.moods[0])[0]
    )
}
