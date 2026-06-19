MAKE_CONFIG_FILE = config.mk

-include $(MAKE_CONFIG_FILE)

FLATPAK_USER ?= true
FLATPAK_REF_BRANCH ?= stable
FLATPAK_SDK_BRANCH ?= 25.08

FLATPAK_APP_DIR ?= app
FLATPAK_RUNTIME_DIR ?= runtime
FLATPAK_BUILD_DIR ?= build
FLATPAK_ARTIFACTS_DIR ?= artifacts
FLATPAK_REPO_DIR ?= $(FLATPAK_ARTIFACTS_DIR)/repo

FLATPAK_BUILDER_VERBOSE ?= false
FLATPAK_INSTALL_FLAGS ?= --assumeyes --or-update

FLATPAK_REFS := $(filter-out %.disabled,$(patsubst %/,%,$(wildcard $(FLATPAK_APP_DIR)/*/ $(FLATPAK_RUNTIME_DIR)/*/)))

ifneq ($(FLATPAK_USER), true)
override undefine FLATPAK_USER
endif

ifneq ($(FLATPAK_BUILDER_VERBOSE), true)
override undefine FLATPAK_BUILDER_VERBOSE
endif

.PHONY: all
all: requirements bundle

.PHONY: requirements
requirements: | org.freedesktop.Platform org.freedesktop.Sdk org.flatpak.Builder

.PHONY: clean
clean: $(foreach ref,$(FLATPAK_REFS),$(ref)-clean)
	$(RM) --recursive $(FLATPAK_REPO_DIR)

.PHONY: distclean
distclean: clean
	$(RM) --recursive $(FLATPAK_ARTIFACTS_DIR) .flatpak-builder/

.PHONY: export
export: $(foreach ref,$(FLATPAK_REFS),$(ref)-export)

.PHONY: bundle
bundle: $(foreach ref,$(FLATPAK_REFS),$(FLATPAK_ARTIFACTS_DIR)/$(shell echo $(ref) | sed 's,^.\+/,,')-$(FLATPAK_REF_BRANCH).flatpak)

.PHONY: install
install: $(foreach ref,$(FLATPAK_REFS),$(ref)-install)

.PHONY: builder-export
builder-export: $(foreach ref,$(FLATPAK_REFS),$(ref)-builder-export)

.PHONY: builder-install
builder-install: $(foreach ref,$(FLATPAK_REFS),$(ref)-builder-install)

.PHONY: flathub
flathub:
	flatpak remote-add --if-not-exists $@ https://dl.flathub.org/repo/flathub.flatpakrepo

.PHONY: org.freedesktop.Platform org.freedesktop.Sdk
org.freedesktop.Platform org.freedesktop.Sdk: flathub
	flatpak install $(FLATPAK_INSTALL_FLAGS) $@//$(FLATPAK_SDK_BRANCH)

.PHONY: org.flatpak.Builder
org.flatpak.Builder: flathub
	flatpak install $(FLATPAK_INSTALL_FLAGS) $@

$(FLATPAK_REPO_DIR):
	mkdir --parents $@

define REF_RULE_GENERATOR
.PHONY: $(1)-clean
$(1)-clean:
	$(RM) --recursive $(1)/$(FLATPAK_BUILD_DIR)

.PHONY: $(1)-build
$(1)-build:
	flatpak run org.flatpak.Builder $(if $(FLATPAK_BUILDER_VERBOSE),--verbose) \
		--build-only --force-clean $(1)/$(FLATPAK_BUILD_DIR) $(1)/$$(patsubst %-build,%,$$(@F)).yaml

.PHONY: $(1)-finish
$(1)-finish: $(1)-build
	flatpak run org.flatpak.Builder $(if $(FLATPAK_BUILDER_VERBOSE),--verbose) \
		--finish-only $(1)/$(FLATPAK_BUILD_DIR) $(1)/$$(patsubst %-finish,%,$$(@F)).yaml

.PHONY: $(1)-export
$(1)-export: $(1)-finish | $(FLATPAK_REPO_DIR)
	flatpak build-export $(FLATPAK_REPO_DIR) $(1)/$(FLATPAK_BUILD_DIR) $(FLATPAK_REF_BRANCH)

$(FLATPAK_ARTIFACTS_DIR)/$(shell echo $(1) | sed 's,^.\+/,,')-$(FLATPAK_REF_BRANCH).flatpak:\
	RUNTIME := $(if $(findstring runtime/,$(1)),true)
$(FLATPAK_ARTIFACTS_DIR)/$(shell echo $(1) | sed 's,^.\+/,,')-$(FLATPAK_REF_BRANCH).flatpak: $(1)-export
	flatpak build-bundle $(FLATPAK_REPO_DIR) $$(if $$(RUNTIME),--runtime) $$@ \
		$(shell echo $(1) | sed 's,^.\+/,,') $(FLATPAK_REF_BRANCH)

.PHONY: $(1)-install
$(1)-install: $(FLATPAK_ARTIFACTS_DIR)/$(shell echo $(1) | sed 's,^.\+/,,')-$(FLATPAK_REF_BRANCH).flatpak
	flatpak install $(if $(FLATPAK_USER),--user) $(FLATPAK_INSTALL_FLAGS) $$<

.PHONY: $(1)-builder-export
$(1)-builder-export: | $(FLATPAK_REPO_DIR)
	flatpak run org.flatpak.Builder $(if $(FLATPAK_BUILDER_VERBOSE),--verbose) \
		--repo=$(FLATPAK_REPO_DIR) --force-clean $(1)/$(FLATPAK_BUILD_DIR) \
		$(1)/$$(patsubst %-builder-export,%,$$(@F)).yaml

.PHONY: $(1)-builder-install
$(1)-builder-install: | $(FLATPAK_REPO_DIR)
	flatpak run org.flatpak.Builder $(if $(FLATPAK_BUILDER_VERBOSE),--verbose) \
	--repo=$(FLATPAK_REPO_DIR) --force-clean --install $(if $(FLATPAK_USER),--user) \
	$(1)/$(FLATPAK_BUILD_DIR) $(1)/$$(patsubst %-builder-install,%,$$(@F)).yaml
endef

$(foreach ref,$(FLATPAK_REFS),$(eval $(call REF_RULE_GENERATOR,$(ref))))
