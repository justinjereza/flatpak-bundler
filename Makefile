FLATPAK_APP_BRANCH ?= stable
FLATPAK_PLATFORM_BRANCH = 25.08
FLATPAK_APP_MAKEFILE = Makefile.application

# FLATPAK_APPS = $(patsubst %/,%,$(wildcard */))
FLATPAK_APPS = $(filter-out $(FLATPAK_ARTIFACTS_DIR) %.disabled,$(patsubst %/,%,$(wildcard */)))

FLATPAK_ARTIFACTS_DIR ?= artifacts
FLATPAK_REPO_DIR ?= $(FLATPAK_ARTIFACTS_DIR)/repo
FLATPAK_INSTALL_FLAGS ?= --assumeyes --or-update

export FLATPAK_BUILD_DIR ?= build

.PHONY: all
all: flatpak-prerequisites bundle

.PHONY: clean
clean: $(foreach app,$(FLATPAK_APPS),$(app)-clean)
# 	$(RM) --recursive $(FLATPAK_REPO_DIR)

.PHONY: distclean
distclean: clean
	$(RM) --recursive $(FLATPAK_ARTIFACTS_DIR)

.PHONY: export
export: $(foreach app,$(FLATPAK_APPS),$(app)-export)

.PHONY: bundle
bundle: export $(foreach app,$(FLATPAK_APPS),$(FLATPAK_ARTIFACTS_DIR)/$(app).flatpak)

.PHONY: flatpak-prerequisites
flatpak-prerequisites: flathub org.freedesktop.Platform org.freedesktop.Sdk org.flatpak.Builder

.PHONY: flathub
flathub:
	flatpak remote-add --if-not-exists $@ https://dl.flathub.org/repo/flathub.flatpakrepo

.PHONY: org.freedesktop.Platform org.freedesktop.Sdk
org.freedesktop.Platform org.freedesktop.Sdk:
	flatpak install $(FLATPAK_INSTALL_FLAGS) $@//$(FLATPAK_PLATFORM_BRANCH)

.PHONY: org.flatpak.Builder
org.flatpak.Builder:
	flatpak install $(FLATPAK_INSTALL_FLAGS) $@

$(FLATPAK_ARTIFACTS_DIR):
	mkdir $(FLATPAK_ARTIFACTS_DIR)

define APP_RULE_GENERATOR
.PHONY: $(1)/Makefile
$(1)/Makefile:
	ln --force --symbolic ../$(FLATPAK_APP_MAKEFILE) $$@

.PHONY: $(1)
$(1): export FLATPAK_APP = $(1)
$(1): $(1)/Makefile
	$(MAKE) --directory=$$@

.PHONY: $(1)-clean
$(1)-clean: export FLATPAK_APP = $(1)
$(1)-clean: $(1)/Makefile
	$(MAKE) --directory=$(1) clean
	$(RM) $$<

.PHONY: $(1)-export
$(1)-export: $(1) $(FLATPAK_ARTIFACTS_DIR)
	flatpak build-export $(FLATPAK_REPO_DIR) $(1)/$(FLATPAK_BUILD_DIR) $(FLATPAK_APP_BRANCH)

$(FLATPAK_ARTIFACTS_DIR)/$(1).flatpak: $(1)-export
	flatpak build-bundle $(FLATPAK_REPO_DIR) $$@ $(1) $(FLATPAK_APP_BRANCH)
endef

$(foreach app,$(FLATPAK_APPS),$(eval $(call APP_RULE_GENERATOR,$(app))))
