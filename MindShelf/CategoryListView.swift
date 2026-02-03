import SwiftUI
import SwiftData

struct CategoryListView: View {
    let category: LinkCategoryGroup
    @Query(sort: \LinkItem.createdDate, order: .reverse) private var allLinks: [LinkItem]
    
    var body: some View {
        List {
            ForEach(filteredLinks) { link in
                NavigationLink(destination: LinkDetailView(link: link)) {
                    CategoryLinkRowView(link: link)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var filteredLinks: [LinkItem] {
        allLinks.filter { category.matches($0) }
    }
}

#Preview {
    NavigationStack {
        CategoryListView(category: .youtube)
            .modelContainer(for: LinkItem.self, inMemory: true)
    }
}
