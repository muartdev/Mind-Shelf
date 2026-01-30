import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var allLinks: [LinkItem]
    @State private var searchText = ""
    
    var filteredLinks: [LinkItem] {
        if searchText.isEmpty {
            return allLinks
        } else {
            return allLinks.filter { link in
                link.title.localizedCaseInsensitiveContains(searchText) ||
                link.url.localizedCaseInsensitiveContains(searchText) ||
                link.category.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredLinks) { link in
                    NavigationLink(destination: LinkDetailView(link: link)) {
                        LinkRowView(link: link)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search links...")
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
