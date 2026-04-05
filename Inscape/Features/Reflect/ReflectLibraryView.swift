// Features/Reflect/ReflectLibraryView.swift

import SwiftUI

// MARK: - Library (list of past entries)

private enum LibraryTab { case reflections, images }

struct ReflectLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = JournalStore.shared
    @StateObject private var galleryVM = GalleryViewModel()

    @State private var selectedTab: LibraryTab = .reflections
    @State private var selectedEntry: JournalEntry? = nil

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    /// Entries grouped by calendar day, newest day first.
    private var groupedEntries: [(date: Date, entries: [JournalEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: store.entries) { entry in
            calendar.startOfDay(for: entry.date)
        }
        return grouped
            .map { (date: $0.key, entries: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.date > $1.date }
    }

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
                Text("Reflect")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            // MARK: Tab Picker
            Picker("", selection: $selectedTab) {
                Text("Reflections").tag(LibraryTab.reflections)
                Text("Images").tag(LibraryTab.images)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            Divider()

            // MARK: Content
            if selectedTab == .reflections {
                reflectionsTab
            } else {
                imagesTab
            }
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .navigationDestination(item: $selectedEntry) { entry in
            ReflectEntryDetailView(entry: entry)
        }
        .sheet(item: $galleryVM.selectedImage) { image in
            ImageDetailView(image: image) {
                galleryVM.confirmDelete(image)
            }
        }
        .confirmationDialog(
            "Delete Image",
            isPresented: $galleryVM.showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task { await galleryVM.deleteImage() }
            }
            Button("Cancel", role: .cancel) { galleryVM.cancelDelete() }
        } message: {
            Text("This image will be permanently deleted.")
        }
        .task(id: selectedTab) {
            if selectedTab == .images && galleryVM.images.isEmpty {
                await galleryVM.loadImages()
            }
        }
    }

    // MARK: - Reflections Tab

    private var reflectionsTab: some View {
        Group {
            if store.entries.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary)
                    Text("No reflections yet")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("After creating an image, answer a reflection\nquestion to save your first entry.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(groupedEntries, id: \.date) { group in
                            // Date header
                            Text(dateFormatter.string(from: group.date))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.top, 24)
                                .padding(.bottom, 8)

                            // Timeline entries for this day
                            ForEach(Array(group.entries.enumerated()), id: \.element.id) { index, entry in
                                TimelineEntryRow(
                                    entry: entry,
                                    timeFormatter: timeFormatter,
                                    isLast: index == group.entries.count - 1
                                )
                                .onTapGesture { selectedEntry = entry }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    // MARK: - Images Tab

    private var imagesTab: some View {
        Group {
            if galleryVM.isLoading && galleryVM.images.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.4)
                    Text("Loading images…")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else if galleryVM.images.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary)
                    Text("No images yet")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("Images you generate will appear here.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(galleryVM.images) { image in
                            GalleryCell(image: image)
                                .onTapGesture { galleryVM.selectedImage = image }
                                .task { await galleryVM.loadMoreIfNeeded(currentItem: image) }
                        }
                    }
                    if galleryVM.isLoadingMore {
                        ProgressView().padding(.vertical, 20)
                    }
                }
            }
        }
    }
}

// MARK: - Timeline Entry Row

private struct TimelineEntryRow: View {
    let entry: JournalEntry
    let timeFormatter: DateFormatter
    let isLast: Bool

    private let dotSize: CGFloat = 10
    private let lineWidth: CGFloat = 2
    private let leftPad: CGFloat = 20

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Timeline track
            ZStack(alignment: .top) {
                // Vertical line below dot
                if !isLast {
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(width: lineWidth)
                        .padding(.top, dotSize)
                        .frame(maxHeight: .infinity)
                }
                // Dot
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: dotSize, height: dotSize)
                    .padding(.top, 4)
            }
            .frame(width: leftPad)

            // Card
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 10) {
                    // Thumbnail
                    AsyncImage(url: URL(string: entry.imageURL)) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        case .failure:
                            Color(.secondarySystemBackground)
                                .overlay(Image(systemName: "photo").foregroundColor(.secondary))
                        default:
                            Color(.secondarySystemBackground).overlay(ProgressView())
                        }
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.question)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)

                        if !entry.reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(entry.reflectionText)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        Text(timeFormatter.string(from: entry.date))
                            .font(.system(size: 11))
                            .foregroundColor(Color(.tertiaryLabel))

                        // Emotional response badges
                        if entry.selectedSymbol != nil || entry.selectedWord != nil || entry.selectedColorName != nil {
                            HStack(spacing: 6) {
                                if let symbol = entry.selectedSymbol {
                                    Image(systemName: symbol)
                                        .font(.system(size: 11))
                                        .foregroundColor(.blue)
                                }
                                if let word = entry.selectedWord {
                                    Text(word)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                                if let colorName = entry.selectedColorName,
                                   let color = EmotionColor.color(for: colorName) {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 12, height: 12)
                                }
                            }
                        }
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(.tertiaryLabel))
                        .padding(.top, 2)
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.leading, 12)
            .padding(.bottom, isLast ? 0 : 12)
        }
    }
}

// MARK: - Entry Detail

struct ReflectEntryDetailView: View {
    let entry: JournalEntry

    @Environment(\.dismiss) private var dismiss
    @State private var editedText: String
    @State private var saved = false
    @FocusState private var inputFocused: Bool

    private let store = JournalStore.shared

    init(entry: JournalEntry) {
        self.entry = entry
        _editedText = State(initialValue: entry.reflectionText)
    }

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
                Text("Entry")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Button {
                    saveEdit()
                } label: {
                    Text(saved ? "Saved" : "Save")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(saved ? .secondary : .blue)
                }
                .disabled(saved || editedText == entry.reflectionText)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Full-size image
                    AsyncImage(url: URL(string: entry.imageURL)) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFit()
                        case .failure:
                            Color(.secondarySystemBackground)
                                .frame(height: 300)
                                .overlay(Image(systemName: "photo").font(.system(size: 40)).foregroundColor(.secondary))
                        default:
                            Color(.secondarySystemBackground)
                                .frame(height: 300)
                                .overlay(ProgressView())
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Question
                    Text(entry.question)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 4)

                    Text(entry.concept)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 16)

                    Divider()
                        .padding(.horizontal, 16)

                    // Editable reflection
                    TextEditor(text: $editedText)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .frame(minHeight: 180)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .focused($inputFocused)
                        .onChange(of: editedText) { saved = false }

                    Spacer(minLength: 32)
                }
            }
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { inputFocused = false }
            }
        }
    }

    private func saveEdit() {
        var updated = entry
        updated.reflectionText = editedText
        store.update(updated)
        saved = true
        inputFocused = false
    }
}

#Preview {
    NavigationStack {
        ReflectLibraryView()
    }
}
