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

package Foswiki::Form::Bytes;

use strict;
use warnings;

use Foswiki::Render();
use Foswiki::Form::Text ();
use Foswiki::Form::BaseField ();
use Scalar::Util qw( looks_like_number );

our @ISA = ('Foswiki::Form::Text', 'Foswiki::Form::BaseField');
our @BYTE_SUFFIX = ('B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB');

sub new {
  my $class = shift;

  my $this = $class->SUPER::new(@_);

  my $size = $this->{size} || '';
  $size =~ s/\D//g;
  $size = 10 if (!$size || $size < 1);
  $this->{size} = $size;

  return $this;
}

sub getDefaultValue {
  my $this = shift;

  return $this->Foswiki::Form::BaseField::getDefaultValue(@_);
}

sub isTextMergeable { return 0; }

sub renderForEdit {
  my ($this, $topicObject, $value) = @_;

  return (
    '',
    Foswiki::Render::html("input", {
      "type" => "text",
      "class" => $this->cssClasses('foswikiInputField foswikiBytesField'),
      "name" => $this->{name},
      "size" => $this->{size},
      "value" => $value,
      "data-rule-pattern" => '^[+\-]?\d+(\.\d+)?$'
    })
  );
}

sub getDisplayValue {
  my ($this, $value) = @_;

  return $value unless looks_like_number($value);
  my $max = $this->param("max") || '';

  my $magnitude = 0;
  my $suffix;
  my $orig = $value;

  while ($magnitude < scalar(@BYTE_SUFFIX)) {
    $suffix = $BYTE_SUFFIX[$magnitude];
    last if $value < 1024;
    last if $max eq $suffix;
    $value = $value/1024;
    $magnitude++;
  };

  my $prec = $this->param("prec") // 2;

  my $result = sprintf("%.0".$prec."f", $value);
  $result =~ s/\.00$//;
  $result .= ' '. $suffix;

  return $result;
}

1;

