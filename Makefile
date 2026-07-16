SDKROOT := $(shell xcrun --show-sdk-path)
CC := xcrun clang
ARCHS := -arch arm64 -arch arm64e
DOCK_TARGET := build/libQOLDock.dylib
APPS_TARGET := build/libQOLAppKit.dylib
COMMON_SOURCE := Sources/Tweak/Common/QOLPreferences.m
DOCK_SOURCES := $(COMMON_SOURCE) Sources/Tweak/Common/QOLDockRuntime.m \
	Sources/Tweak/MusicPulse/QOLMusicPulseController.m
APPS_SOURCES := $(COMMON_SOURCE) Sources/Tweak/Common/QOLAppsRuntime.m \
	$(shell find Sources/Tweak/Cursor Sources/Tweak/SoftScrollEdges -name '*.m' -print)

.PHONY: all clean sign install rescan restart deploy

all: $(DOCK_TARGET) $(APPS_TARGET)

$(DOCK_TARGET): $(DOCK_SOURCES)
	@mkdir -p build
	$(CC) -dynamiclib -fobjc-arc -fblocks -fmodules -O2 $(ARCHS) -isysroot "$(SDKROOT)" \
		-I Sources/Tweak/Common -I Sources/Tweak/MusicPulse \
		-I Sources/Tweak/Cursor -I Sources/Tweak/SoftScrollEdges \
		-framework Foundation -framework AppKit -framework QuartzCore \
		-install_name @rpath/libQOLDock.dylib -o $@ $(DOCK_SOURCES)

$(APPS_TARGET): $(APPS_SOURCES)
	@mkdir -p build
	$(CC) -dynamiclib -fobjc-arc -fblocks -fmodules -O2 $(ARCHS) -isysroot "$(SDKROOT)" \
		-I Sources/Tweak/Common -I Sources/Tweak/Cursor -I Sources/Tweak/SoftScrollEdges \
		-framework Foundation -framework AppKit -framework QuartzCore \
		-install_name @rpath/libQOLAppKit.dylib -o $@ $(APPS_SOURCES)

clean:
	rm -rf build

sign: $(DOCK_TARGET) $(APPS_TARGET)
	codesign --force --sign - $(DOCK_TARGET)
	codesign --force --sign - $(APPS_TARGET)

install: sign
	rm -f /private/var/ammonia/core/tweaks/libQOL.dylib /private/var/ammonia/core/tweaks/libQOL.dylib.blacklist \
		/private/var/ammonia/core/tweaks/libQOLApps.dylib /private/var/ammonia/core/tweaks/libQOLApps.dylib.blacklist \
		/private/var/ammonia/core/tweaks/libQOLDock.dylib /private/var/ammonia/core/tweaks/libQOLDock.dylib.whitelist \
		/private/var/ammonia/core/tweaks/libQOLAppKit.dylib /private/var/ammonia/core/tweaks/libQOLAppKit.dylib.blacklist
	rm -f /private/var/ammonia/core/tweaks/libQOLDock-*.dylib /private/var/ammonia/core/tweaks/libQOLDock-*.dylib.whitelist \
		/private/var/ammonia/core/tweaks/libQOLAppKit-*.dylib /private/var/ammonia/core/tweaks/libQOLAppKit-*.dylib.blacklist
	@dock_hash=$$(shasum -a 256 $(DOCK_TARGET) | cut -c1-12); \
		cp $(DOCK_TARGET) /private/var/ammonia/core/tweaks/libQOLDock-$$dock_hash.dylib; \
		cp libQOLDock.dylib.whitelist /private/var/ammonia/core/tweaks/libQOLDock-$$dock_hash.dylib.whitelist
	@app_hash=$$(shasum -a 256 $(APPS_TARGET) | cut -c1-12); \
		cp $(APPS_TARGET) /private/var/ammonia/core/tweaks/libQOLAppKit-$$app_hash.dylib; \
		cp libQOLAppKit.dylib.blacklist /private/var/ammonia/core/tweaks/libQOLAppKit-$$app_hash.dylib.blacklist

restart:
	killall Dock || true

rescan:
	launchctl kickstart -k system/com.bedtime.ammonia

deploy: install rescan restart
