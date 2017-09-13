"use strict";
jQuery(function($) {

  // methods
  jQuery.validator.addMethod("ipv4_address", function(value, element, param) {
    return this.optional(element) || /^(25[0-5]|2[0-4]\d|[01]?\d\d?)\.(25[0-5]|2[0-4]\d|[01]?\d\d?)\.(25[0-5]|2[0-4]\d|[01]?\d\d?)\.(25[0-4]|2[0-4]\d|[01]?\d\d?)$/i.test(value);
  }, "Please enter a valid IP v4 address.");

  jQuery.validator.addMethod("ipv4_netmask", function(value, element, param) {
    return this.optional(element) || /^(25[0-5]|2[0-4]\d|[01]?\d\d?)\.(25[0-5]|2[0-4]\d|[01]?\d\d?)\.(25[0-5]|2[0-4]\d|[01]?\d\d?)\.(25[0-5]|2[0-4]\d|[01]?\d\d?)$/i.test(value);
  }, "Please enter a valid IP v4 address.");

  jQuery.validator.addMethod("mac_address", function(value, element, param) {
    return this.optional(element) || /^([a-f\d]+)[:\.\-]([a-f\d]+)[:\.\-]([a-f\d]+)[:\.\-]([a-f\d]+)[:\.\-]([a-f\d]+)[:\.\-]([a-f\d]+)$/i.test(value);
  }, "Please enter a valid MAC address.");

  // add rules to jquery.validate
  $.validator.addClassRules("foswikiIpv4Address", {
    "ipv4_address": true
  })

  $.validator.addClassRules("foswikiIpv6Address", {
    "ipv6": true
  })

  $.validator.addClassRules("foswikiNetmask", {
    "ipv4_netmask": true
  })

  $.validator.addClassRules("foswikiMacAddress", {
    "mac_address": true
  })

});
