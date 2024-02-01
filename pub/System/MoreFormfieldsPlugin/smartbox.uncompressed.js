/*
 * Copyright (c) 2013-2024 Michael Daum https://michaeldaumconsulting.com
 *
 * Licensed under the GPL license http://www.gnu.org/licenses/gpl.html
 *
 */
"use strict";
jQuery(function($) {

  $(document).on("change", ".foswikiSmartboxItem", function() {
    var $this = $(this), 
        $container = $this.parents(".foswikiSmartbox").first(),
        opts = $container.data(),
        val = $this.val(),
        isChecked = $this.is(":checked"),
        $items = $container.find(".foswikiSmartboxItem"),
        $anyValueItem = $container.find("input[value='"+opts.anyValue+"']");

    if (val === opts.anyValue) {
      $items.prop("checked", isChecked);
    } else {
      if ($items.length == $items.not($anyValueItem).filter(":checked").length + 1) {
        $anyValueItem.prop("checked", true);
      } else {
        $anyValueItem.prop("checked", false);
      }
    }

  });
});
