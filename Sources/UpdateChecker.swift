import Foundation

// MARK: - Model

struct ReleaseInfo {
    let version:      String   // e.g. "1.1.0"
    let releaseNotes: String
    let htmlURL:      URL
    let pkgURL:       URL?     // direct download URL for the installer .pkg, nil if not in release assets
}

enum UpdateResult {
    case available(ReleaseInfo)
    case upToDate
    case failed
}

// MARK: - UpdateChecker

final class UpdateChecker {

    private let currentVersion: String
    private let releasesURL = URL(string: "https://api.github.com/repos/tinkermesomething/latch/releases/latest")!

    /// Called on main queue when a newer, non-skipped release is found (background/auto checks).
    var onUpdateAvailable: ((ReleaseInfo) -> Void)?

    init() {
        if let versionURL = Bundle.main.url(forResource: "VERSION", withExtension: nil),
           let v = try? String(contentsOf: versionURL, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
           !v.isEmpty {
            currentVersion = v
        } else {
            currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        }
    }

    // MARK: - Public

    /// Background auto-check — only calls `onUpdateAvailable` if a newer non-skipped version exists.
    func checkAsync(skippedVersions: [String]) {
        fetch { [weak self] result in
            guard let self else { return }
            switch result {
            case .available(let info):
                guard !skippedVersions.contains(info.version) else { return }
                self.onUpdateAvailable?(info)
            case .upToDate, .failed:
                break
            }
        }
    }

    /// Manual check — always delivers a result (update found, up to date, or failed).
    func checkManual(skippedVersions: [String], completion: @escaping (UpdateResult) -> Void) {
        fetch { result in
            if case .available(let info) = result, skippedVersions.contains(info.version) {
                completion(.upToDate)
            } else {
                completion(result)
            }
        }
    }

    // MARK: - Private

    private func fetch(completion: @escaping (UpdateResult) -> Void) {
        var request = URLRequest(url: releasesURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self else { return }
            guard error == nil, let data else {
                DispatchQueue.main.async { completion(.failed) }
                return
            }

            guard
                let json    = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let tagName = json["tag_name"] as? String,
                let htmlStr = json["html_url"] as? String,
                let htmlURL = URL(string: htmlStr)
            else {
                DispatchQueue.main.async { completion(.failed) }
                return
            }

            let remote = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
            let notes  = json["body"] as? String ?? ""

            // Find the installer .pkg asset (exclude the uninstaller)
            let assets = json["assets"] as? [[String: Any]] ?? []
            let pkgAsset = assets.first {
                let name = $0["name"] as? String ?? ""
                return name.hasSuffix(".pkg") && !name.contains("uninstaller")
            }
            let pkgURL = (pkgAsset?["browser_download_url"] as? String).flatMap { URL(string: $0) }

            if self.isNewer(remote, than: self.currentVersion) {
                let info = ReleaseInfo(version: remote, releaseNotes: notes, htmlURL: htmlURL, pkgURL: pkgURL)
                DispatchQueue.main.async { completion(.available(info)) }
            } else {
                DispatchQueue.main.async { completion(.upToDate) }
            }
        }.resume()
    }

    /// Semantic version compare — returns true if `a` > `b`.
    private func isNewer(_ a: String, than b: String) -> Bool {
        let av = a.split(separator: ".").compactMap { Int($0) }
        let bv = b.split(separator: ".").compactMap { Int($0) }
        let len = max(av.count, bv.count)
        for i in 0..<len {
            let ai = i < av.count ? av[i] : 0
            let bi = i < bv.count ? bv[i] : 0
            if ai != bi { return ai > bi }
        }
        return false
    }
}
