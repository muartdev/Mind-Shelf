import SwiftUI
import SwiftData

struct CategoryLinkRowView: View {
    let link: LinkItem
    
    @Environment(\.modelContext) private var modelContext
    @State private var showQRCodeSheet = false
    
    var body: some View {
        HStack(spacing: 12) {
            thumbnail
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(displayTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                Text(displayHost)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(readingTimeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
        .contextMenu {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    link.isFavorite.toggle()
                }
                WidgetDataStore.updateFavorite(id: link.id, isFavorite: link.isFavorite)
            } label: {
                Label(link.isFavorite ? "Unfavorite" : "Favorite", systemImage: link.isFavorite ? "star.slash" : "star")
            }
            
            Button {
                scheduleQuickReminder()
            } label: {
                Label("Quick Reminder", systemImage: "bell")
            }
            
            Menu {
                Button("Automatic") {
                    link.categoryGroupOverride = nil
                }
                ForEach(LinkCategoryGroup.displayOrder) { category in
                    Button(category.title) {
                        link.categoryGroupOverride = category.rawValue
                    }
                }
            } label: {
                Label("Change Category", systemImage: "folder")
            }
            
            Button {
                showQRCodeSheet = true
            } label: {
                Label("Share via QR Code", systemImage: "qrcode")
            }
            
            Button(role: .destructive) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                    modelContext.delete(link)
                    WidgetDataStore.removeLink(id: link.id)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showQRCodeSheet) {
            QRCodeSheetView(urlString: link.url, title: displayTitle)
        }
        .onDrag {
            NSItemProvider(object: link.id.uuidString as NSString)
        }
    }
    
    private var displayTitle: String {
        let trimmed = link.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == link.url {
            return displayHost
        }
        return trimmed
    }
    
    private var displayHost: String {
        guard let url = URL(string: link.url) else { return link.url }
        return url.host?.replacingOccurrences(of: "www.", with: "") ?? link.url
    }
    
    private var readingTimeText: String {
        if let duration = link.durationText, !duration.isEmpty {
            return duration
        }
        if let minutes = link.readingTimeMinutes {
            return "~\(minutes) min read"
        }
        return "~1 min read"
    }
    
    private var thumbnail: some View {
        if let thumbURL = resolvedThumbnailURL {
            return AnyView(
                AsyncImage(url: thumbURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipped()
                    case .failure, .empty:
                        fallbackThumbnail
                    @unknown default:
                        fallbackThumbnail
                    }
                }
            )
        }
        return AnyView(fallbackThumbnail)
    }
    
    private var resolvedThumbnailURL: URL? {
        if let urlString = link.thumbnailURL, let url = URL(string: urlString) {
            return url
        }
        guard let linkURL = URL(string: link.url) else { return nil }
        if let urlString = LinkMetadataService.shared.thumbnailURL(for: linkURL) {
            return URL(string: urlString)
        }
        return nil
    }
    
    private var fallbackThumbnail: some View {
        ZStack {
            Color(.secondarySystemBackground)
            if let url = URL(string: link.url),
               let faviconURL = LinkMetadataService.shared.getFaviconURL(for: url) {
                AsyncImage(url: faviconURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 22, height: 22)
                    case .failure, .empty:
                        Image(systemName: "link")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    @unknown default:
                        Image(systemName: "link")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Image(systemName: "link")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func scheduleQuickReminder() {
        let reminderDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        NotificationManager.shared.scheduleReminder(
            bookmarkID: link.id,
            title: displayTitle,
            date: reminderDate,
            url: link.url
        )
        link.reminderDate = reminderDate
    }
}

#Preview {
    CategoryLinkRowView(
        link: LinkItem(
            url: "https://developer.apple.com",
            title: "Apple Developer Documentation",
            category: LinkCategory.article.rawValue
        )
    )
    .padding()
}
