/*
 * Copyright (c) 2013-2022 Michael Daum https://michaeldaumconsulting.com
 *
 * Licensed under the GPL license http://www.gnu.org/licenses/gpl.html
 *
 */

"use strict";
(function($) {

  $.validator.addMethod('phone', function(value, element) {
    value = value.replace(/\s/g,'');
    return (
      this.optional(element) ||
      value.match(/^(((\+)?[1-9]{1,2})?([\-\s\.])?(\(\d\)[\-\s\.]?)?((\(\d{1,4}\))|\d{1,4})(([\-\s\.])?[0-9]{1,12}){1,2}(\s*(ext|x)\s*\.?:?\s*([0-9]+))?)?$/)
    );
  }, 'Please enter a valid phone number (Intl format accepted + ext: or x:)');

  $.validator.addClassRules("foswikiPhoneNumber", {
    phone: true
  })

})(jQuery);
