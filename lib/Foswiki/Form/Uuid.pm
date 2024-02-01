# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2021-2024 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Form::Uuid;

use strict;
use warnings;

use Foswiki::Form::BaseField ();
use Foswiki::Func ();
use Foswiki::Render ();
our @ISA = ('Foswiki::Form::BaseField');

sub new {
  my $class = shift;
  my $this = $class->SUPER::new(@_);

  $this->{_formfieldClass} = 'foswikiUuidField';

  return $this;
}

sub isEditable { return 0; }
sub isTextMergeable { return 0; }

sub renderForEdit {
  my ($this, $meta, $value) = @_;

  return (
    '',
    Foswiki::Render::html("input", {
      "type" => "hidden",
      "name" => $this->{name},
      "value" => $value,
    }) .
    Foswiki::Render::html("div", {
      "class" => $this->{_formfieldClass}
    }, $value)
  );
}

sub afterSaveHandler {
  my ($this, $meta) = @_;

  my $thisField = $meta->get('FIELD', $this->{name});

  # only once
  return if defined($thisField) && defined($thisField->{value}) && $thisField->{value} ne "";

  $thisField = {
    name => $this->{name},
    title => $this->{name},
    value => "",
  } unless defined $thisField;

  # remove it from the request so that it doesn't override things here
  my $request = Foswiki::Func::getRequestObject();
  $request->delete($this->{name});

  my $value = $this->generateID();
  return if $thisField->{value} eq $value;

  $thisField->{value} = $value;
  $meta->putKeyed('FIELD', $thisField);

  return 1;    # trigger mustSave
}

sub generateID {
  my $this = shift;

  my $prefix = $this->param("prefix");
  my $charset = $this->param("charset") || "upperalpha";

  if (defined $prefix) {
    $prefix .= '-';
  } else {
    $prefix = '';
  }

  # secure enuf
  my $uuid = sprintf(
    ($charset eq 'upperalpha' ? "%08X-%04X-%04X-%04X-%08X" : "%08x-%04x-%04x-%04x-%08x"), 
    rand(0xFFFFFFFF) & 0xFFFFFFFF, 
    rand(0xFFFF) & 0xFFFF, 
    rand(0xFFFF) & 0xFFFF, 
    rand(0xFFFF) & 0xFFFF, 
    rand(0xFFFFFFFF) & 0xFFFFFFFF
  );

  return $prefix . $uuid;
}

sub getDisplayValue {
  my ($this, $value) = @_;

  $this->addStyles();

  return "<span class='" . $this->{_formfieldClass} . "'>$value</span>";
}

1;

