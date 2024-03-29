## Variables accepted
#
# KEEP_IMAGES - to avoid cleaning up container images locally
#
##

# If SKU is not defined, default to mitaka
ifndef CONTRAIL_SKU
	export CONTRAIL_SKU := mitaka
endif

ifndef CONTRAIL_REPO_PORT
	export CONTRAIL_REPO_PORT := 1567
endif

ifndef CONTRAIL_REPO_IP
	export CONTRAIL_REPO_IP := $(shell ifconfig docker0 | awk '/inet.addr:/ {print $$2}' | cut -f2 -d:)
endif

ifndef SSHUSER
	export SSHUSER := root
endif

# Define all containers to be built
CONTAINERS = controller

# CONTRAIL_VERSION is requisite so fail, if not provided
ifndef CONTRAIL_VERSION
$(error CONTRAIL_VERSION is undefined)
endif

CONTAINER_TARS = $(CONTAINERS:%=contrail-%-$(CONTRAIL_VERSION).tar.gz)

CONTRAIL_INSTALL_PACKAGE_TAR = contrail-install-packages_$(CONTRAIL_VERSION)-$(CONTRAIL_SKU).tgz

CONTRAIL_REPO_CONTAINER = contrail-apt-repo
CONTRAIL_REPO_CONTAINER_TAR = $(CONTRAIL_REPO_CONTAINER)-$(CONTRAIL_VERSION).tar.gz

# This is the default target which should build all containers
.PHONY: all

all: $(CONTAINER_TARS)
	@echo "Building containers finished"

$(CONTAINER_TARS): $(CONTRAIL_REPO_CONTAINER_TAR)
	$(eval CONTAINER := $(subst -$(CONTRAIL_VERSION).tar.gz,,$@))
	$(eval CONTAINER_NAME := $(subst contrail-,,$(subst -$(CONTRAIL_VERSION).tar.gz,,$@)))
	@echo "Building the container $(CONTAINER):$(CONTRAIL_VERSION)"
	cp docker/common.sh docker/pyj2.py docker/$(CONTAINER_NAME)/
	cd docker/$(CONTAINER_NAME); \
	docker build --build-arg CONTRAIL_REPO_URL=http://$(CONTRAIL_REPO_IP):$(CONTRAIL_REPO_PORT) \
		-t $(CONTAINER):$(CONTRAIL_VERSION) .
	@echo "Saving the container $(CONTAINER):$(CONTRAIL_VERSION)"
	docker save $(CONTAINER):$(CONTRAIL_VERSION) | gzip -c > $@

.PHONY: prep

prep: $(CONTRAIL_REPO_CONTAINER_TAR)
	@echo "Preparation for container build is completed"

$(CONTRAIL_REPO_CONTAINER_TAR): $(CONTRAIL_INSTALL_PACKAGE)
	@echo "Pre-build step:"
	$(eval CONTRAIL_REPO_BUILD_ARGS := )
ifdef CONTRAIL_INSTALL_PACKAGE_TAR_URL
	$(eval CONTRAIL_REPO_BUILD_ARGS +=  --build-arg CONTRAIL_INSTALL_PACKAGE_TAR_URL=$(CONTRAIL_INSTALL_PACKAGE_TAR_URL) )
else
	$(error CONTRAIL_INSTALL_PACKAGE_TAR_URL is undefined)
endif

ifdef SSHPASS
	$(eval CONTRAIL_REPO_BUILD_ARGS += --build-arg SSHPASS=$(SSHPASS) )
endif

ifdef SSHUSER
	$(eval CONTRAIL_REPO_BUILD_ARGS += --build-arg SSHUSER=$(SSHUSER))
endif

	@echo "Building Contrail repo container"
	cd docker/contrail_repo/; \
	docker build $(CONTRAIL_REPO_BUILD_ARGS) \
		-t $(CONTRAIL_REPO_CONTAINER):$(CONTRAIL_VERSION) .
	@echo "Starting contrail repo container"
	docker run -d -p $(CONTRAIL_REPO_PORT):1567 --name contrail-apt-repo $(CONTRAIL_REPO_CONTAINER):$(CONTRAIL_VERSION)
	@echo "Saving the container $(CONTRAIL_REPO_CONTAINER):$(CONTRAIL_VERSION)"
	docker save $(CONTRAIL_REPO_CONTAINER):$(CONTRAIL_VERSION) | gzip -c > $@

$(CONTRAIL_INSTALL_PACKAGE):
	@echo "Making Contrail packages"
	@echo "Copying /cs-shared/packages/$(CONTRAIL_INSTALL_PACKAGE) to build directory"
	touch $@

.PHONY: clean

clean:
	@echo "Cleaning the workspace"
	docker rm -f contrail-apt-repo | true
ifndef KEEP_IMAGES
	$(foreach i,$(CONTAINERS),docker rmi -f contrail-$(i):$(CONTRAIL_VERSION) | true;)
	docker rmi -f $(CONTRAIL_REPO_CONTAINER):$(CONTRAIL_VERSION) | true
endif
	rm -f $(CONTAINER_TARS) $(CONTRAIL_INSTALL_PACKAGE) $(CONTRAIL_REPO_CONTAINER_TAR)

.PHONY: save

save: $(CONTAINER_TARS)
ifndef CONTAINER_SAVE_LOCATION
	$(error CONTAINER_SAVE_LOCATION is undefined)
endif
	@echo "Saving container images in $(CONTAINER_SAVE_LOCATION)"
	install -t  $(CONTAINER_SAVE_LOCATION) $(CONTAINER_TARS)
	install -t  $(CONTAINER_SAVE_LOCATION) $(CONTRAIL_REPO_CONTAINER_TAR)

.PHONY: push

push: $(CONTAINER_TARS)
ifdef CONTAINER_REGISTRY
		$(eval CONTAINERS := $(CONTAINER_TARS:%-$(CONTRAIL_VERSION).tar.gz=$(CONTAINER_REGISTRY)/%:$(CONTRAIL_VERSION)))
		@echo "Tagging container images to $(CONTAINERS)"
		@echo "Pushing container images $(CONTAINERS)"
else
		$(error CONTAINER_REGISTRY is undefined)
endif
