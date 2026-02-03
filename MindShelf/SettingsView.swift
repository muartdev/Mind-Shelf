import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    private var appVersion: String {
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(shortVersion) (\(build))"
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
                    InfoRow(
                        icon: "bookmark.fill",
                        iconColor: .secondary,
                        title: "Total Links",
                        value: "Coming Soon"
                    )
                    
                    InfoRow(
                        icon: "star.fill",
                        iconColor: .secondary,
                        title: "Favorites",
                        value: "Coming Soon"
                    )
                } header: {
                    Label("Statistics", systemImage: "chart.bar.fill")
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

#Preview {
    SettingsView()
}
