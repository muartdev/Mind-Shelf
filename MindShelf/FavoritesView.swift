import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<LinkItem> { $0.isFavorite == true }, sort: \LinkItem.createdDate, order: .reverse)
    private var favoriteLinks: [LinkItem]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                Group {
                    if favoriteLinks.isEmpty {
                        VStack(spacing: 24) {
                            ZStack {
                                Circle()
                                    .fill(Color(.secondarySystemBackground))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "star.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.secondary)
                            }
                            
                            VStack(spacing: 8) {
                                Text("No Favorites")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("Star links to see them here")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(favoriteLinks) { link in
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
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .tint(.primary)
    }
}

#Preview {
    FavoritesView()
        .modelContainer(for: LinkItem.self, inMemory: true)
}
