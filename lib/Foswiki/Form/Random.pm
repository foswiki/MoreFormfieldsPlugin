# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2021-2022 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Form::Random;

use strict;
use warnings;

use Foswiki::Form::FieldDefinition ();
use Foswiki::Func ();
use Foswiki::Render ();
our @ISA = ('Foswiki::Form::FieldDefinition');

our %CHARSETS = (
  "alpha" => [ 'a' .. 'z', 'A' .. 'Z' ],
  "upperalpha" => ['A' .. 'Z'],
  "loweralpha" => ['a' .. 'z'],
  "numeric" => [ 0 .. 9 ],
  "alphanumeric" => [ 0 .. 9, 'a' .. 'z', 'A' .. 'Z' ],
  "misc" => ['#', ',', qw(~ ! @ $ % ^ & * ( ) _ + = - { } | : " < > ? / . ' ; ] [ \ `)],
  "all" => [ 0 .. 9, 'a' .. 'z', 'A' .. 'Z', '#', ',', qw(~ ! @ $ % ^ & * ( ) _ + = - { } | : " < > ? / . ' ; ] [ \ `)],
);

sub new {
  my $class = shift;
  my $this = $class->SUPER::new(@_);

  $this->{_formfieldClass} = 'foswikiRadomField';

  return $this;
}

sub finish {
  my $this = shift;
  $this->SUPER::finish();
  undef $this->{_params};
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

sub param {
  my ($this, $key) = @_;

  unless (defined $this->{_params}) {
    my %params = Foswiki::Func::extractParameters($this->{value});
    $this->{_params} = \%params;
  }

  return (defined $key) ? $this->{_params}{$key} : $this->{_params};
}

sub getDefaultValue {
  my $this = shift;

  my $value = $this->{default};
  $value = '' unless defined $value;

  return $value;
}

sub afterSaveHandler {
  my ($this, $meta) = @_;

  my $thisField = $meta->get('FIELD', $this->{name});

  return if defined($thisField) && defined($thisField->{value}) && $thisField->{value} ne "";

  $thisField = {
    name => $this->{name},
    title => $this->{name},
    value => "",
  } unless defined $thisField;

  # remove it from the request so that it doesn't override things here
  my $request = Foswiki::Func::getRequestObject();
  $request->delete($this->{name});

  my $value = $this->randomChars();
  return if $thisField->{value} eq $value;

  $thisField->{value} = $value;
  $meta->putKeyed('FIELD', $thisField);

  return 1;    # trigger mustSave
}

sub randomChars {
  my $this = shift;

  my $set = $this->param("charset") // "alphanumeric";
  my $charset = $CHARSETS{$set};
  return unless defined $charset;

  my $size = $this->{size};
  my $min = $this->param("min");
  my $max = $this->param("max") // $size;
  $size = ($min + int(rand($max - $min))) if defined $min;

  my $result = "";

  my $len = scalar(@$charset);
  for (my $i = 0 ; $i < $size ; $i++) {
    $result .= $charset->[int(rand($len))];
  }

  return $result;
}

1;
