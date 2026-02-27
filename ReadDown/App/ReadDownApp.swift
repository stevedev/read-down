import SwiftUI

@main
struct ReadDownApp: App {
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
