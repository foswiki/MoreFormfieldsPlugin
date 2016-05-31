FOSWIKI_ROOT?=~/foswiki/core
TARGET= \
  fontawesome.json \
  moreformfields.css \
  networkaddress.js \
  userfield.js \
  topicfield.js \
  phonenumber.js \
  clockpicker.js \
  clockpicker.init.js \
  clockpicker.css \
  iconfield.js \
  smartbox.js \
  select2.js

FONTAWESOME_GIT=$(FOSWIKI_ROOT)/pub/System/JQueryPlugin/plugins/fontawesome/git-fontawesome

-include $(FOSWIKI_ROOT)/pub/System/JQueryPlugin/Makefile.include

.PHONY: git

git:
	git clone https://github.com/weareoutman/clockpicker.git git

ifneq (,$(wildcard $(FONTAWESOME_GIT)))
fontawesome.json: $(FONTAWESOME_GIT)/src/icons.yml
	@echo "creating $@"; ./yaml2json $< > $@
else
fontawesome.json:
endif

ifneq (,$(wildcard git))
clockpicker.uncompressed.js: git/dist/jquery-clockpicker.js
	@echo "creating $@"; cp $< $@

clockpicker.uncompressed.css: git/dist/jquery-clockpicker.css
	@echo "creating $@"; cp $< $@
endif
