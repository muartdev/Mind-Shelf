import SwiftUI
import SwiftData

struct SquareLinkCardView: View {
    let link: LinkItem
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @State private var showReminderPicker = false
    @State private var reminderDate = Date()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            thumbnailView
                .aspectRatio(16/9, contentMode: .fill)
            
            Text(displayTitle)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(2)
            
            HStack(spacing: 6) {
                Text(displayHost)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Text("•")
                    .font(.caption2)
                    .foregroundStyle(Color.secondary.opacity(0.7))
                
                Text(compactTimeText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button {
                    reminderDate = link.reminderDate ?? Date()
                    showReminderPicker = true
                } label: {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .contextMenu {
            if let url = URL(string: link.url) {
                Button("Open Link") {
                    openURL(url)
                }
                ShareLink(item: url) {
                    Label("Şimdi Paylaş", systemImage: "square.and.arrow.up")
                }
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
        .onDrag {
            NSItemProvider(object: link.id.uuidString as NSString)
        }
    }
    
    private var categoryIcon: some View {
        Image(systemName: LinkCategory(rawValue: link.category)?.icon ?? "link")
            .font(.system(size: 18))
            .foregroundStyle(.secondary)
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
    
    private var thumbnailURL: URL? {
        if let urlString = link.thumbnailURL, let url = URL(string: urlString) {
            return url
        }
        guard let linkURL = URL(string: link.url) else { return nil }
        if let urlString = LinkMetadataService.shared.thumbnailURL(for: linkURL) {
            return URL(string: urlString)
        }
        return nil
    }
    
    private var thumbnailView: some View {
        ZStack(alignment: .topTrailing) {
            if let thumb = thumbnailURL {
                AsyncImage(url: thumb) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .clipped()
                    case .failure, .empty:
                        fallbackThumbnail
                    @unknown default:
                        fallbackThumbnail
                    }
                }
            } else {
                fallbackThumbnail
            }
            
            if link.isFavorite {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
                    .padding(6)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                            .frame(width: 28, height: 28)
                    case .failure, .empty:
                        categoryIcon
                    @unknown default:
                        categoryIcon
                    }
                }
            } else {
                categoryIcon
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
    SquareLinkCardView(
        link: LinkItem(
            url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            title: "Sample Video Title",
            category: LinkCategory.video.rawValue
        )
    )
    .padding()
    .frame(width: 180)
}
