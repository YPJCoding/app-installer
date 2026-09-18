.PHONY: build build-universal build-arm64 build-intel dmg-arm64 dmg-intel dmg-universal update-archive release-update publish-update run test verify clean

APP := build/universal/App Installer.app

build: build-universal

build-universal:
	./App/build.sh universal

build-arm64:
	./App/build.sh arm64

build-intel:
	./App/build.sh intel

dmg-arm64:
	./scripts/package-dmg.sh arm64

dmg-intel:
	./scripts/package-dmg.sh intel

dmg-universal:
	./scripts/package-dmg.sh universal

update-archive:
	./scripts/package-update.sh

release-update:
	./scripts/release-update.sh

publish-update:
	./scripts/publish-update.sh

run: build
	open "$(APP)"

test:
	swift build

verify: build
	plutil -lint "$(APP)/Contents/Info.plist"
	file "$(APP)/Contents/MacOS/AppInstaller"
	codesign --verify --deep --strict --verbose=4 "$(APP)"

clean:
	rm -rf .build build
