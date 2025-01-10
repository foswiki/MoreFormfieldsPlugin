/*
 * MultiText 
 *
 * Copyright (c) 2019-2025 Michael Daum https://michaeldaumconsulting.com
 *
 * Licensed under the GPL license http://www.gnu.org/licenses/gpl.html
 *
 */
"use strict";
(function($) {

  var defaults = {
    selector: "input",
    separator: ",",
    sortable: true
  };

  function MultiText(elem, opts) {
    var self = this;

    self.elem = $(elem);
    self.opts = $.extend({}, defaults, self.elem.data(), opts);
    self.init();
  }

  MultiText.prototype.init = function () {
    var self = this;

    self.elem.wrap("<div class='jqMultiTextInputWrapper orig'></div>");
    self.container = self.elem.parent().wrap("<div class='jqMultiTextContainer jqMultiText inited'></div>").parent();
    self.container.data({
      "multiText": self,
    }).attr("data-name", self.elem.attr("name"))

    if (self.opts.sortable) {
      self.container.sortable({
	items: '> .jqMultiTextInputWrapper',
      });
    }

    self.elem.on("focus blur keydown", function(ev) {
      var elem = $(this);

      if (typeof(self.timer) !== 'undefined') {
	window.clearTimeout(self.timer);
      }
      self.timer = window.setTimeout(function() {
	self.updateFields();
      }, 250);

      if (ev.type === 'keydown' && ev.keyCode == 13 && elem.val() !== '') {
	elem.parent().next().find(self.opts.selector).focus();
	return false;
      }
    });

    var value = self.elem.val();

    self.setValue(value);
  };

  MultiText.prototype.clear = function() {
    var self = this;

    self.container.children(":not(.orig)").remove();
    self.elem.val("");
  };

  MultiText.prototype.getValue = function() {
    var self = this, value = [];

    self.container.find("input").each(function() {
      if (this.value !== '') {
        value.push(this.value);
      }
    });

    return value;
  };

  MultiText.prototype.setValue = function(val) {
    var self = this, val,
        sep = decodeURIComponent(self.opts.separator),
        regex = new RegExp("\\s*"+sep+"\\s*");

    self.clear();

    if (typeof(val) === 'undefined' || val === '') {
      return;
    }

    if (typeof(val) === "string") {
      if (val !== '') {

        val = decodeURIComponent(val);
        val = val.split(regex);

      }
    } 

    $.each(val, function(i, v) {
      if (i) {
        self.createField(v);
      } else {
        self.elem.val(v);
      }
    });

    self.createField();
  };

  MultiText.prototype.appendValue = function(val) {
    var self = this,
        values = self.getValue();

    values.push(val);
    self.setValue(values);
  };

  MultiText.prototype.updateFields = function() {
    var self = this, empty;

    empty = self.container.find(self.opts.selector).not(':focus').filter(function() {
      return this.value === '';
    });

    if (empty.length < 1) {
      self.createField();
    } 

    if (empty.length > 1) {
      empty.slice(0, -1).remove();
    }
  };

  MultiText.prototype.createField = function(val) {
    var self = this, clone;

    if (typeof(val) === 'undefined') {
      val = "";
    }

    clone = self.elem.clone(true);
    clone
      .removeClass('foswikiMandatory valid jqMultiText')
      .removeAttr("value")
      .val(val)
      .wrap("<div class='jqMultiTextInputWrapper'></div>")
      .parent().appendTo(self.container);

    self.elem.trigger("update", clone);
  };

  $.fn.multiText = function (opts) {
    return this.each(function () {
      new MultiText(this, opts);
    });
  };

  $(function() {
    $(".jqMultiText:not(.inited)").livequery(function() {
      $(this).multiText();
    });
  });

})(jQuery);
