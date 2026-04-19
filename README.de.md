# Toms Clippy Light

Eine schlanke, native Clipboard-History-App für **macOS 26 Tahoe**. Lebt in der Menubar, speichert die letzten N kopierten Einträge (Text, Bilder, Dateien) und lässt dich jeden davon per globalem Tastenkürzel wieder einfügen.

🇬🇧 [English version](README.md)

## Features

- **Reine Menubar-App** — kein Dock-Icon, bleibt dir aus dem Weg
- **Einheitliche Historie**: Plain Text, Rich Text (RTF), Bilder, Datei-Referenzen
- **Globales Shortcut** (Default: `⇧⌘V`) öffnet die Historie aus jeder App
- **Auto-Paste** in das zuvor fokussierte Textfeld
- **Suche, Pinning, Dedup** — Clipboard-History wie sie sein sollte
- **Passwort-sensitiv**: respektiert `NSPasteboardTypeConcealed` — Einträge aus 1Password / Safari AutoFill landen nicht in der Historie
- **Zweisprachige UI**: Englisch + Deutsch, erkennt System-Sprache automatisch, in den Einstellungen überschreibbar
- **"Beim Anmelden starten"** (via `SMAppService`)
- **Optionale Persistenz** über Neustarts hinweg (JSON unter `~/Library/Application Support/TomsClippyLight/`)

## Screenshots

_Screenshots werden nach dem ersten Build ergänzt._

## Installation

Da die App **nicht signiert** ist (keine Apple Developer ID), setzt macOS sie standardmäßig in Quarantäne. Du musst das Quarantäne-Flag manuell entfernen.

### Schritt für Schritt

1. Lade das aktuelle `TomsClippyLight.zip` von der [Releases-Seite](https://github.com/tomschmidtdev/toms-clippy-light/releases).
2. Entpacke es und verschiebe `TomsClippyLight.app` nach `/Applications`.
3. Öffne das Terminal und führe aus:

   ```bash
   xattr -dr com.apple.quarantine /Applications/TomsClippyLight.app
   ```

   Alternativ das mitgelieferte Hilfs-Script:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/tomschmidtdev/toms-clippy-light/main/scripts/install.sh | bash
   ```

4. Starte die App.
5. Beim ersten Auto-Paste fragt macOS nach der **Bedienungshilfen**-Berechtigung. Erteile sie unter **Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen**.

## Konfiguration

Rechtsklick auf das Menubar-Icon → **Einstellungen…**

| Option | Default | Beschreibung |
|---|---|---|
| Beim Anmelden starten | aus | Auto-Start beim Mac-Login via `SMAppService` |
| Sprache | Automatisch | UI-Sprache überschreiben (Englisch / Deutsch) |
| Größe der Historie | 20 | Maximale Anzahl aktueller Einträge (1–100) |
| Historie persistent | aus | Historie über App-Neustarts behalten |
| Passwörter ignorieren | an | Einträge aus Passwort-Managern überspringen |
| History-Shortcut | ⇧⌘V | Historie global öffnen |

## Tastenkürzel

Drücke dein konfiguriertes Shortcut (Default `⇧⌘V`) in einer beliebigen App. Die History öffnet sich mit Suchfeld. Klicke auf einen Eintrag (oder drücke Enter auf dem ersten Treffer), um ihn in das Textfeld einzufügen, das gerade den Fokus hatte.

## Aus dem Quellcode bauen

Voraussetzungen: macOS 26 Tahoe, Xcode 26+, [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
git clone https://github.com/tomschmidtdev/toms-clippy-light.git
cd toms-clippy-light
make build        # oder: xcodegen generate && open TomsClippyLight.xcodeproj
```

### Make-Targets

| Target | Zweck |
|---|---|
| `make generate` | `.xcodeproj` aus `project.yml` (re-)generieren |
| `make build` | Debug-Build |
| `make test` | Unit- + UI-Tests laufen lassen |
| `make archive` | Unsigniertes Release-Archiv |
| `make zip` | Distributierbares `.zip` unter `build/` |

## Testing

Das Projekt nutzt **Swift Testing** für Unit-Tests und **XCUITest** für UI-Smoke-Tests. Core-Services nutzen Dependency-Injection über Protocol-Wrapper (`PasteboardProtocol`, `WorkspaceProtocol`, `KeyboardSimulating`, `LaunchAtLoginService`) — jede System-API ist durch ein Fake ersetzbar.

```bash
make test
```

## Release veröffentlichen

Einen Tag der Form `vX.Y.Z` pushen:

```bash
git tag v0.1.0
git push origin v0.1.0
```

GitHub Actions erledigt dann:
1. Unsigniertes `TomsClippyLight.app`-Archiv
2. Verpackung in `TomsClippyLight.zip`
3. SHA-256-Prüfsumme
4. GitHub-Release mit beiden Artefakten und Installationsanleitung

## Berechtigungen

| Berechtigung | Warum |
|---|---|
| **Bedienungshilfen** | Wird benötigt, um ⌘V in die zuvor fokussierte App zu simulieren, nachdem du einen Eintrag ausgewählt hast. macOS fragt beim ersten Auto-Paste automatisch nach. |

Die App fordert **keinen** Netzwerk-Zugriff, Full Disk Access oder andere erweiterte Berechtigungen an.

## Privatsphäre

- Clipboard-Inhalte bleiben lokal auf deinem Mac.
- Bei deaktivierter **Persistenz** (Default) wird nichts auf die Platte geschrieben.
- Bei aktivierter Persistenz wird die Historie unverschlüsselt in `~/Library/Application Support/TomsClippyLight/history.json` gespeichert.
- Einträge aus Passwort-Managern (Flag `NSPasteboardTypeConcealed`) werden standardmäßig ignoriert.

## Lizenz

[MIT](LICENSE) © 2026 Tom Schmidt
