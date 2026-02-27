# ReadDown

A native macOS markdown reader with tabbed documents, syntax highlighting, mermaid diagrams, and IDE-inspired themes.

## Features

- **Tabbed interface** — open multiple `.md` files as tabs in a single window, with remembered window size
- **Full GFM rendering** — tables, task lists, fenced code blocks, and more via marked.js
- **Syntax highlighting** — code blocks rendered with language-aware colors via highlight.js
- **Mermaid diagrams** — renders mermaid code blocks as SVG diagrams
- **8 color themes** — GitHub Light/Dark, Dracula, One Dark, Nord, Solarized Light/Dark, Monokai
- **Local link navigation** — follow links to other `.md` files within the same tab, with back/forward history and scroll position memory
- **Find in document** — Cmd+F search with forward/backward navigation
- **Table of contents** — sidebar extracted from document headings, click to jump
- **Relative image rendering** — inline images with relative paths render correctly
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
  App/            — App entry point, menu commands, app delegate
  Models/         — Document model, theme definitions, navigation history
  Views/          — SwiftUI views, WKWebView wrapper
  Services/       — Theme manager, file watcher, link resolver
  Resources/      — HTML template, JS libraries, CSS themes
ReadDownTests/    — Unit tests (63 tests across 6 suites)
CLI/              — readdown command-line tool
Scripts/          — Build setup automation
```

## Development

```bash
make setup        # install XcodeGen, download JS deps, generate project
make generate     # regenerate Xcode project after changing project.yml
make build        # release build
make test         # run all unit tests
make install      # build + copy app to /Applications
make install-cli  # build + copy CLI to /usr/local/bin
make install-all  # both of the above
make clean        # remove build artifacts and generated project

open ReadDown.xcodeproj   # develop in Xcode (after setup)
```

### Releasing

Releases can be created manually or via CI:

```bash
# Manual: build, package, and publish to GitHub Releases
make release

# CI: push a version tag and GitHub Actions handles the rest
make bump-minor
git add -A && git commit -m "Bump to v$(cat VERSION)"
git tag "v$(cat VERSION)"
git push && git push --tags
```

### Versioning

Version is tracked in two files at the repo root:

- `VERSION` — semantic version (e.g. `1.2.0`), bumped via `make bump-major`, `make bump-minor`, or `make bump-patch`
- `BUILD_NUMBER` — auto-incremented on every build, reset on version bumps

### Debug Logging

Navigation and rendering events are logged via `os.Logger` (subsystem `com.readdown.app`). To watch live:

```bash
log stream --predicate 'subsystem == "com.readdown.app"' --level debug
```
