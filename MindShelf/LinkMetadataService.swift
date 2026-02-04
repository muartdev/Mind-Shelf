import Foundation
import LinkPresentation
import UIKit

class LinkMetadataService {
    static let shared = LinkMetadataService()
    
    private init() {}
    
    func fetchMetadata(for url: URL) async -> (title: String, suggestedCategory: LinkCategory?) {
        let provider = LPMetadataProvider()
        
        var title: String = ""
        do {
            // Timeout logic can be added here if needed, but LPMetadataProvider handles it reasonably.
            let metadata = try await provider.startFetchingMetadata(for: url)
            title = metadata.title ?? ""
        } catch {
            title = ""
        }
        
        title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty {
            title = cleanTitle(title, for: url)
        }
        
        if isPlaceholderTitle(title, for: url) {
            if let oembedTitle = await fetchOEmbedTitle(for: url) {
                title = cleanTitle(oembedTitle, for: url)
            }
        }
        
        if isPlaceholderTitle(title, for: url) {
            title = url.absoluteString
        }
        
        let category = suggestCategory(for: url)
        return (title, category)
    }
    
    func getFaviconURL(for url: URL) -> URL? {
        let urlString = url.absoluteString
        guard let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        // Using Google's favicon service for reliable icons
        return URL(string: "https://www.google.com/s2/favicons?sz=128&domain_url=\(encoded)")
    }

    func fetchDurationText(for url: URL) async -> String? {
        guard isYouTubeLink(url) else { return nil }
        guard let videoId = youtubeVideoID(from: url) else { return nil }
        return await fetchYouTubeDurationText(videoId: videoId)
    }

    func fetchReadingTimeMinutes(for url: URL) async -> Int? {
        guard !isYouTubeLink(url) else { return nil }
        guard ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return nil }
        guard let (text, isHTML) = await fetchPageText(for: url) else { return nil }
        let content = isHTML ? stripHTML(from: text) : text
        let words = wordCount(in: content)
        guard words > 0 else { return nil }
        let minutes = max(1, Int(ceil(Double(words) / 200.0)))
        return minutes
    }
    
    func thumbnailURL(for url: URL) -> String? {
        guard isYouTubeLink(url) else { return nil }
        guard let videoId = youtubeVideoID(from: url) else { return nil }
        return "https://i.ytimg.com/vi/\(videoId)/hqdefault.jpg"
    }
    
    private func suggestCategory(for url: URL) -> LinkCategory? {
        guard let host = url.host?.lowercased() else { return nil }
        let path = url.path.lowercased()
        let query = (url.query ?? "").lowercased()
        
        // Video first: common hosts + common video path hints
        if host.contains("youtube")
            || host.contains("youtu.be")
            || host.contains("vimeo")
            || host.contains("netflix")
            || host.contains("tiktok")
            || host.contains("twitch")
            || host.contains("dailymotion")
            || host.contains("loom") {
            return .video
        }
        
        if path.contains("/watch")
            || path.contains("/video")
            || path.contains("/videos")
            || path.contains("/playlist")
            || query.contains("list=")
            || query.contains("v=") {
            return .video
        }
        
        // Article/reading platforms
        if host.contains("medium")
            || host.contains("substack")
            || host.contains("wikipedia")
            || host.contains("nytimes")
            || host.contains("theverge")
            || host.contains("wired")
            || host.contains("arstechnica")
            || host.contains("dev.to")
            || host.contains("hashnode")
            || host.contains("blog")
            || host.contains("news")
            || host.contains("towardsdatascience") {
            return .article
        }
        
        if path.contains("/blog")
            || path.contains("/posts")
            || path.contains("/article")
            || path.contains("/read")
            || path.contains("/story") {
            return .article
        }
        
        // Shopping / commerce
        if host.contains("amazon")
            || host.contains("ebay")
            || host.contains("etsy")
            || host.contains("shopify")
            || host.contains("aliexpress")
            || host.contains("temu")
            || host.contains("walmart")
            || host.contains("bestbuy")
            || host.contains("target")
            || host.contains("ikea")
            || host.contains("trendyol")
            || host.contains("hepsiburada")
            || host.contains("n11") {
            return .shopping
        }
        
        if path.contains("/product")
            || path.contains("/products")
            || path.contains("/shop")
            || path.contains("/cart")
            || path.contains("/checkout") {
            return .shopping
        }
        
        // Social
        if host.contains("twitter")
            || host.contains("x.com")
            || host.contains("instagram")
            || host.contains("linkedin")
            || host.contains("facebook")
            || host.contains("reddit")
            || host.contains("threads")
            || host.contains("discord")
            || host.contains("t.me")
            || host.contains("telegram")
            || host.contains("pinterest") {
            return .social
        }
        
        if path.contains("/u/")
            || path.contains("/user/")
            || path.contains("/users/")
            || path.contains("/profile")
            || path.contains("/status/")
            || path.contains("/r/") {
            return .social
        }
        
        // Fallback
        return .other
    }
    
    func isPlaceholderTitle(_ title: String, for url: URL) -> Bool {
        let normalized = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized.isEmpty { return true }
        
        let urlString = url.absoluteString.lowercased()
        let host = (url.host ?? "").lowercased()
        let hostBare = host.replacingOccurrences(of: "www.", with: "")
        
        if normalized == urlString { return true }
        if normalized == host || normalized == hostBare { return true }
        
        if normalized == "youtube" || normalized == "youtube.com" || normalized == "youtu.be" { return true }
        if normalized == "vimeo" || normalized == "vimeo.com" { return true }
        
        return false
    }

    private func cleanTitle(_ rawTitle: String, for url: URL) -> String {
        let original = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !original.isEmpty else { return rawTitle }
        
        let parts = splitTitleParts(original)
        let tokens = noisyTokens(for: url)
        let filtered = parts.filter { !isNoisyPart($0, tokens: tokens) }
        let candidates = filtered.isEmpty ? parts : filtered
        
        guard let best = candidates.max(by: { titleScore($0) < titleScore($1) }) else {
            return original
        }
        
        let cleaned = best.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.count < 3 ? original : cleaned
    }
    
    private func splitTitleParts(_ title: String) -> [String] {
        let separators = [" - ", " | ", " • ", " — ", " – ", " : ", " :: "]
        var parts = [title]
        for separator in separators {
            parts = parts.flatMap { $0.components(separatedBy: separator) }
        }
        return parts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    private func noisyTokens(for url: URL) -> [String] {
        var tokens = [
            "youtube",
            "youtube.com",
            "youtu.be",
            "login",
            "log in",
            "sign in",
            "signin",
            "sign up",
            "signup",
            "giris yap",
            "giris",
            "oturum ac",
            "kayit ol",
            "subscribe",
            "subscribe now",
            "abone ol",
            "abonelik"
        ]
        
        if let host = url.host?.lowercased() {
            let trimmedHost = host.replacingOccurrences(of: "www.", with: "")
            tokens.append(trimmedHost)
            let parts = trimmedHost.split(separator: ".")
            if parts.count >= 2 {
                tokens.append(String(parts[parts.count - 2]))
            }
        }
        
        return tokens
    }
    
    private func isNoisyPart(_ part: String, tokens: [String]) -> Bool {
        let lower = part.lowercased()
        let normalized = lower.folding(options: .diacriticInsensitive, locale: .current)
        let normalizedNoSpace = normalized.replacingOccurrences(of: " ", with: "")
        
        for token in tokens {
            let tokenNoSpace = token.replacingOccurrences(of: " ", with: "")
            if normalized == token || normalizedNoSpace == tokenNoSpace {
                return true
            }
            if normalized.contains(token) && normalized.count <= token.count + 4 {
                return true
            }
        }
        
        return false
    }
    
    private func titleScore(_ part: String) -> Int {
        let letters = part.filter { $0.isLetter }.count
        let digits = part.filter { $0.isNumber }.count
        return letters * 3 + digits + part.count
    }
    
    private func fetchOEmbedTitle(for url: URL) async -> String? {
        guard let host = url.host?.lowercased() else { return nil }
        
        var oembedURLs: [URL] = []
        if host.contains("youtube") || host.contains("youtu.be") {
            var components = URLComponents(string: "https://www.youtube.com/oembed")
            components?.queryItems = [
                URLQueryItem(name: "url", value: url.absoluteString),
                URLQueryItem(name: "format", value: "json")
            ]
            if let url = components?.url { oembedURLs.append(url) }
        } else if host.contains("vimeo") {
            var components = URLComponents(string: "https://vimeo.com/api/oembed.json")
            components?.queryItems = [
                URLQueryItem(name: "url", value: url.absoluteString)
            ]
            if let url = components?.url { oembedURLs.append(url) }
        } else {
            return nil
        }
        
        // Fallback to noembed if primary oEmbed fails
        if let noEmbedURL = URL(string: "https://noembed.com/embed") {
            var components = URLComponents(url: noEmbedURL, resolvingAgainstBaseURL: false)
            components?.queryItems = [
                URLQueryItem(name: "url", value: url.absoluteString)
            ]
            if let fallbackURL = components?.url { oembedURLs.append(fallbackURL) }
        }
        
        for requestURL in oembedURLs {
            if let title = await fetchOEmbedTitle(from: requestURL) {
                return title
            }
        }
        
        return nil
    }
}

private struct OEmbedResponse: Decodable {
    let title: String
}

private extension LinkMetadataService {
    func fetchPageText(for url: URL) async -> (String, Bool)? {
        var request = URLRequest(url: url)
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                return nil
            }
            let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1)
            guard let body = html else { return nil }
            let contentType = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Content-Type") ?? ""
            let isHTML = contentType.contains("text/html") || body.contains("<html")
            return (body, isHTML)
        } catch {
            return nil
        }
    }
    
    func stripHTML(from string: String) -> String {
        let withoutScripts = removeTagContents(from: string, tag: "script")
        let withoutStyles = removeTagContents(from: withoutScripts, tag: "style")
        let withoutTags = withoutStyles.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        let entitiesDecoded = decodeHTMLEntities(in: withoutTags)
        return entitiesDecoded
    }
    
    func removeTagContents(from string: String, tag: String) -> String {
        let pattern = "<\(tag)[\\s\\S]*?</\(tag)>"
        return string.replacingOccurrences(of: pattern, with: " ", options: .regularExpression)
    }
    
    func decodeHTMLEntities(in string: String) -> String {
        guard let data = string.data(using: .utf8) else { return string }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        let decoded = try? NSAttributedString(data: data, options: options, documentAttributes: nil).string
        return decoded ?? string
    }
    
    func wordCount(in text: String) -> Int {
        let tokens = text
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
        return tokens.count
    }

    func isYouTubeLink(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host.contains("youtube.com") || host.contains("youtu.be") || host.contains("music.youtube.com")
    }
    
    func youtubeVideoID(from url: URL) -> String? {
        let host = (url.host ?? "").lowercased()
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        if host.contains("youtu.be") {
            return pathComponents.first
        }
        
        if host.contains("youtube.com") {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let id = components.queryItems?.first(where: { $0.name == "v" })?.value {
                return id
            }
            
            if let index = pathComponents.firstIndex(of: "shorts"), index + 1 < pathComponents.count {
                return pathComponents[index + 1]
            }
            
            if let index = pathComponents.firstIndex(of: "embed"), index + 1 < pathComponents.count {
                return pathComponents[index + 1]
            }
        }
        
        return nil
    }
    
    func fetchYouTubeDurationText(videoId: String) async -> String? {
        guard let url = URL(string: "https://www.youtube.com/watch?v=\(videoId)") else { return nil }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 8
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                return nil
            }
            guard let html = String(data: data, encoding: .utf8) else { return nil }
            
            if let seconds = extractLengthSeconds(from: html) {
                return formatDuration(seconds: seconds)
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    func extractLengthSeconds(from html: String) -> Int? {
        let marker = "\"lengthSeconds\":\""
        guard let range = html.range(of: marker) else { return nil }
        let substring = html[range.upperBound...]
        let digits = substring.prefix { $0.isNumber }
        return Int(digits)
    }
    
    func formatDuration(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }
    
    func fetchOEmbedTitle(from url: URL) async -> String? {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 8
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                return nil
            }
            let decoded = try JSONDecoder().decode(OEmbedResponse.self, from: data)
            let title = decoded.title.trimmingCharacters(in: .whitespacesAndNewlines)
            return title.isEmpty ? nil : title
        } catch {
            return nil
        }
    }
}
