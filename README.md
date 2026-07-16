# QOL

QOL is a multi-feature quality-of-life tweak for macOS. It currently contains:

- Music Pulse: concentric red rings emitted from the Music Dock icon while Apple Music is playing.
- Command Lens: hold Command to reveal shortcut and action labels over visible AppKit controls.
- App Capsule: replaces the application menu title with an icon-bearing capsule that reflects the active document and unsaved state.

The tweak is organized by feature under `Sources/Tweak`. Its settings app is a separate SwiftUI Xcode project under `SettingsApp`. Ammonia receives two internal components: a Dock-whitelisted dylib and an ordinary-app dylib. Both are one QOL product and share the same settings suite.

## Build

```sh
make
xcodebuild -project SettingsApp/QOLSettings.xcodeproj -scheme QOLSettings -configuration Release build
```

## Install the tweak

```sh
make deploy
```

The install target copies content-hashed Dock and AppKit components into Ammonia's tweak directory, rescans Ammonia, then restarts Dock. Content-hashed filenames prevent Ammonia from reusing a stale trust registration after a rebuild. Relaunch ordinary applications to load Command Lens and App Capsule into them.
