/*
 * Copyright (c) 2013-2024 Michael Daum https://michaeldaumconsulting.com
 *
 * Licensed under the GPL license http://www.gnu.org/licenses/gpl.html
 *
 */
"use strict";
jQuery(function($) {

  var defaults = {
    minimumInputLength: 0,
    placeholder: 'None',
    url: null,
    width: 'element',
    multiple: false,
    quietMillis:500,
    sortable: false
  };

  function formatItem(item) {
    return item.text;
  }

  $(".foswikiWebFieldEditor:not(.inited)").livequery(function() {
    var $this = $(this), 
        opts = $.extend({}, defaults, $this.data()),
        requestOpts = $.extend({}, opts),
        val = $this.val();

    delete requestOpts.minimumInputLength;
    delete requestOpts.url;
    delete requestOpts.width;
    delete requestOpts.quietMillis;
    delete requestOpts.valueText;

    //console.log("opts=",opts);
    //console.log("requestOpts=",requestOpts);

    $this.addClass("inited").select2({
      allowClear: true,
      dropdownCssClass: 'ui-dialog', // work around problems with jquery-ui: see https://github.com/select2/select2/issues/940
      placeholder: opts.placeholder,
      minimumInputLength: opts.minimumInputLength,
      width: opts.width,
      multiple: opts.multiple,
      ajax: {
        url: opts.url,
        dataType: 'json',
        data: function (term, page) {
          var params = 
            $.extend({}, {
              q: term, // search term
              limit: 10,
              page: page
            }, requestOpts);
          return params;
        },
        results: function (data, page) {
           data.more = (page * 10) < data.total;
           return data;
        }
      },
      initSelection: function(elem, callback) {
	var data, text;
	if (opts.multiple) {
          data = [];
	  $(val.split(/\s*,\s*/)).each(function (index) {
            text = opts.valueText[this]||this;
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
          text = opts.valueText;
          try {
            text = decodeURIComponent(text);
            data = {
              id: val, 
              text: text
            };
          } catch(err) {
            console && console.error("Error: illegal value in topicfield:",text); 
          };
	}
	callback(data);
      },
      formatResult: formatItem,
      formatSelection: formatItem
    });

    // make it sortable
    if (opts.sortable) {
      $this.select2("container").find("ul.select2-choices").sortable({
	  items: "> .select2-search-choice",
          start: function() { $this.select2( 'onSortStart' ); },
          stop: function() { $this.select2( 'onSortEnd' ); }
      });
    }
  });

});
