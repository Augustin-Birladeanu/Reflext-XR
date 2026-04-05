// SelectFromImagesView.swift

import SwiftUI
import Combine

// MARK: - Preset image model

struct PresetImage: Identifiable {
    let id: String
    let label: String
}

// MARK: - Content tab

enum ContentTab: String, CaseIterable {
    case images   = "Images"
    case stickers = "Stickers"
    case words    = "Words"
    case colors   = "Colors"

    var icon: String {
        switch self {
        case .images:   return "photo"
        case .stickers: return "star.fill"
        case .words:    return "textformat"
        case .colors:   return "paintpalette"
        }
    }
}

// MARK: - Sticker options

private struct StickerOption {
    let symbol: String
    let label: String
}

private let stickerOptions: [StickerOption] = [
    StickerOption(symbol: "heart.fill",      label: "Love"),
    StickerOption(symbol: "star.fill",       label: "Hope"),
    StickerOption(symbol: "sun.max.fill",    label: "Joy"),
    StickerOption(symbol: "moon.fill",       label: "Rest"),
    StickerOption(symbol: "leaf.fill",       label: "Growth"),
    StickerOption(symbol: "sparkles",        label: "Wonder"),
    StickerOption(symbol: "cloud.fill",      label: "Peace"),
    StickerOption(symbol: "drop.fill",       label: "Release"),
    StickerOption(symbol: "flame.fill",      label: "Passion"),
    StickerOption(symbol: "wind",            label: "Freedom"),
    StickerOption(symbol: "bird.fill",       label: "Courage"),
    StickerOption(symbol: "mountain.2.fill", label: "Strength"),
]

private let wordOptions = [
    "Hopeful","Grateful","Strong","Peaceful",
    "Loved","Brave","Growing","Healing",
    "Free","Joy","Worthy","Enough",
]

// MARK: - Category data

private let categoryImages: [String: [PresetImage]] = [
    "Emotions": [
        PresetImage(id: "emotions-sunset",  label: "Reflection"),
        PresetImage(id: "emotions-eye",     label: "Release"),
        PresetImage(id: "emotions-joy",     label: "Joy"),
        PresetImage(id: "emotions-calm",    label: "Calm"),
        PresetImage(id: "emotions-longing", label: "Longing"),
        PresetImage(id: "emotions-hope",    label: "Hope"),
    ],
    "Nature": [
        PresetImage(id: "nature-forest",    label: "Hope"),
        PresetImage(id: "nature-mountain",  label: "Strength"),
        PresetImage(id: "nature-wave",      label: "Letting Go"),
        PresetImage(id: "nature-garden",    label: "Gratitude"),
        PresetImage(id: "nature-waterfall", label: "Flow"),
        PresetImage(id: "nature-autumn",    label: "Change"),
    ],
    "Abstract": [
        PresetImage(id: "abstract-light",      label: "Joy"),
        PresetImage(id: "abstract-energy",     label: "Energy"),
        PresetImage(id: "abstract-geometric",  label: "Peace"),
        PresetImage(id: "abstract-flowing",    label: "Flow"),
        PresetImage(id: "abstract-harmony",    label: "Harmony"),
        PresetImage(id: "abstract-depth",      label: "Depth"),
    ],
    "Animals": [
        PresetImage(id: "animals-deer",       label: "Gentleness"),
        PresetImage(id: "animals-birds",      label: "Freedom"),
        PresetImage(id: "animals-butterfly",  label: "Change"),
        PresetImage(id: "animals-wolf",       label: "Resilience"),
        PresetImage(id: "animals-whale",      label: "Majesty"),
        PresetImage(id: "animals-fox",        label: "Stillness"),
    ],
    "Architecture": [
        PresetImage(id: "architecture-cottage",    label: "Safety"),
        PresetImage(id: "architecture-temple",     label: "Peace"),
        PresetImage(id: "architecture-lighthouse", label: "Guidance"),
        PresetImage(id: "architecture-archway",    label: "Journey"),
        PresetImage(id: "architecture-bridge",     label: "Crossing"),
        PresetImage(id: "architecture-window",     label: "Warmth"),
    ],
    "People": [
        PresetImage(id: "people-hands",       label: "Connection"),
        PresetImage(id: "people-meditation",  label: "Stillness"),
        PresetImage(id: "people-silhouette",  label: "Hope"),
        PresetImage(id: "people-embrace",     label: "Love"),
        PresetImage(id: "people-child",       label: "Wonder"),
        PresetImage(id: "people-elder",       label: "Wisdom"),
    ],
    "Space": [
        PresetImage(id: "space-nebula",   label: "Wonder"),
        PresetImage(id: "space-stars",    label: "Infinite"),
        PresetImage(id: "space-moon",     label: "Reflection"),
        PresetImage(id: "space-cosmic",   label: "Expansion"),
        PresetImage(id: "space-aurora",   label: "Ethereal"),
        PresetImage(id: "space-planet",   label: "Discovery"),
    ],
]

private let categoryOrder = ["Emotions", "Nature", "Abstract", "Animals", "Architecture", "People", "Space"]

// MARK: - View

struct SelectFromImagesView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory  = "Emotions"
    @State private var selectedTab: ContentTab = .images
    @State private var selectedAsset: String? = nil
    @State private var navigateToReflect = false

    // Emotional response selections
    @State private var selectedSymbol: String? = nil
    @State private var selectedWord: String?   = nil
    @State private var selectedColorName: String? = nil

    private var visibleImages: [PresetImage] {
        categoryImages[selectedCategory] ?? []
    }

    private let gridColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Header
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.blue)
                }
                Spacer()
                Menu {
                    ForEach(categoryOrder, id: \.self) { cat in
                        Button {
                            selectedCategory = cat
                            selectedAsset = nil
                        } label: {
                            HStack {
                                Text(cat)
                                if cat == selectedCategory { Image(systemName: "checkmark") }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedCategory)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            // MARK: Content area
            Group {
                if selectedTab == .images {
                    imageGridContent
                } else if let asset = selectedAsset {
                    responseContent(for: asset)
                } else {
                    noImagePrompt
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // MARK: Tab bar
            HStack(spacing: 0) {
                ForEach(ContentTab.allCases, id: \.self) { tab in
                    Button { selectedTab = tab } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 18))
                                .foregroundColor(selectedTab == tab ? .blue : Color(.tertiaryLabel))
                            Text(tab.rawValue)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(selectedTab == tab ? .blue : Color(.tertiaryLabel))
                            Circle()
                                .fill(selectedTab == tab ? Color.blue : Color.clear)
                                .frame(width: 5, height: 5)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
            }
            .background(Color(.systemBackground))
            .overlay(alignment: .top) { Divider() }

            // MARK: Action buttons
            HStack(spacing: 12) {
                ActionBarButton(title: "Add", filled: false) { }
                    .disabled(selectedAsset == nil)

                ActionBarButton(title: "Generate", filled: false) { }

                ActionBarButton(title: "Reflect", filled: true) {
                    EmotionalSession.shared.selectedSymbol    = selectedSymbol
                    EmotionalSession.shared.selectedWord      = selectedWord
                    EmotionalSession.shared.selectedColorName = selectedColorName
                    navigateToReflect = true
                }
                .disabled(selectedAsset == nil)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .overlay(alignment: .top) { Divider() }
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToReflect) {
            if let asset = selectedAsset {
                ReflectFromSelectedImageView(imageName: asset, category: selectedCategory)
            }
        }
    }

    // MARK: - Images grid

    private var imageGridContent: some View {
        VStack(spacing: 0) {
            Text("Select an image that resonates with how you are feeling")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 10)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: gridColumns, spacing: 8) {
                    ForEach(visibleImages) { preset in
                        PresetImageCell(preset: preset,
                                        isSelected: selectedAsset == preset.id)
                            .onTapGesture {
                                selectedAsset = (selectedAsset == preset.id) ? nil : preset.id
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .animation(.easeInOut(duration: 0.2), value: selectedCategory)
            }
        }
    }

    // MARK: - Emotional response content

    @ViewBuilder
    private func responseContent(for asset: String) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Selected image preview
                Image(asset)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                // Tab-specific selector
                switch selectedTab {
                case .stickers: stickersSelector
                case .words:    wordsSelector
                case .colors:   colorsSelector
                default:        EmptyView()
                }
            }
            .padding(.bottom, 16)
        }
    }

    // MARK: - Stickers selector

    private var stickersSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How does this image make you feel?")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)

            let columns = [GridItem(.flexible()), GridItem(.flexible()),
                           GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(stickerOptions, id: \.symbol) { option in
                    let isSelected = selectedSymbol == option.symbol
                    Button {
                        selectedSymbol = isSelected ? nil : option.symbol
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: option.symbol)
                                .font(.system(size: 26))
                                .foregroundColor(isSelected ? .blue : .primary)
                                .frame(width: 52, height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(isSelected
                                              ? Color.blue.opacity(0.12)
                                              : Color(.secondarySystemBackground))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                                )
                            Text(option.label)
                                .font(.system(size: 11))
                                .foregroundColor(isSelected ? .blue : .secondary)
                        }
                    }
                    .animation(.easeInOut(duration: 0.15), value: selectedSymbol)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Words selector

    private var wordsSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Which word fits your feeling right now?")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)

            let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(wordOptions, id: \.self) { word in
                    let isSelected = selectedWord == word
                    Button {
                        selectedWord = isSelected ? nil : word
                    } label: {
                        Text(word)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isSelected ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(isSelected ? Color.blue : Color(.secondarySystemBackground))
                            )
                    }
                    .animation(.easeInOut(duration: 0.15), value: selectedWord)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Colors selector

    private var colorsSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Which color represents how you feel?")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(EmotionColor.all) { ec in
                        let isSelected = selectedColorName == ec.id
                        Button {
                            selectedColorName = isSelected ? nil : ec.id
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(ec.color)
                                    .frame(width: 54, height: 54)
                                    .shadow(color: ec.color.opacity(0.4), radius: isSelected ? 8 : 3)
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .animation(.spring(response: 0.25), value: selectedColorName)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - No image prompt

    private var noImagePrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 40))
                .foregroundColor(Color(.tertiaryLabel))
            Text("Select an image from the Images tab first")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preset image cell

private struct PresetImageCell: View {
    let preset: PresetImage
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(preset.id)
                .resizable()
                .scaledToFill()
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.blue, lineWidth: 3)
                    }
                }
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
                    .background(Circle().fill(Color.white).padding(2))
                    .padding(8)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Action bar button

private struct ActionBarButton: View {
    let title: String
    let filled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(filled ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(filled ? Color.blue : Color(.secondarySystemBackground))
                )
        }
    }
}

#Preview {
    NavigationStack { SelectFromImagesView() }
}
