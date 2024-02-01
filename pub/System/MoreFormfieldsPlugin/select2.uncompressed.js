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
    quietMillis:500
  };

  $(".foswikiSelect2Field:not(.inited)").livequery(function() {
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
	  $(val.split(/\s*,\s*/)).each(function () {
	    text = decodeURIComponent(opts.valueText[this]||this);
	    data.push({id: this, text: text});
	  });
	} else {
          text = decodeURIComponent(opts.valueText);
	  data = {id:val, text:text};
	}
	callback(data);
      }
    });
  });
});
