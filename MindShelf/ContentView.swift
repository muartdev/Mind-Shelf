import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allLinks: [LinkItem]
    @State private var showingAddLink = false
    @State private var showingSearch = false
    @State private var searchText = ""
    @State private var selectedCategory: LinkCategory? = nil
    
    var filteredLinks: [LinkItem] {
        var links = allLinks
        
        if let category = selectedCategory {
            links = links.filter { $0.category == category.rawValue }
        }
        
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
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // All button
                        Button {
                            selectedCategory = nil
                        } label: {
                            Text("All")
                                .font(.subheadline)
                                .fontWeight(selectedCategory == nil ? .semibold : .regular)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedCategory == nil ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundStyle(selectedCategory == nil ? .white : .primary)
                                .cornerRadius(20)
                        }
                        
                        // Category buttons
                        ForEach(LinkCategory.allCases, id: \.self) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                Label(category.rawValue, systemImage: category.icon)
                                    .font(.subheadline)
                                    .fontWeight(selectedCategory == category ? .semibold : .regular)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundStyle(selectedCategory == category ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Links list
                if filteredLinks.isEmpty {
                    ContentUnavailableView(
                        "No Links Yet",
                        systemImage: "bookmark.slash",
                        description: Text("Tap + to add your first link")
                    )
                } else {
                    List {
                        ForEach(filteredLinks) { link in
                            NavigationLink(destination: LinkDetailView(link: link)) {
                                LinkRowView(link: link)
                            }
                        }
                        .onDelete(perform: deleteLinks)
                    }
                }
            }
            .navigationTitle("Mind Shelf")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddLink = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddLink) {
                AddLinkView()
            }
            .sheet(isPresented: $showingSearch) {
                SearchView()
            }
            .onAppear {
                checkForPendingLinks()
            }
        }
    }
    
    private func deleteLinks(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(allLinks[index])
        }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func checkForPendingLinks() {
        guard let savedURLs = UserDefaults(suiteName: "group.mindshelf")?.array(forKey: "pendingLinks") as? [String] else {
            return
        }
        
        for urlString in savedURLs {
            let newLink = LinkItem(
                url: urlString,
                title: urlString,
                category: LinkCategory.other.rawValue
            )
            modelContext.insert(newLink)
        }
        
        // Temizle
        UserDefaults(suiteName: "group.mindshelf")?.removeObject(forKey: "pendingLinks")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: LinkItem.self, inMemory: true)
}