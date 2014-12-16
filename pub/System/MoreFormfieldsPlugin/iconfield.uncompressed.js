jQuery(function($) {
"use strict";

  var defaults = {
    minimumInputLength: 0,
    url: foswiki.getPreference('SCRIPTURL')+'/rest/MoreFormfieldsPlugin/icon',
    width: 'element',
    multiple: false,
    quietMillis:500,
    pageSize: 20
  };
  
  function formatIconField(value, container) {
      var result;

      if (typeof(value.id) === 'undefined') {
        result = value.text;
      } else if (value.id.match(/^fa\-/)) {
        result = '<i class="fa ' + value.id + '"></i> ' + value.text;
      } else if (value.url) {
        result = '<img src="'+value.url+'" class="foswikiIcon" /> ' + value.text;
      } else {
        result = value.text;
      }

      return result;
  };

  $(".foswikiIconField:not(.foswikiIconFieldInited)").livequery(function() {
    var $this = $(this), 
        opts = $.extend({}, defaults, $this.data()),
        val = $this.val();

    $this.addClass("foswikiIconFieldInited");

    $this.select2({
      allowClear: true,
      placeholder: 'None',
      minimumInputLength: opts.minimumInputLength,
      width: opts.width,
      multiple: opts.multiple,
      formatSelection: formatIconField,
      formatResult: formatIconField,
      _escapeMarkup: function(m) { return m; },
      ajax: {
        url: opts.url,
        dataType: 'json',
        data: function (term, page) {
          return {
            q: term, 
            limit: opts.pageSize,
            page: page,
            cat: opts.cat,
            include: opts.include,
            exclude: opts.exclude
          };
        },
        results: function (data, page) {
           data.more = (page * opts.pageSize) < data.total;
           return data;
        }
      },
      initSelection: function(elem, callback) {
        var params;
        if (val!=='') {
          params = {
            q: val,
            limit: 1,
            cat: opts.cat,
            exact: 1
          };
          $.ajax(opts.url, {
            data: params,
            dataType: 'json'
          }).done(function(data) { 
            if (typeof(data.results) !== 'undefined') {
              callback(data.results[0]); 
            }
          });
        }
      }
    });
  });
});
