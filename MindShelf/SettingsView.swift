import SwiftUI
import SwiftData
import Charts

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @Query private var allLinks: [LinkItem]
    
    private var appVersion: String {
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(shortVersion) (\(build))"
    }
    
    private var favoritesCount: Int {
        allLinks.filter { $0.isFavorite }.count
    }

    private struct DayCount: Identifiable {
        let date: Date
        let count: Int
        var id: Date { date }
    }

    private struct CategoryShare: Identifiable {
        let category: LinkCategoryGroup
        let count: Int
        var id: String { category.rawValue }
    }

    private var last7DaysCounts: [DayCount] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: startOfToday) ?? startOfToday
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let count = allLinks.filter { $0.createdDate >= day && $0.createdDate < nextDay }.count
            return DayCount(date: day, count: count)
        }.reversed()
    }

    private var categoryShares: [CategoryShare] {
        LinkCategoryGroup.displayOrder
            .map { category in
                CategoryShare(category: category, count: allLinks.filter { category.matches($0) }.count)
            }
            .filter { $0.count > 0 }
    }

    private func color(for category: LinkCategoryGroup) -> Color {
        switch category {
        case .youtube: return .red
        case .development: return .blue
        case .aiTools: return .purple
        case .shopping: return .orange
        case .other: return .gray
        }
    }
    
    private var categoryColorScale: KeyValuePairs<String, Color> {
        [
            LinkCategoryGroup.youtube.title: color(for: .youtube),
            LinkCategoryGroup.development.title: color(for: .development),
            LinkCategoryGroup.aiTools.title: color(for: .aiTools),
            LinkCategoryGroup.shopping.title: color(for: .shopping),
            LinkCategoryGroup.other.title: color(for: .other)
        ]
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Appearance Section
                Section {
                    HStack {
                        Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 18))
                        
                        Text("Dark Mode")
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Toggle("", isOn: $isDarkMode)
                            .labelsHidden()
                    }
                } header: {
                    Label("Appearance", systemImage: "paintbrush.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
                
                // Stats Section
                Section {
                    StatRow(
                        icon: "bookmark.fill",
                        title: "Total Links",
                        value: "\(allLinks.count)",
                        accent: .blue
                    )
                    
                    StatRow(
                        icon: "star.fill",
                        title: "Favorites",
                        value: "\(favoritesCount)",
                        accent: .orange
                    )
                } header: {
                    Label("Statistics", systemImage: "chart.bar.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Links Added (Last 7 Days)")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        if allLinks.isEmpty {
                            Text("Add links to see trends here.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Chart(last7DaysCounts) { entry in
                                BarMark(
                                    x: .value("Day", entry.date, unit: .day),
                                    y: .value("Links", entry.count)
                                )
                                .foregroundStyle(Color.blue)
                                .cornerRadius(4)
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { value in
                                    AxisGridLine()
                                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                }
                            }
                            .frame(height: 180)
                        }
                    }
                    .padding(.vertical, 6)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Category Distribution")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        if categoryShares.isEmpty {
                            Text("Save links to populate category stats.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Chart(categoryShares) { share in
                                SectorMark(
                                    angle: .value("Count", share.count),
                                    innerRadius: .ratio(0.55)
                                )
                                .foregroundStyle(by: .value("Category", share.category.title))
                            }
                            .chartForegroundStyleScale(categoryColorScale)
                            .chartLegend(position: .bottom, alignment: .leading, spacing: 8)
                            .frame(height: 220)
                        }
                    }
                    .padding(.vertical, 6)
                } header: {
                    Label("Insights", systemImage: "chart.pie.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
                
                // About Section
                Section {
                    InfoRow(
                        icon: "app.fill",
                        iconColor: .secondary,
                        title: "App Name",
                        value: "Mind Shelf"
                    )
                    
                    InfoRow(
                        icon: "number",
                        iconColor: .secondary,
                        title: "Version",
                        value: appVersion
                    )
                } header: {
                    Label("About", systemImage: "info.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
                
                // Developer Section
                Section {
                    InfoRow(
                        icon: "person.fill",
                        iconColor: .secondary,
                        title: "Developer",
                        value: "Murat"
                    )
                    
                    Link(destination: URL(string: "https://github.com/muartdev/Mind-Shelf")!) {
                        HStack {
                            Image(systemName: "link")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 18))
                            
                            Text("GitHub")
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Label("Developer", systemImage: "hammer.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
    }
}

// Info Row Component
struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.system(size: 18))
            
            Text(title)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    let accent: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(accent)
                .font(.system(size: 18))
            
            Text(title)
                .fontWeight(.medium)
            
            Spacer()
            
            HStack(spacing: 6) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Image(systemName: "chart.bar")
                    .font(.caption)
                    .foregroundStyle(accent)
            }
        }
    }
}

#Preview {
    SettingsView()
}
