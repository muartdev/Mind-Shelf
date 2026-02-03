import SwiftUI
import SwiftData

struct AddLinkView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var url: String = ""
    @State private var title: String = ""
    @State private var selectedCategory: String = LinkCategory.other.rawValue // Default to 'Other'
    @State private var showCategoryPicker = false
    @State private var metadataTask: Task<Void, Never>?
    
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
                        saveLink()
                        dismiss()
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
        }
    }
}
