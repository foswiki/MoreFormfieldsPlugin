# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2010-2022 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Form::Phonenumber;

use strict;
use warnings;

use Foswiki::Render();
use Foswiki::Form::Text ();
use Foswiki::Plugins::JQueryPlugin();
our @ISA = ('Foswiki::Form::Text');

sub isTextMergeable { return 0; }

sub finish {
  my $this = shift;

  $this->SUPER::finish();

  undef $this->{_params};
}

sub addStyles {
  #my $this = shift;
  Foswiki::Func::addToZone("head", 
    "MOREFORMFIELDSPLUGIN::CSS",
    "<link rel='stylesheet' href='%PUBURLPATH%/%SYSTEMWEB%/MoreFormfieldsPlugin/moreformfields.css' media='all' />",
    "JQUERYPLUGIN::SELECT2");

}

sub addJavascript {
  #my $this = shift;

  Foswiki::Plugins::JQueryPlugin::createPlugin("validate");
  Foswiki::Func::addToZone("script", 
    "MOREFORMFIELDSPLUGIN::PHONENUMBER::JS",
    "<script src='%PUBURLPATH%/%SYSTEMWEB%/MoreFormfieldsPlugin/phonenumber.js'></script>", 
    "JQUERYPLUGIN::FOSWIKI, JQUERYPLUGIN::VALIDATE");
}

sub renderForEdit {
  my ($this, $topicObject, $value) = @_;

  $this->addJavascript();
  $this->addStyles();

  return (
    '',
    Foswiki::Render::html("input", {
      "type" => "text",
      "class" => $this->cssClasses('foswikiInputField foswikiPhoneNumber'),
      "name" => $this->{name},
      "size" => $this->{size},
      "value" => $value,
    })
  );
}

sub renderForDisplay {
  my ($this, $format, $value, $attrs) = @_;

  return '' unless defined $value && $value ne '';

  my $displayValue = $this->getDisplayValue($value);
  $format =~ s/\$value\(display\)/$displayValue/g;
  $format =~ s/\$value/$value/g;

  $this->addStyles();
  $this->addJavascript();

  return $this->SUPER::renderForDisplay($format, $value, $attrs);
}

sub getDisplayValue {
  my ($this, $value) = @_;

  my $number = $value;
  $number =~ s/\s+//g;
  $number =~ s/\(.*?\)//g;
  $number =~ s/^\+/00/;

  my $prot = $this->param("protocol") || 'tel';

  return "<a href='$prot:$number' class='foswikiPhoneNumber'>$value</a>";
}

sub getDefaultValue {
  my $this = shift;

  my $value = $this->{default};
  $value = '' unless defined $value;

  return $value;
}

sub param {
  my ($this, $key) = @_;

  unless (defined $this->{_params}) {
    my %params = Foswiki::Func::extractParameters($this->{value});
    $this->{_params} = \%params;
  }

  return (defined $key) ? $this->{_params}{$key} : $this->{_params};
}

1;
