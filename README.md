# Toms Clippy Light

A lightweight, native clipboard history app for **macOS 26 Tahoe**. Lives in the menubar, stores the last N items you copied (text, images, files), and lets you paste any of them back with a global shortcut.

🇩🇪 [Deutsche Version](README.de.md)

## Features

- **Menubar-only app** — no Dock icon, stays out of your way
- **Unified clipboard history**: plain text, rich text (RTF), images, and file references
- **Global shortcut** (default: `⇧⌘V`) to open the history popover from any app
- **Auto-paste** into the previously focused text field
- **Search, pin favorites, deduplicate** — clipboard history done right
- **Password-aware**: respects `NSPasteboardTypeConcealed`, so 1Password / Safari AutoFill entries don't leak into history
- **Bilingual UI**: English + German, auto-detects from system, overridable in settings
- **Launch at login** toggle (`SMAppService`)
- **Optional persistence** across restarts (JSON in `~/Library/Application Support/TomsClippyLight/`)

## Screenshots

_Screenshots to be added after first build._

## Installation

Since this app is **unsigned** (no Apple Developer ID), macOS will quarantine it by default. You need to remove the quarantine flag manually.

### Step-by-step

1. Download the latest `TomsClippyLight.zip` from the [Releases page](https://github.com/tomschmidtdev/toms-clippy-light/releases).
2. Unzip and move `TomsClippyLight.app` to `/Applications`.
3. Open Terminal and run:

   ```bash
   xattr -d com.apple.quarantine /Applications/TomsClippyLight.app
   ```

   Alternatively, use the bundled helper:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/tomschmidtdev/toms-clippy-light/main/scripts/install.sh | bash
   ```

4. Launch the app.
5. On your first paste via the history, macOS will ask for **Accessibility** permission. Grant it under **System Settings → Privacy & Security → Accessibility**.

## Configuration

Right-click the menubar icon, choose **Settings…**.

| Option | Default | Description |
|---|---|---|
| Launch at login | off | Auto-start with your Mac via `SMAppService` |
| Language | Automatic | Override UI language (English / German) |
| History size | 20 | Max number of recent entries (1–100) |
| Persist history | off | Keep history across app restarts |
| Ignore passwords | on | Skip entries flagged by password managers |
| Show history shortcut | ⇧⌘V | Open history popover globally |

## Keyboard shortcut

Press your configured shortcut (default `⇧⌘V`) in any application. The history popover appears with a search field. Click an entry (or press Enter on the first match) to paste it back into the text field you just had focused.

## Build from source

Requirements: macOS 26 Tahoe, Xcode 26+, [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
git clone https://github.com/tomschmidtdev/toms-clippy-light.git
cd toms-clippy-light
make build        # or: xcodegen generate && open TomsClippyLight.xcodeproj
```

### Make targets

| Target | Purpose |
|---|---|
| `make generate` | Regenerate `.xcodeproj` from `project.yml` |
| `make build` | Debug build |
| `make test` | Run unit + UI tests |
| `make archive` | Release archive (signed with Apple Development cert if available, otherwise ad-hoc) |
| `make install` | `archive` + copy `.app` to `/Applications` |
| `make zip` | Distributable `.zip` under `build/` |
| `make release-local` | Same as `zip`, prints artifact path |
| `make clean` | Remove `build/`, `DerivedData/`, generated `.xcodeproj` |

## Testing

The project uses **Swift Testing** for unit tests and **XCUITest** for UI smoke tests. Core services use dependency-injected protocol wrappers (`PasteboardProtocol`, `WorkspaceProtocol`, `KeyboardSimulating`, `LaunchAtLoginService`) so every system API is replaceable with a fake.

```bash
make test
```

## Releasing

Push a tag of the form `vX.Y.Z`:

```bash
git tag v0.1.0
git push origin v0.1.0
```

GitHub Actions will:
1. Archive an unsigned `TomsClippyLight.app`
2. Package it into `TomsClippyLight.zip`
3. Compute its SHA-256
4. Create a GitHub Release with both artifacts and installation instructions

## Permissions

| Permission | Why |
|---|---|
| **Accessibility** | Needed to simulate ⌘V against the previously focused app after you pick an entry. macOS will prompt the first time you try to auto-paste. |

The app does **not** request network access, full disk access, or any other elevated permissions.

## Privacy

- Clipboard contents stay local to your Mac.
- With **Persist history** disabled (default), nothing touches disk.
- With it enabled, history is stored unencrypted in `~/Library/Application Support/TomsClippyLight/history.json`.
- Password manager entries (flagged with `NSPasteboardTypeConcealed`) are ignored by default.

## License

[MIT](LICENSE) © 2026 Tom Schmidt
