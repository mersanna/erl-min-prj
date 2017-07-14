PROJECT=phonebook
DESCRIPTION="Simple Phonebook"
HOMEPAGE="http://eax.me/"

BUILD_DIR=$(CURDIR)/$(PROJECT)
PACKAGE_DIR=$(CURDIR)/build

OVERLAY_VARS?=files/vars.config
PACKAGE=$(PROJECT)
VERSION=`cat files/VERSION`

all: build

clean:
	rm -rf build
	./rebar clean

deps:
	./rebar get-deps

compile: deps
	./rebar compile
	./rebar xref skip_apps=goldrush

build: compile
	./rebar generate overlay_vars=$(OVERLAY_VARS)

run: clean
	make OVERLAY_VARS=files/vars-dev.config
	./$(PROJECT)/bin/$(PROJECT) console

release: clean build
	mkdir -p $(PACKAGE_DIR)/etc/init.d
	mkdir -p $(PACKAGE_DIR)/etc/$(PROJECT)
	mkdir -p $(PACKAGE_DIR)/usr/lib/$(PROJECT)/bin
	mkdir -p $(PACKAGE_DIR)/var/log/$(PROJECT)

	cp -R $(BUILD_DIR)/erts-*   $(PACKAGE_DIR)/usr/lib/$(PROJECT)/
	cp -R $(BUILD_DIR)/lib      $(PACKAGE_DIR)/usr/lib/$(PROJECT)/
	cp -R $(BUILD_DIR)/releases $(PACKAGE_DIR)/usr/lib/$(PROJECT)/

	install -p -m 0755 $(BUILD_DIR)/bin/$(PROJECT) $(PACKAGE_DIR)/usr/lib/$(PROJECT)/bin/$(PROJECT)
	install -p -m 0755 $(CURDIR)/files/init        $(PACKAGE_DIR)/etc/init.d/$(PROJECT)
	install -m644 $(BUILD_DIR)/etc/app.config      $(PACKAGE_DIR)/etc/$(PROJECT)/app.config
	install -m644 $(BUILD_DIR)/etc/VERSION      $(PACKAGE_DIR)/etc/$(PROJECT)/VERSION
	install -m644 $(BUILD_DIR)/etc/vm.args         $(PACKAGE_DIR)/etc/$(PROJECT)/vm.args
	install -m644 $(BUILD_DIR)/etc/${PROJECT}.yml         $(PACKAGE_DIR)/etc/$(PROJECT)/${PROJECT}.yml

	fpm -s dir -t deb -f -n $(PACKAGE) -v $(VERSION) \
		--after-install $(CURDIR)/files/postinst \
		--after-remove  $(CURDIR)/files/postrm \
		--config-files /etc/$(PROJECT)/app.config \
		--config-files /etc/$(PROJECT)/vm.args \
		--config-files /etc/$(PROJECT)/${PROJECT}.yml \
		--config-files /etc/$(PROJECT)/VERSION \
		--deb-pre-depends adduser \
		--description $(DESCRIPTION) \
		-a native --url $(HOMEPAGE) \
		-C $(PACKAGE_DIR) etc usr var
