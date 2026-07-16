# QOL

QOL is a multi-feature quality-of-life tweak for macOS. It currently contains:

- Music Pulse: a fixed red border matching the Music Dock icon appears during Apple Music playback.
- Cursor: a static rounded-rectangle replacement for the standard AppKit arrow with configurable size, corner radius, fill, opacity, and outline.
- Folder Look: documents the protected system resources used for Finder's default folder art.
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

The install target copies content-hashed Dock and AppKit components into Ammonia's tweak directory, rescans Ammonia, then restarts Dock. Content-hashed filenames prevent Ammonia from reusing a stale trust registration after a rebuild. Cursor and Soft Scroll Edges install automatically when an ordinary AppKit application starts.

## Folder icon source

macOS stores the generic folder sources at:

- `/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericFolderIcon.icns`
- `/System/Library/CoreServices/IconsetResources.bundle/Contents/Resources/Folder_*.png`

These resources are on the sealed system volume and are served through IconServices caches. QOL leaves them untouched. Finder's private icon pipeline is not hooked because doing so is not a stable arm64e customization point.
