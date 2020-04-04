# Copyright 2020 Codecahedron Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
REPOSITORY_ROOT := $(patsubst %/,%,$(dir $(abspath Makefile)))

TERRAFORM_VERSION = 0.12.24

# Make port forwards accessible outside of the proxy machine.
BUILD_DIR = $(REPOSITORY_ROOT)/build
TOOLCHAIN_DIR = $(BUILD_DIR)/toolchain
TOOLCHAIN_BIN = $(TOOLCHAIN_DIR)/bin
ARCHIVES_DIR = $(BUILD_DIR)/archives

# Tools
TERRAFORM = $(TOOLCHAIN_BIN)/terraform$(EXE_EXTENSION)

export PATH := $(REPOSITORY_ROOT)/build/toolchain/bin:$(CURDIR)/bin:$(PATH):/usr/local/go/bin:/usr/go/bin

ifeq ($(OS),Windows_NT)
	TERRAFORM_PACKAGE = https://releases.hashicorp.com/terraform/$(TERRAFORM_VERSION)/terraform_$(TERRAFORM_VERSION)_windows_amd64.zip
else
	UNAME_OS := $(shell uname -s)
	UNAME_ARCH := $(shell uname -m)
	ifeq ($(UNAME_OS),Linux)
		TERRAFORM_PACKAGE = https://releases.hashicorp.com/terraform/$(TERRAFORM_VERSION)/terraform_$(TERRAFORM_VERSION)_linux_amd64.zip
	endif
	ifeq ($(UNAME_OS),Darwin)
		TERRAFORM_PACKAGE = https://releases.hashicorp.com/terraform/$(TERRAFORM_VERSION)/terraform_$(TERRAFORM_VERSION)_darwin_amd64.zip
	endif
endif

INFRA_TOOLCHAIN += build/toolchain/bin/terraform$(EXE_EXTENSION)

bootstrap: install-toolchain

lint: build/toolchain/bin/terraform$(EXE_EXTENSION)
	$(TERRAFORM) fmt -recursive

install-toolchain: $(CODECAHEDRON_TOOLCHAIN)

build/archives/terraform.zip:
	mkdir -p $(ARCHIVES_DIR)
	curl -o $@ -L $(TERRAFORM_PACKAGE)
	touch $@

build/toolchain/bin/terraform$(EXE_EXTENSION): build/archives/terraform.zip
	mkdir -p $(TOOLCHAIN_BIN)
	mkdir -p $(TOOLCHAIN_DIR)/temp-terraform
	cp $(ARCHIVES_DIR)/terraform.zip $(TOOLCHAIN_DIR)/temp-terraform/terraform.zip
	cd $(TOOLCHAIN_DIR)/temp-terraform && unzip -j -q -o terraform.zip
	mv $(TOOLCHAIN_DIR)/temp-terraform/terraform$(EXE_EXTENSION) $@
	rm -rf $(TOOLCHAIN_DIR)/temp-terraform/
	touch $@

terraform-plan: build/toolchain/bin/terraform$(EXE_EXTENSION)
	cd $(REPOSITORY_ROOT)/state && $(TERRAFORM) init
	cd $(REPOSITORY_ROOT)/state && $(TERRAFORM) plan

clean:
	rm -f $(REPOSITORY_ROOT)/testdata/hashes.csv

.SECONDARY:
.PHONY: bootstrap lint clean install-toolchain terraform-plan
