# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2023-2024 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Form::Masked;

use strict;
use warnings;

use Foswiki::Render();
use Foswiki::Plugins::JQueryPlugin ();
use Foswiki::Form::BaseField ();
our @ISA = ('Foswiki::Form::BaseField');

sub new {
  my $class = shift;

  my $this = $class->SUPER::new(@_);
  my $size = $this->{size} // 10;
  $size =~ s/\D//g;
  $size = 10 if !$size || $size < 1;
  $this->{size} = $size;

  return $this;
}

sub renderForEdit {
  my ($this, $meta, $value) = @_;

  Foswiki::Plugins::JQueryPlugin::createPlugin("imask");

  my $attrs = {
    "class" => $this->cssClasses('foswikiInputField imask'),
    "name" => $this->{name},
    "size" => $this->{size},
    "value" => $value,
  };

  my $placeholder = $this->param("placeholder");
  $attrs->{"placeholder"} = $placeholder if defined $placeholder;

  foreach my $key (qw(type mask pattern min max radix scale lazy from to autofix)) {
    my $val = $this->param($key);
    $attrs->{"data-".$key} = $val if defined $val;
  }

  return ('', Foswiki::Render::html("input", $attrs));
}

1;


