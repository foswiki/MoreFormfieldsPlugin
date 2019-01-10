FOSWIKI_ROOT?=~/foswiki/core
TARGET= \
  moreformfields.css \
  networkaddress.js \
  userfield.js \
  topicfield.js \
  attachmentfield.js \
  phonenumber.js \
  clockpicker.js \
  clockpicker.init.js \
  clockpicker.css \
  iconfield.js \
  smartbox.js \
  select2.js


-include $(FOSWIKI_ROOT)/pub/System/JQueryPlugin/Makefile.include

.PHONY: git

git:
	git clone https://github.com/weareoutman/clockpicker.git git

ifneq (,$(wildcard git))
clockpicker.uncompressed.js: git/dist/jquery-clockpicker.js
	@echo "creating $@"; cp $< $@

clockpicker.uncompressed.css: git/dist/jquery-clockpicker.css
	@echo "creating $@"; cp $< $@
endif
