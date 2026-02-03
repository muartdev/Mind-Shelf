import SwiftUI
import SwiftData

struct CategoryLinkRowView: View {
    let link: LinkItem
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @State private var showReminderPicker = false
    @State private var reminderDate = Date()
    
    var body: some View {
        HStack(spacing: 12) {
            thumbnail
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(displayTitle)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                HStack(spacing: 6) {
                    Text(displayHost)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary.opacity(0.7))
                    
                    Text(compactTimeText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Button {
                reminderDate = link.reminderDate ?? Date()
                showReminderPicker = true
            } label: {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
        }
        .contextMenu {
            if let url = URL(string: link.url) {
                Button("Open Link") { openURL(url) }
                ShareLink(item: url)
            }
            Button(role: .destructive) {
                modelContext.delete(link)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showReminderPicker) {
            NavigationStack {
                VStack(spacing: 16) {
                    DatePicker("Reminder Time", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                    
                    Button("Schedule Reminder") {
                        NotificationManager.shared.scheduleReminder(
                            bookmarkID: link.id,
                            title: displayTitle,
                            date: reminderDate,
                            url: link.url
                        )
                        link.reminderDate = reminderDate
                        showReminderPicker = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.primary)
                }
                .padding()
                .navigationTitle("Reminder")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showReminderPicker = false
                        }
                    }
                }
            }
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
    
    private var compactTimeText: String {
        if let reminderDate = link.reminderDate {
            return "rem \(reminderText(for: reminderDate))"
        }
        let seconds = Int(Date().timeIntervalSince(link.createdDate))
        if seconds < 60 { return "now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h" }
        let days = hours / 24
        return "\(days)d"
    }
    
    private func reminderText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
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
                            .scaledToFit()
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
