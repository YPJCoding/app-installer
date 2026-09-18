.PHONY: build dmg update-archive publish-update run test verify clean

APP := build/App Installer.app

build:
	./App/build.sh

dmg:
	./scripts/package-dmg.sh

update-archive:
	./scripts/package-update.sh

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
