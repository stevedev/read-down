import SwiftUI

@main
struct ReadDownApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        DocumentGroup(viewing: MarkdownDocument.self) { file in
            ContentView(
                document: file.$document,
                fileURL: file.fileURL
            )
            .frame(minWidth: 600, minHeight: 400)
        }
        .commands {
            AppCommands()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: ["AppleWindowTabbingMode": "always"])
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey(_:)),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )
    }

    @objc private func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              window.frameAutosaveName.isEmpty else { return }
        window.setFrameAutosaveName("ReadDownDocumentWindow")
    }
}
