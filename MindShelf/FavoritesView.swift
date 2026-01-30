import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<LinkItem> { $0.isFavorite == true }, sort: \LinkItem.createdDate, order: .reverse)
    private var favoriteLinks: [LinkItem]
    
    var body: some View {
        NavigationStack {
            Group {
                if favoriteLinks.isEmpty {
                    ContentUnavailableView(
                        "No Favorites",
                        systemImage: "star.slash",
                        description: Text("Links you favorite will appear here")
                    )
                } else {
                    List {
                        ForEach(favoriteLinks) { link in
                            NavigationLink(destination: LinkDetailView(link: link)) {
                                LinkRowView(link: link)
                            }
                        }
                        .onDelete(perform: deleteLinks)
                    }
                }
            }
            .navigationTitle("Favorites")
        }
    }
    
    private func deleteLinks(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(favoriteLinks[index])
        }
    }
}
