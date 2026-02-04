import SwiftUI
import SwiftData

struct LinkDetailView: View {
    @Bindable var link: LinkItem
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var favoritePulse = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                metaRow
                
                if let note = link.userNote {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(note)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                }
                
                if let reminderDate = link.reminderDate {
                    HStack(spacing: 8) {
                        Image(systemName: "bell")
                            .foregroundStyle(.secondary)
                        Text(reminderDate, style: .date)
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(reminderDate, style: .time)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    if let url = URL(string: link.url) {
                        openURL(url)
                    }
                } label: {
                    Image(systemName: "arrow.up.right")
                }
                .buttonStyle(.plain)
                
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                        link.isFavorite.toggle()
                        favoritePulse = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        favoritePulse = false
                    }
                    WidgetDataStore.updateFavorite(id: link.id, isFavorite: link.isFavorite)
                } label: {
                    Image(systemName: link.isFavorite ? "star.fill" : "star")
                        .scaleEffect(favoritePulse ? 1.25 : 1.0)
                        .foregroundStyle(link.isFavorite ? .yellow : .primary)
                }
                .buttonStyle(.plain)
                
                Button(role: .destructive) {
                    modelContext.delete(link)
                    WidgetDataStore.removeLink(id: link.id)
                    dismiss()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .tint(.secondary)
    }
    
    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 44, height: 44)
                faviconOrCategoryIcon
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(link.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                    .lineLimit(2)
                Text(displayHost(from: link.url))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var metaRow: some View {
        HStack(spacing: 8) {
            if let category = LinkCategory(rawValue: link.category) {
                Label(category.rawValue, systemImage: category.icon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }
            
            Text(link.createdDate, style: .date)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
        }
    }
    
    private var faviconOrCategoryIcon: some View {
        Group {
            if let url = URL(string: link.url),
               let faviconURL = LinkMetadataService.shared.getFaviconURL(for: url) {
                AsyncImage(url: faviconURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
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
    
    private var categoryIcon: some View {
        Image(systemName: LinkCategory(rawValue: link.category)?.icon ?? "link")
            .font(.system(size: 18))
            .foregroundStyle(.secondary)
    }
    
    private func displayHost(from urlString: String) -> String {
        guard let url = URL(string: urlString) else { return urlString }
        return url.host?.replacingOccurrences(of: "www.", with: "") ?? urlString
    }
}
