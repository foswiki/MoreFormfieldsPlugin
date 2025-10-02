/*
 * Copyright (c) 2013-2025 Michael Daum https://michaeldaumconsulting.com
 *
 * Licensed under the GPL license http://www.gnu.org/licenses/gpl.html
 *
 */
"use strict";
(function($) {

  var defaults = {
    minimumInputLength: 0,
    placeholder: 'None',
    url: null,
    width: 'element',
    multiple: false,
    quietMillis:500,
    sortable: false,
    limit: 10
  };


  function WebFieldEditor(elem, opts) {
    var self = this;

    //console.log("new WebFieldEditor");

    self.elem = $(elem);
    self.opts = $.extend({}, defaults, self.elem.data(), opts);
    self.init();
  }

  WebFieldEditor.prototype.init = function () {
    var self = this,
        val = self.elem.val();

    self.opts.params = $.extend({}, self.opts);

    delete self.opts.params.minimumInputLength;
    delete self.opts.params.placeholder;
    delete self.opts.params.url;
    delete self.opts.params.width;
    delete self.opts.params.multiple;
    delete self.opts.params.quietMillis;
    delete self.opts.params.sortable;
    delete self.opts.params.valueText;

    self.elem.select2({
      allowClear: true,
      dropdownCssClass: 'ui-dialog', // work around problems with jquery-ui: see https://github.com/select2/select2/issues/940
      placeholder: self.opts.placeholder,
      minimumInputLength: self.opts.minimumInputLength,
      width: self.opts.width,
      multiple: self.opts.multiple,
      ajax: {
        url: self.opts.url,
        dataType: 'json',
        data: function (term, page) {
          var params = 
            $.extend({}, {
              q: term, // search term
              limit: self.opts.limit,
              page: page
            }, self.opts.params);
          return params;
        },
        results: function (data, page) {
           data.more = (page * self.opts.limit) < data.total;
           return data;
        }
      },
      initSelection: function(elem, callback) {
	var data, text;
	if (self.opts.multiple) {
          data = [];
	  $(val.split(/\s*,\s*/)).each(function (index) {
            text = self.opts.valueText[this]||this;
            try {
              text = decodeURIComponent(text);
              data.push({
                id: this, 
                text: text
              });
            } catch(err) {
              console && console.error("Error: illegal value in webfield:",text); 
            };
	  });
	} else {
          text = self.opts.valueText;
          try {
            text = decodeURIComponent(text);
            data = {
              id: val, 
              title: text,
              text: text
            };
          } catch(err) {
            console && console.error("Error: illegal value in topicfield:",text); 
          };
	}
	callback(data);
      },
      formatResult: function(item) {
        return item.text;
      },
      formatSelection: function(item) {
        return item.title;
      }
    });

    // make it sortable
    if (self.opts.sortable) {
      self.elem.select2("container").find("ul.select2-choices").sortable({
	  items: "> .select2-search-choice",
          start: function() { self.elem.select2( 'onSortStart' ); },
          stop: function() { self.elem.select2( 'onSortEnd' ); }
      });
    }
  };

  $.fn.webFieldEditor = function (opts) {
    return this.each(function () {
      if (!$.data(this, "webFieldEditor")) {
        $.data(this, "webFieldEditor", new WebFieldEditor(this, opts));
      }
    });
  };

  // Enable declarative widget instanziation
  $(".foswikiWebFieldEditor:not(.select2-container)").livequery(function() {
    $(this).webFieldEditor();
  });

})(jQuery);
