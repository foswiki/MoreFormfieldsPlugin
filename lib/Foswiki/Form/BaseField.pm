# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2010-2025 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Form::BaseField;

use strict;
use warnings;

use Foswiki::Func ();
use Foswiki::Form::FieldDefinition ();
our @ISA = ('Foswiki::Form::FieldDefinition');

sub finish {
  my $this = shift;
  $this->SUPER::finish();
  undef $this->{_params};
}

sub param {
  my ($this, $key, $val) = @_;

  unless (defined $this->{_params}) {
    my %params = Foswiki::Func::extractParameters($this->{value});
    $this->{_params} = \%params;
  }

  if (defined $key && defined $val) {
    $this->{_params}{$key} = $val;
    return $val;
  }

  return (defined $key) ? $this->{_params}{$key} : $this->{_params};
}

sub readTemplate {
  my ($this, $name) = @_;

  return if exists $this->{session}{doneReadTemplate}{$name};
  $this->{session}{doneReadTemplate}{$name} = 1;
 
  return Foswiki::Func::readTemplate($name);
}

sub getDefaultValue {
  my ($this, $web, $topic) = @_;

  my $value = $this->{default} // "";

  if ($value eq "") {
    $value = Foswiki::Func::decodeFormatTokens($this->param("default") // "");
    $value = Foswiki::Func::expandCommonVariables($value, $topic, $web) if $value =~ /%/;
  }

  return $value;
}

sub getFormfieldClass {
  my $this = shift;

  return $this->{_formfieldClass} // 'foswikiFormfield';
}

sub renderForDisplay {
  my ($this, $format, $value, $attrs) = @_;

  my $displayValue = $this->getDisplayValue($value);
  $format =~ s/\$value\(display\)/$displayValue/g;
  $format =~ s/\$value/$value/g;

  $this->addStyles();

  return $this->SUPER::renderForDisplay($format, $value, $attrs);
}

sub addStyles {
  #my $this = shift;
  Foswiki::Func::addToZone("head", 
    "MOREFORMFIELDSPLUGIN::CSS", 
    "<link rel='stylesheet' href='%PUBURLPATH%/%SYSTEMWEB%/MoreFormfieldsPlugin/build/moreformfields.css' media='all'>"
  );
}

sub addJavaScript {}

sub encode {
  my ($this, $text) = @_;

  $text = Encode::encode_utf8($text) if $Foswiki::UNICODE;
  $text =~ s/([^0-9a-zA-Z-_.:~!*\/])/'%'.sprintf('%02x',ord($1))/ge;

  return $text;
}

1;
