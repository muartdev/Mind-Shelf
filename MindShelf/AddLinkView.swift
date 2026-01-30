import SwiftUI
import SwiftData
import LinkPresentation

struct AddLinkView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var url: String = ""
    @State private var title: String = ""
    @State private var selectedCategory: LinkCategory = .other
    @State private var isLoadingMetadata = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Link Details") {
                    HStack {
                        TextField("URL", text: $url)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .disabled(isLoadingMetadata)
                        
                        if isLoadingMetadata {
                            ProgressView()
                        } else if !url.isEmpty {
                            Button {
                                fetchMetadata()
                            } label: {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    
                    TextField("Title", text: $title)
                        .disabled(isLoadingMetadata)
                }
                
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(LinkCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Add Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveLink()
                    }
                    .disabled(url.isEmpty || title.isEmpty)
                }
            }
        }
    }
    
    private func saveLink() {
        let newLink = LinkItem(
            url: url,
            title: title,
            category: selectedCategory.rawValue
        )
        modelContext.insert(newLink)
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        dismiss()
    }
    
    private func fetchMetadata() {
        guard let linkURL = URL(string: url) else { return }
        
        isLoadingMetadata = true
        
        Task {
            do {
                let metadata = try await LinkMetadataService.shared.fetchMetadata(for: linkURL)
                await MainActor.run {
                    self.title = metadata.title
                    self.isLoadingMetadata = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingMetadata = false
                }
                print("Failed to fetch metadata: \(error)")
            }
        }
    }
}