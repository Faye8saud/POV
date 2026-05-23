//
//  onBoardingView.swift
//  POV
//
//  Created by Fay  on 21/05/2026.
//

import SwiftUI



struct OnboardingView: View {

    @ObservedObject var viewModel: OnboardingViewModel

    

    var body: some View {

        ZStack {

            // Dark Base Canvas matching the screenshot

            Color.black.ignoresSafeArea()

            

            // Left-center muted plum/magenta mood aura

            GeometryReader { geometry in

                RadialGradient(

                    colors: [Color(red: 0.22, green: 0.11, blue: 0.18).opacity(0.55), Color.clear],

                    center: .init(x: 0.15, y: 0.45),

                    startRadius: 5,

                    endRadius: geometry.size.width * 0.85

                )

                .ignoresSafeArea()

            }

            

            VStack(spacing: 0) {

                // Skip button - Top Right

                HStack {

                    Spacer()

                    Button(action: {

                        viewModel.completeOnboarding()

                    }) {

                        Text("Skip")

                            .font(.system(size: 13))

                            .foregroundColor(.white.opacity(0.45))

                    }

                }

                .padding(.horizontal, 24)

                .padding(.top, 16)

                .padding(.bottom, 8)

                

                Spacer()

                

                // Content Information Frame

                VStack(alignment: .leading, spacing: 18) {

                    Text("POV is a daily cinematic practice")

                        .font(.system(size: 40, weight: .medium, design: .serif))

                        .foregroundColor(.white)

                        .lineSpacing(5)

                    

                    Text("Each day, a director shapes how you see.\nBy night, your moments become a film.\nWhat emerges in the reflection?")

                        .font(.system(size: 17))

                        .foregroundColor(.white.opacity(0.45))

                        .lineSpacing(4)

                }

                .frame(maxWidth: .infinity, alignment: .leading)

                .padding(.horizontal, 28)

                

                Spacer()

                    .frame(height: 50)

                

                // Begin Button - Bottom

                Button(action: {

                    viewModel.completeOnboarding()

                }) {

                    Text("Begin")

                        .font(.system(size: 16, weight: .bold, design: .serif))

                        .foregroundColor(.black)

                        .frame(maxWidth: .infinity)

                        .frame(height: 54)

                        .background(Color.white)

                        .cornerRadius(27)

                }

                .padding(.horizontal, 24)

                .padding(.bottom, 55)

            }

        }

    }

}



#Preview {

    OnboardingView(viewModel: OnboardingViewModel())

}
