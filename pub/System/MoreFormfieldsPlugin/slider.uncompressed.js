/*
 * Slider input 
 *
 * Copyright (c) 2022 Michael Daum https://michaeldaumconsulting.com
 *
 * Licensed under the GPL license http://www.gnu.org/licenses/gpl.html
 *
 */
"use strict"; 

(function($) {
  var defaults = {
    animate: true,
    format: null
  };


  $(".jqSliderContainer").livequery(function() {
    var $container = $(this),
        opts = $.extend({}, defaults, $container.data()),
        $input = $container.find("input"),
        $slider = $("<div class='jqSliderElem' />").appendTo($container),
        $label = $("<span class='jqSliderLabel' />").appendTo($container),
        isRange = (typeof(opts.range) === 'boolean')? opts.range:false;

    if (isRange) {
      opts.values = $input.val().split(/\s*,\s*/);
      while (opts.values.length < 2) {
        opts.values.push(0);
      }
    } else {
      opts.value = $input.val();
    }

    function formatValue (val) {
      var result;

      if (typeof(val) === 'undefined') {
        val = $input.val();
      }

      if (isRange) {
        if (typeof(val) !== 'object') {
          val = val.split(/\s*,\s*/);
        }

        if (opts.isMapped) {
          val = $.map(val, function(v) {
            return opts.mappedValues[v];
          });
        }

        if (opts.format) {
          result = sprintf(opts.format, val[0], val[1]);
        } else {
          result = val.join(" - ");
        }
      } else {
        if (opts.isMapped) {
          val = opts.mappedValues[val]
        }

        if (opts.format) {
          result = sprintf(opts.format, val);
        } else {
          result = val;
        }
      }

      return result;
    }

    opts.create = function(ev, ui) {
      $label.text(formatValue());
    };

    opts.slide = function(ev, ui) {
      var val;
      if (isRange) {
        val = ui.values;
        $input.val(val.join(", "));
      } else {
        val = ui.value;
        $input.val(val);
      }

      $label.text(formatValue(val));
    };

    $slider.slider(opts);
  });
})(jQuery);
