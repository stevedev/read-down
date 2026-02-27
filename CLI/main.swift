import Foundation

func main() {
    let args = CommandLine.arguments

    guard args.count > 1 else {
        printUsage()
        exit(1)
    }

    let command = args[1]

    if command == "--help" || command == "-h" {
        printUsage()
        exit(0)
    }

    let filePaths = Array(args.dropFirst())

    for path in filePaths {
        let url: URL
        if path.hasPrefix("/") {
            url = URL(fileURLWithPath: path)
        } else {
            let cwd = FileManager.default.currentDirectoryPath
            url = URL(fileURLWithPath: cwd).appendingPathComponent(path)
        }

        let resolved = url.standardized

        guard FileManager.default.fileExists(atPath: resolved.path) else {
            fputs("readdown: no such file: \(path)\n", stderr)
            continue
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "ReadDown", resolved.path]

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            fputs("readdown: failed to open \(path): \(error.localizedDescription)\n", stderr)
        }
    }
}

func printUsage() {
    let usage = """
    Usage: readdown <file.md> [file2.md ...]

    Opens markdown files in ReadDown.

    Options:
      -h, --help    Show this help message
    """
    print(usage)
}

main()
