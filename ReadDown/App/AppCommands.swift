import SwiftUI

struct AppCommands: Commands {
    @Bindable var themeManager = ThemeManager.shared

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About ReadDown") {
                let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
                let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
                NSApplication.shared.orderFrontStandardAboutPanel(options: [
                    .applicationName: "ReadDown",
                    .applicationVersion: version,
                    .version: build,
                    .credits: NSAttributedString(
                        string: "A native macOS markdown reader with GFM support, mermaid diagrams, and IDE-inspired themes.",
                        attributes: [
                            .font: NSFont.systemFont(ofSize: 11),
                            .foregroundColor: NSColor.secondaryLabelColor
                        ]
                    )
                ])
            }
        }

        CommandMenu("Theme") {
            ForEach(Theme.allCases) { theme in
                Button(theme.displayName) {
                    themeManager.current = theme
                }
                .keyboardShortcut(shortcut(for: theme))
            }
        }

        CommandGroup(after: .toolbar) {
            Button("Back") {
                NotificationCenter.default.post(name: .navigateBack, object: nil)
            }
            .keyboardShortcut("[", modifiers: .command)

            Button("Forward") {
                NotificationCenter.default.post(name: .navigateForward, object: nil)
            }
            .keyboardShortcut("]", modifiers: .command)
        }

        CommandGroup(after: .textEditing) {
            Button("Find...") {
                NotificationCenter.default.post(name: .toggleFind, object: nil)
            }
            .keyboardShortcut("f", modifiers: .command)
        }
    }

    private func shortcut(for theme: Theme) -> KeyboardShortcut? {
        switch theme {
        case .githubLight: KeyboardShortcut("1", modifiers: [.command, .control])
        case .githubDark: KeyboardShortcut("2", modifiers: [.command, .control])
        case .dracula: KeyboardShortcut("3", modifiers: [.command, .control])
        case .oneDark: KeyboardShortcut("4", modifiers: [.command, .control])
        case .nord: KeyboardShortcut("5", modifiers: [.command, .control])
        case .solarizedLight: KeyboardShortcut("6", modifiers: [.command, .control])
        case .solarizedDark: KeyboardShortcut("7", modifiers: [.command, .control])
        case .monokai: KeyboardShortcut("8", modifiers: [.command, .control])
        }
    }
}

extension Notification.Name {
    static let navigateBack = Notification.Name("com.readdown.navigateBack")
    static let navigateForward = Notification.Name("com.readdown.navigateForward")
    static let toggleFind = Notification.Name("com.readdown.toggleFind")
}
