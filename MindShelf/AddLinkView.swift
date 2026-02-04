import SwiftUI
import SwiftData

struct AddLinkView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \LinkItem.createdDate, order: .reverse) private var allLinks: [LinkItem]
    
    @State private var url: String = ""
    @State private var title: String = ""
    @State private var selectedCategory: String = LinkCategory.other.rawValue // Default to 'Other'
    @State private var showCategoryPicker = false
    @State private var metadataTask: Task<Void, Never>?
    @State private var duplicateLink: LinkItem?
    @State private var showDuplicateAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Inputs
                    VStack(alignment: .leading, spacing: 16) {
                        customField(label: "Link URL", placeholder: "https://example.com", text: $url, icon: "link")
                        customField(label: "Title", placeholder: "Enter title", text: $title, icon: "pencil")
                    }
                    .padding(.top)
                    
                    // Auto Category (minimal + change)
                    HStack(spacing: 8) {
                        Text("Category")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Text("Auto: \(selectedCategory)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                            
                            Button("Change") {
                                showCategoryPicker = true
                            }
                            .font(.caption)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("New Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let existing = findDuplicateLink() {
                            duplicateLink = existing
                            showDuplicateAlert = true
                        } else {
                            saveLink()
                            dismiss()
                        }
                    }
                    .fontWeight(.bold)
                    .disabled(url.isEmpty)
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .tint(.primary)
        .onChange(of: url) { _, newValue in
            scheduleMetadataFetch(for: newValue)
        }
        .confirmationDialog("Select Category", isPresented: $showCategoryPicker) {
            ForEach(LinkCategory.allCases, id: \.self) { category in
                Button(category.rawValue) {
                    selectedCategory = category.rawValue
                }
            }
        }
        .alert("This link is already in your Mind Shelf!", isPresented: $showDuplicateAlert) {
            Button("View") {
                openDuplicateLink()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(duplicateLink?.title ?? "")
        }
    }
    
    // Extracted ViewBuilder for inputs
    @ViewBuilder
    private func customField(label: String, placeholder: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.caption).fontWeight(.bold).foregroundStyle(.secondary)
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                TextField(placeholder, text: text)
                    .textInputAutocapitalization(.never)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    private func saveLink() {
        // English comments as per your request
        let newLink = LinkItem(url: url, title: title.isEmpty ? url : title, category: selectedCategory)
        modelContext.insert(newLink)
        fetchAndUpdateMetadata(for: newLink)
        WidgetDataStore.upsert(link: newLink)
        NotificationCenter.default.post(name: .linkSaved, object: nil)
    }
    
    private func scheduleMetadataFetch(for urlString: String) {
        metadataTask?.cancel()
        metadataTask = Task { @MainActor in
            let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard trimmed == url.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            guard let url = URL(string: trimmed) else { return }
            
            let metadata = await LinkMetadataService.shared.fetchMetadata(for: url)
            if title.isEmpty && !LinkMetadataService.shared.isPlaceholderTitle(metadata.title, for: url) {
                title = metadata.title
            }
            if let suggested = metadata.suggestedCategory {
                selectedCategory = suggested.rawValue
            } else {
                selectedCategory = LinkCategory.other.rawValue
            }
        }
    }
    
    private func fetchAndUpdateMetadata(for link: LinkItem) {
        guard let url = URL(string: link.url) else { return }
        
        Task { @MainActor in
            let metadata = await LinkMetadataService.shared.fetchMetadata(for: url)
            if LinkMetadataService.shared.isPlaceholderTitle(link.title, for: url),
               !LinkMetadataService.shared.isPlaceholderTitle(metadata.title, for: url) {
                link.title = metadata.title
            }
            if let suggested = metadata.suggestedCategory {
                link.category = suggested.rawValue
            }
            if link.durationText == nil {
                link.durationText = await LinkMetadataService.shared.fetchDurationText(for: url)
            }
            if link.thumbnailURL == nil {
                link.thumbnailURL = LinkMetadataService.shared.thumbnailURL(for: url)
            }
            if link.readingTimeMinutes == nil {
                link.readingTimeMinutes = await LinkMetadataService.shared.fetchReadingTimeMinutes(for: url)
            }
            WidgetDataStore.upsert(link: link)
        }
    }

    private func findDuplicateLink() -> LinkItem? {
        let normalized = normalizedURLString(url)
        guard !normalized.isEmpty else { return nil }
        return allLinks.first { normalizedURLString($0.url) == normalized }
    }
    
    private func normalizedURLString(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else { return trimmed.lowercased() }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.fragment = nil
        let normalized = components?.url?.absoluteString ?? trimmed
        return normalized.lowercased()
    }
    
    private func openDuplicateLink() {
        guard let link = duplicateLink else { return }
        NotificationCenter.default.post(name: .openBookmarkFromNotification, object: nil, userInfo: [
            "bookmarkID": link.id.uuidString,
            "url": link.url
        ])
        dismiss()
    }
}
