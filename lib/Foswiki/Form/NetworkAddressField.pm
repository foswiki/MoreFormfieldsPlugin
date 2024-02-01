# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2010-2024 Michael Daum http://michaeldaumconsulting.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details, published at
# http://www.gnu.org/copyleft/gpl.html

package Foswiki::Form::NetworkAddressField;

use strict;
use warnings;

use Foswiki::Render();
use Foswiki::Form::Text ();
use Foswiki::Plugins::JQueryPlugin ();

our @ISA = ('Foswiki::Form::Text', 'Foswiki::Form::BaseField'); 

sub isTextMergeable { return 0; }

sub addJavaScript {
  #my $this = shift;
  Foswiki::Func::addToZone("script", 
    "MOREFORMFIELDSPLUGIN::IPADDRESS::JS",
    "<script src='%PUBURLPATH%/%SYSTEMWEB%/MoreFormfieldsPlugin/networkaddress.js'></script>", 
    "JQUERYPLUGIN::FOSWIKI, JQUERYPLUGIN::VALIDATE");

  Foswiki::Plugins::JQueryPlugin::createPlugin("validate");

  if ($Foswiki::cfg{Plugins}{MoreFormfieldsPlugin}{Debug}) {
    Foswiki::Plugins::JQueryPlugin::createPlugin("debug");
  }

}

sub renderForEdit {
  my $this = shift;

  # get args in a backwards compatible manor:
  my $metaOrWeb = shift;
  unless (ref($metaOrWeb)) {
    shift;
  }

  my $value = shift;

  $this->addJavaScript();
  $this->addStyles();

  my $required = '';
  if ($this->{attributes} =~ /\bM\b/i) {
    $required = 'required';
  }

  return (
    '',
    Foswiki::Render::html("input", {
      "type" => "text",
      "class" => $this->cssClasses('foswikiInputField', $this->{_formfieldClass}, $required),
      "name" => $this->{name},
      "size" => $this->{size},
      "value" => $value
    })
  );
}

sub getDisplayValue {
  my ($this, $value) = @_;

  $this->addStyles();

  return "<span class='" . $this->{_formfieldClass} . "'>$value</span>";
}

1;
