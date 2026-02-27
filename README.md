# ReadDown

A native macOS markdown reader with tabbed documents, mermaid diagrams, and IDE-inspired themes.

## Features

- **Tabbed interface** — open multiple `.md` files as tabs in a single window
- **Full GFM rendering** — tables, task lists, fenced code blocks, and more via marked.js
- **Mermaid diagrams** — renders mermaid code blocks as SVG diagrams
- **8 color themes** — GitHub Light/Dark, Dracula, One Dark, Nord, Solarized Light/Dark, Monokai
- **Local link navigation** — follow links to other `.md` files within the same tab, with back/forward history
- **Live file watching** — auto-reloads when the file changes on disk
- **Copy as markdown or rich text** — right-click for markdown, default copy for rich text
- **CLI tool** — `readdown file.md` opens files from the terminal
- **macOS `open` integration** — `open file.md` launches ReadDown when set as default

## Install

### Download (recommended)

Grab the latest `.zip` from [Releases](https://github.com/stevedev/read-down/releases), unzip, and drag **ReadDown.app** to `/Applications`.

### Build from source

Requires macOS 14.0+, Xcode 15+, and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```bash
make setup        # download JS deps + generate Xcode project
make install-all  # build and install app + CLI
```

## Usage

### From Terminal

```bash
# Using the CLI tool
readdown README.md
readdown doc1.md doc2.md

# Using macOS open command (after setting as default handler)
open README.md
```

### Keyboard Shortcuts

| Action          | Shortcut          |
|-----------------|-------------------|
| Back            | Cmd + [           |
| Forward         | Cmd + ]           |
| Find            | Cmd + F           |
| Theme 1-8       | Ctrl + Cmd + 1-8  |

## Adding a New Theme

1. Create a CSS file in `ReadDown/Resources/themes/` using the CSS custom property pattern from existing themes
2. Add a case to the `Theme` enum in `ReadDown/Models/Theme.swift`
3. Rebuild

## Project Structure

```
ReadDown/
  App/            — App entry point, menu commands
  Models/         — Document model, theme definitions, navigation history
  Views/          — SwiftUI views, WKWebView wrapper
  Services/       — Theme manager, file watcher
  Resources/      — HTML template, JS libraries, CSS themes
CLI/              — readdown command-line tool
Scripts/          — Build setup automation
```

## Development

```bash
# Generate/regenerate Xcode project after changing project.yml
make generate

# Open in Xcode
open ReadDown.xcodeproj

# Clean build artifacts
make clean
```
