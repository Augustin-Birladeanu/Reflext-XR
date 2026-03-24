// ConceptsView.swift

import SwiftUI

struct ConceptsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navManager: NavigationManager
    @State private var selectedConcept: String? = nil
    @State private var navigateToCreate = false
    @State private var navigateToDailyCreation = false
    @State private var selectedDailyConcept: DailyCreationConcept? = nil

    private let concepts = [
        "A Safe Space",
        "Emotional Waves",
        "Resilience",
        "Journey",
        "Masks we wear",
        "Crossroads",
        "Future Self",
        "Bridges",
        "Friendship",
        "Growing Roots",
        "Letting Go",
        "Garden of peace",
        "Rising from Ashes",
        "Inner Child"
    ]

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Custom Header
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.blue)
                }
                Spacer()
                Text("Concepts")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // MARK: Hero image
                    Image("concepts-ui")
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Text("Get started by selecting from the below concepts")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)

                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(concepts, id: \.self) { concept in
                            ConceptPill(
                                title: concept,
                                isSelected: selectedConcept == concept
                            ) {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedConcept = selectedConcept == concept ? nil : concept
                                }
                            }
                        }
                    }

                    // MARK: Daily Creation
                    Button {
                        selectedDailyConcept = DailyCreationConcept.all.randomElement()
                        navigateToDailyCreation = true
                    } label: {
                        Text("Daily Creation")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.blue, lineWidth: 1.5)
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .safeAreaInset(edge: .bottom) {
                continueBar
            }
            .background(Color(.systemBackground))
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedConcept)
        .navigationBarHidden(true)
        .onChange(of: navManager.popToRoot) { _, popping in
            if popping { dismiss() }
        }
        .navigationDestination(isPresented: $navigateToCreate) {
            PromptView(concept: selectedConcept ?? "")
        }
        .navigationDestination(isPresented: $navigateToDailyCreation) {
            if let dc = selectedDailyConcept {
                PromptView(concept: dc.name, dailyConcept: dc)
            }
        }
    }

    @ViewBuilder
    private var continueBar: some View {
        if selectedConcept != nil {
            Button {
                navigateToCreate = true
            } label: {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

// MARK: - Concept Pill

struct ConceptPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void


    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .black)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 10)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(isSelected ? Color.blue : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.blue, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ConceptsView()
    }
}
