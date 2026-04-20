.PHONY: all generate build test clean archive zip install release-local help

SCHEME := TomsClippyLight
PROJECT := TomsClippyLight.xcodeproj
CONFIG := Release
ARCHIVE := build/$(SCHEME).xcarchive
APP := build/$(SCHEME).app
ZIP := build/$(SCHEME).zip

# Auto-detect Apple Development cert SHA1 for local builds; falls back to ad-hoc.
SIGN_SHA := $(shell security find-identity -v -p codesigning 2>/dev/null \
              | grep "Apple Development" | head -1 | awk '{print $$2}')
ifeq ($(SIGN_SHA),)
  SIGN_SHA := -
  SIGN_FLAGS := CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=YES
else
  SIGN_FLAGS := CODE_SIGN_IDENTITY="$(SIGN_SHA)" CODE_SIGN_STYLE=Manual \
                CODE_SIGNING_REQUIRED=YES CODE_SIGNING_ALLOWED=YES \
                PROVISIONING_PROFILE_SPECIFIER=""
endif

all: generate build

generate: ## Regenerate .xcodeproj from project.yml (requires xcodegen)
	xcodegen generate

build: generate ## Debug build
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug build \
	  $(SIGN_FLAGS) | xcbeautify || true

test: generate ## Run unit and UI tests
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination 'platform=macOS' test \
	  $(SIGN_FLAGS)

archive: generate ## Archive Release build (signed if Apple Development cert found)
	xcodebuild archive \
	  -project $(PROJECT) \
	  -scheme $(SCHEME) \
	  -configuration $(CONFIG) \
	  -archivePath $(ARCHIVE) \
	  $(SIGN_FLAGS)

install: archive ## Build Release archive and install to /Applications
	cp -Rf $(ARCHIVE)/Products/Applications/$(SCHEME).app /Applications/
	@echo "Installed to /Applications/$(SCHEME).app"

zip: archive ## Create distributable .zip
	cp -R $(ARCHIVE)/Products/Applications/$(SCHEME).app $(APP)
	cd build && zip -yr $(SCHEME).zip $(SCHEME).app

release-local: zip ## Full local release artifact
	@echo "Release artifact: $(ZIP)"

clean: ## Remove build artifacts and generated project
	rm -rf build/ DerivedData/ $(PROJECT)

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
