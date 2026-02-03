import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \LinkItem.createdDate, order: .reverse) private var allLinks: [LinkItem]
    @State private var searchText = ""
    @State private var selectedCategory: LinkCategory? = nil
    
    var filteredLinks: [LinkItem] {
        var links = allLinks
        
        // Kategori filtresi
        if let category = selectedCategory {
            links = links.filter { $0.category == category.rawValue }
        }
        
        // Arama filtresi
        if !searchText.isEmpty {
            links = links.filter { link in
                link.title.localizedCaseInsensitiveContains(searchText) ||
                link.url.localizedCaseInsensitiveContains(searchText) ||
                link.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return links
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Kategori filtreleri
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // All button
                        FilterChip(
                            title: "All",
                            icon: "square.grid.2x2",
                            isSelected: selectedCategory == nil,
                            colors: [.primary]
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedCategory = nil
                            }
                        }
                        
                        // Kategori butonları
                        ForEach(LinkCategory.allCases, id: \.self) { category in
                            FilterChip(
                                title: category.rawValue,
                                icon: category.icon,
                                isSelected: selectedCategory == category,
                                colors: categoryColors(for: category)
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                
                // Sonuçlar
                if filteredLinks.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: searchText.isEmpty ? "magnifyingglass" : "exclamationmark.magnifyingglass")
                            .font(.system(size: 70))
                            .foregroundStyle(.secondary)
                        
                        VStack(spacing: 8) {
                            Text(searchText.isEmpty ? "Start Searching" : "No Matches")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(searchText.isEmpty ? "Type to search your links" : "Try different keywords or category")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredLinks) { link in
                            NavigationLink(destination: LinkDetailView(link: link)) {
                                CategoryLinkRowView(link: link)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .searchable(text: $searchText, prompt: "Search title, URL, or category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .tint(.primary)
    }
    
    private func categoryColors(for category: LinkCategory) -> [Color] {
        return [.primary]
    }
}

// Kategori filter chip component
struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let colors: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        Color(.systemBackground)
                    } else {
                        Color(.secondarySystemBackground)
                    }
                }
            )
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Color.primary.opacity(0.2) : Color.clear, lineWidth: 1)
            )
        }
    }
}

#Preview {
    SearchView()
        .modelContainer(for: LinkItem.self, inMemory: true)
}
