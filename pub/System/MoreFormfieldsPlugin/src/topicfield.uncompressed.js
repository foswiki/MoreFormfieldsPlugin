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
    quietMillis: 500,
    sortable: false,
    limit: 10,
    templateName: "moreformfields",
    definitionName: "select2::topic",
    relative: "off",
    web: null,
    webSelector: null
  };

  function TopicFieldEditor(elem, opts) {
    var self = this;

    //console.log("new TopicFieldEditor");

    self.elem = $(elem);
    self.opts = $.extend({}, defaults, self.elem.data(), opts);
    self.init();
  }

  TopicFieldEditor.prototype.init = function () {
    var self = this,
        val = self.elem.val(),
        url = new URL(self.opts.url, window.location.origin);

    self.opts.params = $.extend({}, self.opts);

    delete self.opts.params.minimumInputLength;
    delete self.opts.params.placeholder;
    delete self.opts.params.url;
    delete self.opts.params.width;
    delete self.opts.params.multiple;
    delete self.opts.params.quietMillis;
    delete self.opts.params.sortable;
    delete self.opts.params.templateName;
    delete self.opts.params.definitionName;
    delete self.opts.params.valueText;
    delete self.opts.params.webSelector;

    // move get params to post payload
    url.searchParams.forEach(function(val, key) {
      self.opts.params[key] = val;
      //console.log("key=",key,"val=",val);
    });


    //console.log("self.opts.params=",self.opts.params);
    //console.log("url=",url.href);

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
        type: 'post',
        data: function (term, page) {
          var params = 
            $.extend({}, {
              name: self.opts.templateName,
              expand: self.opts.definitionName,
              q: term, // search term
	      limit: self.opts.limit,
              page: page
            }, self.opts.params);

          if (self.opts.webSelector) {
            params.web = $(self.opts.webSelector).val() || params.web;
          }
          //console.log("web=",params.web);

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
                text: text,
                thumbnail: self.opts.thumbnail[this]
              });
            } catch(err) {
              console && console.error("Error: illegal value in topicfield:",text); 
            };
	  });
	} else {
          text = self.opts.valueText;
          try {
            text = decodeURIComponent(text);
            data = {
              id: val, 
              text: text,
              thumbnail: self.opts.thumbnail
            };
          } catch(err) {
            console && console.error("Error: illegal value in topicfield:",text); 
          };
	}
	callback(data);
      },
      formatResult: function(item) {
        return self.formatItem(item);
      },
      formatSelection: function(item) {
        return self.formatItem(item);
      }
    });

    // make it sortable
    if (self.opts.sortable) {
      self.elem.this.select2("container").find("ul.select2-choices").sortable({
	  items: "> .select2-search-choice",
          start: function() { self.elem.this.select2( 'onSortStart' ); },
          stop: function() { self.elem.this.select2( 'onSortEnd' ); }
      });
    }
  };

  TopicFieldEditor.prototype.formatItem = function formatItem(item) {
    var self = this;

    if (item.thumbnail) {
      return "<div class='image-item' style='background-image:url(\""+item.thumbnail + "\")'>"+
        item.text + 
        "</div>";
    } else {
      return item.text;
    }
  };

  $.fn.topicFieldEditor = function (opts) {
    return this.each(function () {
      if (!$.data(this, "topicFieldEditor")) {
        $.data(this, "topicFieldEditor", new TopicFieldEditor(this, opts));
      }
    });
  };

  // Enable declarative widget instanziation
  $(".foswikiTopicFieldEditor:not(.select2-container)").livequery(function() {
    $(this).topicFieldEditor();
  });

})(jQuery);
