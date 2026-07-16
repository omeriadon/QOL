# QOL

> [!WARNING]
> Using this plugin requires Ammonia, which is a modern macOS tweak loader and code injection engine. Installing Ammonia requires disabling SIP and other security options, so only install this if you know what you are doing.1

QOL is a multi-feature quality-of-life tweak for macOS. It currently contains:

- Music Pulse: a fixed red border matching the Music Dock icon appears during Apple Music playback.
- Cursor: a static rounded-rectangle replacement for the standard AppKit arrow with configurable size, corner radius, fill, opacity, and outline.
- Folder Look: injects into Finder and replaces the folder icons with an image you choose.
- Soft Scroll Edges: installs at application startup and redirects AppKit and SwiftUI hard or automatic scroll-edge effects to the soft style.

The tweak is organized by feature under `Sources/Tweak`. Its settings app is a separate SwiftUI Xcode project under `SettingsApp`. Ammonia receives two internal components: a Dock-whitelisted dylib and an ordinary-AppKit/Finder dylib. Both are one QOL product and share the same settings suite.

## Build

```sh
make
xcodebuild -project SettingsApp/QOLSettings.xcodeproj -scheme QOLSettings -configuration Release build
```

## Install the tweak

```sh
make deploy
```

The install target copies content-hashed Dock and AppKit components into Ammonia's tweak directory, rescans Ammonia, then restarts Dock. Content-hashed filenames prevent Ammonia from reusing a stale trust registration after a rebuild. Cursor and Soft Scroll Edges install automatically when an AppKit application starts, so restart applications to take effect. Once installed, cursors can be changed live.
