import SwiftUI
import SwiftData

struct CategoryListView: View {
    let category: LinkCategoryGroup
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LinkItem.createdDate, order: .reverse) private var allLinks: [LinkItem]
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            List {
                ForEach(filteredLinks) { link in
                    NavigationLink(destination: LinkDetailView(link: link)) {
                        CategoryLinkRowView(link: link)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                                modelContext.delete(link)
                                WidgetDataStore.removeLink(id: link.id)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
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
