import UIKit
import UniformTypeIdentifiers

/// The "Just The Crumbs" entry in the iOS share sheet.
///
/// iOS only lists an app in the share sheet if it ships a share extension, so
/// this target exists purely to catch the link TikTok (or Safari, or Instagram)
/// hands over and pass it to the app. It shows no UI of its own: it pulls the
/// URL out of the shared item and reopens the host app on
/// `justthecrumbs://import?text=<shared text>`, which `main.dart` already
/// listens for and routes to the import screen.
///
/// Nothing is written to disk, so the extension needs no App Group — the whole
/// payload rides in the deep link.
class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // No UI: the extension is a redirect, so stay invisible over whatever
        // the user was looking at rather than flashing an empty sheet.
        view.backgroundColor = .clear
        extractSharedText { [weak self] text in
            DispatchQueue.main.async { self?.finish(with: text) }
        }
    }

    /// Reads the first URL (or failing that, the first plain-text item) out of
    /// the share. TikTok attaches both — a `public.url` and a caption string —
    /// so URLs are tried first and the text is only a fallback for apps that
    /// share a bare "look at this https://…" string.
    private func extractSharedText(_ completion: @escaping (String?) -> Void) {
        let attachments = (extensionContext?.inputItems as? [NSExtensionItem] ?? [])
            .flatMap { $0.attachments ?? [] }

        let urlType = UTType.url.identifier
        let textType = UTType.plainText.identifier

        guard
            let provider = attachments.first(where: {
                $0.hasItemConformingToTypeIdentifier(urlType)
            }) ?? attachments.first(where: {
                $0.hasItemConformingToTypeIdentifier(textType)
            })
        else {
            completion(nil)
            return
        }

        let type = provider.hasItemConformingToTypeIdentifier(urlType) ? urlType : textType
        provider.loadItem(forTypeIdentifier: type, options: nil) { item, _ in
            switch item {
            case let url as URL: completion(url.absoluteString)
            case let text as String: completion(text)
            case let data as Data: completion(String(data: data, encoding: .utf8))
            default: completion(nil)
            }
        }
    }

    private func finish(with text: String?) {
        if let text, !text.isEmpty,
           var components = URLComponents(string: "justthecrumbs://import") {
            components.queryItems = [URLQueryItem(name: "text", value: text)]
            if let url = components.url { openHostApp(url) }
        }
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    /// Opens a URL from inside an app extension.
    ///
    /// `UIApplication.shared` is off-limits in extensions, so we walk up the
    /// responder chain until we reach the application object and send it the
    /// (long-deprecated but still live) `openURL:` message. This is the standard
    /// share-extension redirect — the same one `receive_sharing_intent` and
    /// friends use.
    private func openHostApp(_ url: URL) {
        let selector = sel_registerName("openURL:")
        var responder: UIResponder? = self
        while let current = responder {
            if let application = current as? UIApplication,
               application.responds(to: selector) {
                application.perform(selector, with: url)
                return
            }
            responder = current.next
        }
    }
}
