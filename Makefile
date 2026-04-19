.PHONY: all generate build test clean archive zip release-local help

SCHEME := TomsClippyLight
PROJECT := TomsClippyLight.xcodeproj
CONFIG := Release
ARCHIVE := build/$(SCHEME).xcarchive
APP := build/$(SCHEME).app
ZIP := build/$(SCHEME).zip

all: generate build

generate: ## Regenerate .xcodeproj from project.yml (requires xcodegen)
	xcodegen generate

build: generate ## Debug build
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug build | xcbeautify || true

test: generate ## Run unit and UI tests
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination 'platform=macOS' test

archive: generate ## Archive unsigned Release build
	xcodebuild archive \
	  -project $(PROJECT) \
	  -scheme $(SCHEME) \
	  -configuration $(CONFIG) \
	  -archivePath $(ARCHIVE) \
	  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

zip: archive ## Create distributable .zip
	cp -R $(ARCHIVE)/Products/Applications/$(SCHEME).app $(APP)
	cd build && zip -yr $(SCHEME).zip $(SCHEME).app

release-local: zip ## Full local release artifact
	@echo "Release artifact: $(ZIP)"

clean: ## Remove build artifacts and generated project
	rm -rf build/ DerivedData/ $(PROJECT)

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
