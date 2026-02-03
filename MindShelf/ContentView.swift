import SwiftUI
import SwiftData
import Combine

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    // Sort links by creation date in reverse order
    @Query(sort: \LinkItem.createdDate, order: .reverse) private var allLinks: [LinkItem]
    @State private var showingAddLink = false
    @State private var showingSearch = false
    @State private var didRefreshMetadata = false
    @State private var now = Date()
    @State private var selectedBookmark: LinkItem?
    private let reminderTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            Group {
                if allLinks.isEmpty {
                    // Empty state view
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(Color(.secondarySystemBackground))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "bookmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(spacing: 8) {
                            Text("No Links Yet")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Start saving your favorite links")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Button {
                            showingAddLink = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add First Link")
                            }
                            .font(.headline)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.primary)
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            remindersSection
                                .padding(.bottom, 8)
                            
                            Text("Categories")
                                .font(.headline)
                                .padding(.horizontal, 12)
                                .padding(.top, 6)
                                .padding(.bottom, 6)
                            
                            LazyVGrid(columns: gridColumns, spacing: 12) {
                                ForEach(LinkCategoryGroup.displayOrder) { category in
                                    NavigationLink(destination: CategoryListView(category: category)) {
                                        CategoryCardView(
                                            category: category,
                                            count: count(for: category),
                                            previewLinks: previewLinks(for: category)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 12)
                        }
                        .padding(.top, 12)
                    }
                }
            }
            .toolbar {
                if !allLinks.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingSearch = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddLink = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.plain)
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
                if !didRefreshMetadata {
                    refreshPlaceholderMetadata()
                    didRefreshMetadata = true
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    checkForPendingLinks()
                }
            }
            .onReceive(reminderTimer) { value in
                now = value
            }
            .onReceive(NotificationCenter.default.publisher(for: .openBookmarkFromNotification)) { note in
                if let idString = note.userInfo?["bookmarkID"] as? String,
                   let id = UUID(uuidString: idString),
                   let link = allLinks.first(where: { $0.id == id }) {
                    selectedBookmark = link
                } else if let urlString = note.userInfo?["url"] as? String,
                          let link = allLinks.first(where: { $0.url == urlString }) {
                    selectedBookmark = link
                }
            }
            .navigationDestination(item: $selectedBookmark) { link in
                LinkDetailView(link: link)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .tint(.primary)
    }
    
    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }
    
    private func count(for category: LinkCategoryGroup) -> Int {
        allLinks.filter { category.matches($0) }.count
    }
    
    private func previewLinks(for category: LinkCategoryGroup) -> [LinkItem] {
        Array(allLinks.filter { category.matches($0) }.prefix(3))
    }
    
    private var reminders: [LinkItem] {
        allLinks
            .filter { $0.reminderDate != nil }
            .sorted { ($0.reminderDate ?? .distantFuture) < ($1.reminderDate ?? .distantFuture) }
    }
    
    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reminders")
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.top, 6)
                .padding(.bottom, 6)
            
            if reminders.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "bell")
                        .foregroundStyle(.secondary)
                    Text("You haven't set any reminders yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(reminders) { link in
                            ReminderCardView(link: link, now: now)
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
        }
    }
    
    
    // Check for links saved via Share Extension
    private func checkForPendingLinks() {
        guard let savedURLs = UserDefaults(suiteName: "group.mindshelf")?.array(forKey: "pendingLinks") as? [String] else {
            return
        }
        
        for urlString in savedURLs {
            if allLinks.contains(where: { $0.url == urlString }) {
                continue
            }
            let newLink = LinkItem(
                url: urlString,
                title: urlString,
                category: LinkCategory.other.rawValue
            )
            modelContext.insert(newLink)
            fetchAndUpdateMetadata(for: newLink)
        }
        
        UserDefaults(suiteName: "group.mindshelf")?.removeObject(forKey: "pendingLinks")
    }
    
    private func refreshPlaceholderMetadata() {
        for link in allLinks {
            guard let url = URL(string: link.url) else { continue }
            if LinkMetadataService.shared.isPlaceholderTitle(link.title, for: url) {
                fetchAndUpdateMetadata(for: link)
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

#Preview {
    ContentView()
        .modelContainer(for: LinkItem.self, inMemory: true)
}
