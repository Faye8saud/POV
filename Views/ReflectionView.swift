//
//  ReflectionView.swift
//  POV
//
//  Created by Fay  on 18/05/2026.
//
import SwiftUI
import SwiftData

// MARK: - Reflection View
struct ReflectionView: View {

    let lens: DirectorLens
    let date: Date
    let mergedVideoURL: URL?
    let moodName: String
    let onSaveComplete: () -> Void
    
    // Use both — cloudContext for CloudKit, modelContext as guaranteed fallback
    @Environment(\.cloudModelContext) private var cloudContext
    @Environment(\.modelContext) private var modelContext
    @Environment(\.selectedPOVTab) private var selectedTab
    @Environment(\.dismiss) private var dismiss

    @State private var step: Int = 1
    @State private var answer1: String = ""
    @State private var answer2: String = ""
    @State private var isSaving = false

    private var currentQuestion: String {
        step == 1 ? lens.question1 : lens.question2
    }

    var body: some View {
        ZStack {
            Color(white: 0.06).ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: Nav
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(.white.opacity(0.1)))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("\(step) of 2")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                        .tracking(1.5)

                    Spacer()

                    Button { handleSkip() } label: {
                        Text("Skip")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                Spacer()

                Text("In the lens of \(lens.name)")
                    .font(.custom("Georgia-Italic", size: 14))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.bottom, 28)

                Text(currentQuestion)
                    .font(.custom("Georgia-Italic", size: 22))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 32)
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal:   .opacity.combined(with: .move(edge: .leading))
                    ))
                    .animation(.spring(response: 0.4, dampingFraction: 0.82), value: step)

                if step == 1 {
                    YesNoSelector(selection: $answer1)
                        .padding(.horizontal, 24)
                        .padding(.top, 36)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal:   .opacity.combined(with: .move(edge: .leading))
                        ))
                } else {
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                            )

                        if answer2.isEmpty {
                            Text("Write your thoughts…")
                                .font(.system(size: 15, weight: .light))
                                .foregroundStyle(.white.opacity(0.25))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                        }

                        TextEditor(text: $answer2)
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(.white)
                            .scrollContentBackground(.hidden)
                            .background(.clear)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                    }
                    .frame(height: 160)
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal:   .opacity.combined(with: .move(edge: .leading))
                    ))
                }

                Spacer()

                Button { handleContinue() } label: {
                    Group {
                        if isSaving {
                            ProgressView().tint(Color(white: 0.06))
                        } else {
                            Text(step == 1 ? "Next" : "Save & finish")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color(white: 0.06))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white)
                    .cornerRadius(27)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
                .disabled(isSaving)
                .opacity(step == 1 && answer1.isEmpty ? 0.4 : 1)
                .disabled(step == 1 && answer1.isEmpty)
            }
        }
        .navigationBarHidden(true)
        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: step)
        .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .navigationBarHidden(true)
            .animation(.spring(response: 0.4, dampingFraction: 0.82), value: step)
    }

    // MARK: - Actions

    private func handleContinue() {
        if step == 1 {
            withAnimation { step = 2 }
        } else {
            saveAndFinish()
        }
    }

    private func handleSkip() {
        if step == 1 {
            answer1 = ""
            withAnimation { step = 2 }
        } else {
            answer2 = ""
            saveAndFinish()
        }
    }

    private func saveAndFinish() {
        guard !isSaving else { return }
        
        // Dismiss keyboard first, then save after a short delay so it doesn't lag
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        isSaving = true

        let entry = DayEntry(
            date: date,
            moodName: moodName,
            directorName: lens.name,
            directorStyle: lens.styleDescription,
            reflectionAnswer1: answer1,
            reflectionAnswer2: answer2,
            mergedVideoURL: mergedVideoURL?.lastPathComponent ?? ""
        )

        let context = cloudContext ?? modelContext
        context.insert(entry)
        try? context.save()

        // Small delay so keyboard finishes animating down before navigation fires
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onSaveComplete()
        }
    }
}

// MARK: - Yes / No Selector
private struct YesNoSelector: View {

    @Binding var selection: String

    var body: some View {
        HStack(spacing: 16) {
            ForEach(["Yes", "No"], id: \.self) { option in
                let isSelected = selection == option

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selection = option
                    }
                } label: {
                    Text(option)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(isSelected ? Color(white: 0.06) : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(isSelected ? Color.white : Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(
                                            isSelected ? Color.clear : Color.white.opacity(0.1),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .scaleEffect(isSelected ? 1.03 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
