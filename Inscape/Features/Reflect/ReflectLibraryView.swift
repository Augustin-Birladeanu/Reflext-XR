// Features/Reflect/ReflectLibraryView.swift

import SwiftUI

// MARK: - Library (list of past entries)

struct ReflectLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = JournalStore.shared

    @State private var selectedEntry: JournalEntry? = nil

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

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

            Divider()

            // MARK: Content
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
                    LazyVStack(spacing: 12) {
                        ForEach(store.entries) { entry in
                            EntryRowView(entry: entry, dateFormatter: dateFormatter)
                                .onTapGesture { selectedEntry = entry }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .navigationDestination(item: $selectedEntry) { entry in
            ReflectEntryDetailView(entry: entry)
        }
    }
}

// MARK: - Entry Row

private struct EntryRowView: View {
    let entry: JournalEntry
    let dateFormatter: DateFormatter

    var body: some View {
        HStack(spacing: 12) {
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
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.question)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                if !entry.reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(entry.reflectionText)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Text(dateFormatter.string(from: entry.date))
                    .font(.system(size: 12))
                    .foregroundColor(Color(.tertiaryLabel))
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator), lineWidth: 1)
        )
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
