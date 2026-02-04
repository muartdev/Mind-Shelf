import SwiftUI
import SwiftData
import Combine
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    // Sort links by creation date in reverse order
    @Query(sort: \LinkItem.createdDate, order: .reverse) private var allLinks: [LinkItem]
    @State private var showingAddLink = false
    @State private var didRefreshMetadata = false
    @State private var now = Date()
    @State private var selectedBookmark: LinkItem?
    @State private var dropTargetedCategory: LinkCategoryGroup?
    @State private var selectedCategory: LinkCategoryGroup = LinkCategoryGroup.displayOrder.first ?? .other
    @State private var searchText = ""
    @State private var toastMessage: String?
    private let reminderTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                mainContent
            }
            .toolbar { mainToolbar }
            .sheet(isPresented: $showingAddLink) {
                AddLinkView()
            }
            .onAppear {
                checkForPendingLinks()
                if !didRefreshMetadata {
                    refreshPlaceholderMetadata()
                    didRefreshMetadata = true
                }
                updateInitialCategorySelection()
                WidgetDataStore.sync(from: allLinks)
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    checkForPendingLinks()
                }
            }
            .onChange(of: allLinks.count) { _, _ in
                updateInitialCategorySelection()
                WidgetDataStore.sync(from: allLinks)
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
            .onReceive(NotificationCenter.default.publisher(for: .linkSaved)) { _ in
                showToast(message: "Link saved!")
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .navigationDestination(item: $selectedBookmark) { link in
                LinkDetailView(link: link)
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search links")
        }
        .overlay(alignment: .top) {
            if let toastMessage {
                ToastBanner(message: toastMessage)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .tint(.primary)
    }

    @ViewBuilder
    private var mainContent: some View {
        if allLinks.isEmpty {
            emptyStateView
        } else if isSearching {
            searchResultsView
        } else {
            homeListView
        }
    }

    @ToolbarContentBuilder
    private var mainToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showingAddLink = true
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.plain)
        }
    }

    private var emptyStateView: some View {
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
    }

    private var homeListView: some View {
        List {
            remindersSection
                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            
            categoryScrollSection
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            
            Section {
                if selectedCategoryLinks.isEmpty {
                    Text("No links in this category yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(selectedCategoryLinks) { link in
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
            } header: {
                HStack {
                    Text(selectedCategory.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(.horizontal, 12)
            }
            .textCase(nil)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    private func count(for category: LinkCategoryGroup) -> Int {
        allLinks.filter { category.matches($0) }.count
    }
    
    private var selectedCategoryLinks: [LinkItem] {
        allLinks.filter { selectedCategory.matches($0) }
    }
    
    private var reminders: [LinkItem] {
        allLinks
            .filter { $0.reminderDate != nil }
            .sorted { ($0.reminderDate ?? .distantFuture) < ($1.reminderDate ?? .distantFuture) }
    }
    
    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Reminders")
                .font(.headline)
                .padding(.horizontal, 4)
            
            if reminders.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "bell")
                        .foregroundStyle(.secondary)
                    Text("You haven't set any reminders yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(reminders) { link in
                            ReminderCardView(link: link, now: now)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var categoryScrollSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Categories")
                .font(.headline)
                .padding(.horizontal, 12)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(LinkCategoryGroup.displayOrder) { category in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedCategory = category
                            }
                        } label: {
                            CategoryCardView(
                                category: category,
                                count: count(for: category),
                                isSelected: selectedCategory == category,
                                isDropTargeted: dropTargetedCategory == category
                            )
                        }
                        .buttonStyle(.plain)
                        .onDrop(of: [UTType.text], isTargeted: dropTargetBinding(for: category)) { providers in
                            handleDrop(providers, on: category)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
        }
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var searchResults: [LinkItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        return allLinks.filter { link in
            link.title.localizedCaseInsensitiveContains(query) ||
            link.url.localizedCaseInsensitiveContains(query)
        }
    }
    
    private var searchResultsView: some View {
        Group {
            if searchResults.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No Results")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Try a different keyword")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(searchResults) { link in
                        NavigationLink(destination: LinkDetailView(link: link)) {
                            CategoryLinkRowView(link: link)
                        }
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
    
    
    // Check for links saved via Share Extension
    private func checkForPendingLinks() {
        guard let savedURLs = UserDefaults(suiteName: "group.mindshelf")?.array(forKey: "pendingLinks") as? [String] else {
            return
        }
        
        for urlString in savedURLs {
            if findDuplicateLink(for: urlString) != nil {
                showToast(message: "This link is already in your Mind Shelf!")
                continue
            }
            let newLink = LinkItem(
                url: urlString,
                title: urlString,
                category: LinkCategory.other.rawValue
            )
            modelContext.insert(newLink)
            fetchAndUpdateMetadata(for: newLink)
            WidgetDataStore.upsert(link: newLink)
            showToast(message: "Link saved!")
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

    private func dropTargetBinding(for category: LinkCategoryGroup) -> Binding<Bool> {
        Binding(
            get: { dropTargetedCategory == category },
            set: { isTargeted in
                if isTargeted {
                    dropTargetedCategory = category
                } else if dropTargetedCategory == category {
                    dropTargetedCategory = nil
                }
            }
        )
    }
    
    private func handleDrop(_ providers: [NSItemProvider], on category: LinkCategoryGroup) -> Bool {
        guard let provider = providers.first else { return false }
        if provider.canLoadObject(ofClass: NSString.self) {
            _ = provider.loadObject(ofClass: NSString.self) { object, _ in
                guard let idString = object as? String,
                      let id = UUID(uuidString: idString) else { return }
                DispatchQueue.main.async {
                    if let link = allLinks.first(where: { $0.id == id }) {
                        link.categoryGroupOverride = category.rawValue
                    }
                }
            }
            return true
        }
        return false
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
            if link.readingTimeMinutes == nil {
                link.readingTimeMinutes = await LinkMetadataService.shared.fetchReadingTimeMinutes(for: url)
            }
            WidgetDataStore.upsert(link: link)
        }
    }

    private func showToast(message: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            toastMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.2)) {
                toastMessage = nil
            }
        }
    }
    
    private func findDuplicateLink(for urlString: String) -> LinkItem? {
        let normalized = normalizedURLString(urlString)
        guard !normalized.isEmpty else { return nil }
        return allLinks.first { normalizedURLString($0.url) == normalized }
    }
    
    private func normalizedURLString(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else { return trimmed.lowercased() }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.fragment = nil
        let normalized = components?.url?.absoluteString ?? trimmed
        return normalized.lowercased()
    }

    private func updateInitialCategorySelection() {
        guard !allLinks.isEmpty else { return }
        if selectedCategoryLinks.isEmpty,
           let firstWithItems = LinkCategoryGroup.displayOrder.first(where: { count(for: $0) > 0 }) {
            selectedCategory = firstWithItems
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "mindshelf" else { return }
        if url.host == "link" {
            let idString = url.pathComponents.dropFirst().first ?? ""
            if let id = UUID(uuidString: idString),
               let link = allLinks.first(where: { $0.id == id }) {
                selectedBookmark = link
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: LinkItem.self, inMemory: true)
}
