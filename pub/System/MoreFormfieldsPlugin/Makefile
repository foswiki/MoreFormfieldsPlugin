FOSWIKI_ROOT?=~/foswiki/core
TARGET= \
  moreformfields.css \
  networkaddress.js \
  userfield.js \
  topicfield.js \
  phonenumber.js \
  clockpicker.js \
  clockpicker.init.js \
  clockpicker.css \
  iconfield.js \
  smartbox.js

-include $(FOSWIKI_ROOT)/pub/System/JQueryPlugin/Makefile.include

clockpicker.uncompressed.js: git/dist/jquery-clockpicker.js
	@echo "creating $@"; cp $< $@

clockpicker.uncompressed.css: git/dist/jquery-clockpicker.css
	@echo "creating $@"; cp $< $@
