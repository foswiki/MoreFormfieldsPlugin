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
    limit: 10,
    sortable: false,
    templateName: "moreformfields",
    definitionName: "select2::topic",
  };

  function formatItem(item) {
    if (item.thumbnail) {
      return "<div class='image-item' style='background-image:url(\""+item.thumbnail + "\")'>"+
        item.text + 
        "</div>";
    } else {
      return item.text;
    }
  }

  $(".foswikiTopicFieldEditor:not(.inited)").livequery(function() {
    var $this = $(this), 
        opts = $.extend({}, defaults, $this.data()),
        requestOpts = $.extend({}, opts),
        val = $this.val(),
        url = new URL(opts.url, window.location.origin);

    delete requestOpts.minimumInputLength;
    delete requestOpts.url;
    delete requestOpts.templateName;
    delete requestOpts.definitionName;
    delete requestOpts.width;
    delete requestOpts.quietMillis;
    delete requestOpts.valueText;

    // move get params to post payload
    url.searchParams.forEach(function(val, key) {
      requestOpts[key] = val;
      //console.log("key=",key,"val=",val);
    });


    //console.log("opts=",opts);
    //console.log("requestOpts=",requestOpts);
    //console.log("url=",url.href);

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
        type: 'post',
        data: function (term, page) {
          var params = 
            $.extend({}, {
              name: opts.templateName,
              expand: opts.definitionName,
              q: term, // search term
	      limit: opts.limit,
              page: page
            }, requestOpts);
          return params;
        },
        results: function (data, page) {
           data.more = (page * opts.limit) < data.total;
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
                text: text,
                thumbnail: opts.thumbnail[this]
              });
            } catch(err) {
              console && console.error("Error: illegal value in topicfield:",text); 
            };
	  });
	} else {
          text = opts.valueText;
          try {
            text = decodeURIComponent(text);
            data = {
              id: val, 
              text: text,
              thumbnail: opts.thumbnail
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
