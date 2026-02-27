import SwiftUI

struct AppCommands: Commands {
    @Bindable var themeManager = ThemeManager.shared

    var body: some Commands {
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
}
