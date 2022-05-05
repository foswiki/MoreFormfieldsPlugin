/*
 * Copyright (c) 2013-2022 Michael Daum https://michaeldaumconsulting.com
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
    if (item.thumbnail) {
      return "<div class='image-item' style='background-image:url(\""+item.thumbnail + "\")'>"+
        item.text + 
        "</div>";
    } else {
      return item.text;
    }
  }

  function getThumbnailUrl(file) {
    if (file.match(/\.(gif|png|jpe?g|webp)$/i)) {
      return foswiki.getScriptUrlPath("rest", "ImagePlugin", "resize", {
        topic: foswiki.getPreference("WEB")+"."+foswiki.getPreference("TOPIC"),
        file: encodeURIComponent(file),
        size: "32x32>",
        crop: "west"
      });
    } else {
      return foswiki.getScriptUrlPath("rest", "MimeIconPlugin", "get", {
        topic: foswiki.getPreference("WEB")+"."+foswiki.getPreference("TOPIC"),
        file: encodeURIComponent(file),
        size: "32"
      });
    }
  }

  $(".foswikiAttachmentField:not(.inited)").livequery(function() {
    var $this = $(this), 
        opts = $.extend({}, defaults, $this.data()),
        requestOpts = $.extend({}, opts),
        val = $this.val(),
        fileInput = $this.next().children("input:first");

    delete requestOpts.minimumInputLength;
    delete requestOpts.url;
    delete requestOpts.width;
    delete requestOpts.quietMillis;

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
	var data, text, url
	if (opts.multiple) {
          data = [];
	  $(val.split(/\s*,\s*/)).each(function () {
	    data.push({
              id: this, 
              text: decodeURIComponent(this),
              thumbnail: getThumbnailUrl(this)
            });
	  });
	} else {
	  data = {
            id:val, 
            text:val,
            thumbnail: getThumbnailUrl(val)
          };
	}
	callback(data);
      },
      formatResult: formatItem,
      formatSelection: formatItem
    })
    
    // make it sortable
    if (opts.sortable) {
      $this.select2("container").find("ul.select2-choices").sortable({
          items: "> .select2-search-choice",
          start: function() { $this.select2( 'onSortStart' ); },
          stop: function() { $this.select2( 'onSortEnd' ); }
      });
    }

    $(document).on("afterUpload", function() {
      var fileName = fileInput.val().replace(/^.*[\/\\]/, ""),
          regex;

      if (opts.acceptFileTypes) {
        regex = new RegExp(opts.acceptFileTypes);
        if (!regex.test(fileName)) {
          fileName = "";
        }
      }

      if (fileName !== '') {
        var data = $this.select2("data");
        if ($.isArray(data)) {
          data.push({
            id: fileName, 
            text: fileName,
            thumbnail: getThumbnailUrl(fileName)
          });
        } else {
          data = {
            id: fileName, 
            text: fileName,
            thumbnail: getThumbnailUrl(fileName)
          };
        }
        $this.select2("data", data);
      }
    });
  });

});
