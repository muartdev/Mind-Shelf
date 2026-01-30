import SwiftUI
import SwiftData

struct LinkDetailView: View {
    @Bindable var link: LinkItem
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Thumbnail placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        Image(systemName: categoryIcon)
                            .font(.system(size: 60))
                            .foregroundStyle(.blue.opacity(0.3))
                    )
                
                // Title
                Text(link.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                // URL
                HStack {
                    Image(systemName: "link")
                        .foregroundStyle(.secondary)
                    Text(link.url)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                        .lineLimit(2)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                // Category & Date
                HStack {
                    Label(link.category, systemImage: categoryIcon)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(link.createdDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button {
                        if let url = URL(string: link.url) {
                            openURL(url)
                        }
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    } label: {
                        Label("Open Link", systemImage: "safari")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                    }
                    
                    Button {
                        link.isFavorite.toggle()
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    } label: {
                        Label(
                            link.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                            systemImage: link.isFavorite ? "star.slash.fill" : "star.fill"
                        )
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(link.isFavorite ? Color.gray.opacity(0.2) : Color.yellow.opacity(0.2))
                        .foregroundStyle(link.isFavorite ? .secondary : Color.yellow)
                        .cornerRadius(10)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Link Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var categoryIcon: String {
        guard let category = LinkCategory(rawValue: link.category) else {
            return "folder.fill"
        }
        return category.icon
    }
}