FOSWIKI_ROOT?=~/foswiki/core
TARGET= \
  build \
  build/moreformfields.css \
  build/networkaddress.js \
  build/topicfield.js \
  build/webfield.js \
  build/attachmentfield.js \
  build/phonenumber.js \
  build/clockpicker.js \
  build/clockpicker.init.js \
  build/clockpicker.css \
  build/iconfield.js \
  build/smartbox.js \
  build/select2.js \
  build/multitext.js \
  build/slider.js


-include $(FOSWIKI_ROOT)/pub/System/JQueryPlugin/Makefile.include

.PHONY: git

CLOCKPICKER_JS=lib/clockpicker.uncompressed.js src/clockpicker.init.uncompressed.js

clean:
	rm -f build/*

build:
	@mkdir build

build/clockpicker.js: $(CLOCKPICKER_JS)
	@echo "creating $@"; $(JSMIN) $^ > $@


git:
	git clone https://github.com/weareoutman/clockpicker.git git

ifneq (,$(wildcard git))
lib/clockpicker.uncompressed.js: git/dist/jquery-clockpicker.js
	@echo "creating $@"; cp $< $@

lib/clockpicker.uncompressed.css: git/dist/jquery-clockpicker.css
	@echo "creating $@"; cp $< $@
endif
