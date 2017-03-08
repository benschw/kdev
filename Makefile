default: build

clean:
	rm -rf build

build: clean
	mkdir -p build
	cat src/common.sh \
		src/config.sh \
		src/cli.sh \
		src/pluginmgr.sh \
		src/main.sh \
		> build/horde
	chmod +x build/horde

install:
	cp build/horde /usr/local/bin/horde
	mkdir -p $(HOME)/.horde/plugins/core/
	cp src/plugins/services/*.sh $(HOME)/.horde/plugins/core/
	cp src/plugins/drivers/*.sh $(HOME)/.horde/plugins/core/

contrib-install:
	mkdir -p $(HOME)/.horde/plugins/contrib
	cp src/contrib/services/*.sh $(HOME)/.horde/plugins/contrib/
	cp src/contrib/drivers/*.sh $(HOME)/.horde/plugins/contrib/


.PHONY: build
