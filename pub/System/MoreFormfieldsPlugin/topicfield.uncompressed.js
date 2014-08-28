jQuery(function($) {
  var defaults = {
    minimumInputLength: 0,
    url: foswiki.getPreference('SCRIPTURL')+'/view/'+foswiki.getPreference('SYSTEMWEB')+'/MoreFormfieldsAjaxHelper?section=select2::topic&skin=text&contenttype=application/json%3Bcharset%3Dutf-8',
    width: 'element',
    multiple: false,
    quietMillis:500
  };

  function formatTopicItem(item) {
    if (item.thumbnail) {
      return "<div class='image-item' style='background-image:url("+item.thumbnail + ")'>"+
         item.text + 
         "</div>";
    } else {
      return item.text;
    }
  }

  $(".foswikiTopicField:not(.foswikiTopicFieldInited)").livequery(function() {
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

    $this.addClass("foswikiTopicFieldInited");

    $this.select2({
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
	var data = [], text;
	if (opts.multiple) {
	  $(val.split(/\s*,\s*/)).each(function () {
	    text = decodeURIComponent(opts.valueText[this]||this);
	    data.push({id: this, text: text});
	  });
	} else {
          text = decodeURIComponent(opts.valueText);
	  data = {id:val, text:text};
	}
	callback(data);
      },
      formatResult: formatTopicItem,
      formatSelection: formatTopicItem
    });
  });

});
