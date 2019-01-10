# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2010-2019 Michael Daum http://michaeldaumconsulting.com
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

use Foswiki::Form::Text ();
use Scalar::Util qw( looks_like_number );
our @ISA = ('Foswiki::Form::Text');
our @BYTE_SUFFIX = ('B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB');

sub finish {
  my $this = shift;

  $this->SUPER::finish();

  undef $this->{_params};
}

sub param {
  my ($this, $key) = @_;

  unless (defined $this->{_params}) {
    my %params = Foswiki::Func::extractParameters($this->{value});
    $this->{_params} = \%params;
  }

  return (defined $key)?$this->{_params}{$key}:$this->{_params};
}

sub getDefaultValue {
    my $this = shift;

    my $value =
      ( exists( $this->{default} ) ? $this->{default} : '' );
    $value = '' unless defined $value;

    return $value;
}

sub renderForEdit {
  my ($this, $topicObject, $value) = @_;

  return (
    '',
    CGI::textfield(
      -class => $this->cssClasses('foswikiInputField foswikiBytesField'),
      -name => $this->{name},
      -size => $this->{size},
      -override => 1,
      -value => $value,
      -data_rule_pattern => '^[+\-]?\d+(\.\d+)?$',
    )
  );
}

sub renderForDisplay {
  my ($this, $format, $value, $attrs) = @_;

  return '' unless defined $value && $value ne '';

  my $displayValue = $this->getDisplayValue($value);
  $format =~ s/\$value\(display\)/$displayValue/g;
  $format =~ s/\$value/$value/g;

  return $this->SUPER::renderForDisplay($format, $value, $attrs);
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

