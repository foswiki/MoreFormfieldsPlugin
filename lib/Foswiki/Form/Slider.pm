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

package Foswiki::Form::Slider;

use strict;
use warnings;

use Foswiki::Form::Select ();
use Foswiki::Form::BaseField ();
use Foswiki::Plugins::JQueryPlugin ();
our @ISA = ('Foswiki::Form::BaseField');

use Assert;

sub new {
    my $class = shift;
    my $this  = $class->SUPER::new(@_);

    return $this;
}

sub isValueMapped { return ( shift->{type} =~ m/\+values/ ); }
sub isTextMergeable { return 0; }

sub getDefaultValue {
  my $this = shift;

  my $value = $this->{default};
  $value = $this->param("default") unless defined($value) && $value ne "";
  return $value if defined($value) && $value ne "";

  my $values = $this->getOptions();
  if ($values && @$values) {
    $value = shift @$values;
  } else {
    $value = 0;
  }

  return $value;
}

sub renderForEdit {
  my ($this, $obj, $value) = @_;

  $value = $this->getDefaultValue() if !defined($value) || $value eq '';

  return ('', $this->_html($value));
}

sub getOptions {
  my $this = shift;

  my $values = $this->param("_DEFAULT") // $this->param("values"); # SMELL?
  return unless defined $values;

  my @values = ();
  if ($this->isValueMapped) {
    $this->{valueMap} = ();
    foreach my $val (split/\s*,\s*/, $values) {
      if ($val =~ /^\s*(.*?)\s*=\s*(.*?)\s*$/) {
        $this->{valueMap}{$2} = $1;
        push @values, $2;
      }
    }
  } else {
    @values = split(/\s*,\s*/, $values);
  }

  return \@values;
}

sub getDisplayValue {
  my ($this, $value) = @_;

  $this->getOptions();
  $value = $this->getDefaultValue() if !defined($value) || $value eq '';

  my $range = $this->getRange() // '';
  my $format = $this->getFormat();

  if ($range eq 'true') {
    my ($from, $to) = split(/\s*,\s*/, $value);

    $from //= 0;
    $to //= $from;

    if ($this->isValueMapped) {
      $from = $this->{valueMap}{$from} // $from;
      $to = $this->{valueMap}{$to} // $to;
    }

    return sprintf($format, $from, $to);
  }

  $value = $this->{valueMap}{$value} // $value if $this->isValueMapped;

  return sprintf($format, $value);
}

sub getFormat {
  my $this = shift;

  my $format = $this->param("format");
  return $format if defined($format) && $format ne "";
  
  my $range = $this->getRange() // '';

  return "%s - %s" if $range eq 'true';
  return "%s";
}

sub getRange {
  my $this = shift;

  my $range = $this->param("range");
  return unless defined $range;

  unless ($range =~ /^(min|max)$/) {
    $range = Foswiki::Func::isTrue($range, 0) ? "true": "false";
  }

  return $range;
}

sub _html {
  my ($this, $value, $isReadOnly) = @_;

  my @html5Data = ();
  push @html5Data, "data-name='$this->{name}'";
  push @html5Data, "data-animate='true'";

  my $values = $this->getOptions();
  if ($values && @$values) {
    if ($this->isValueMapped()) {
      push @html5Data, "data-is-mapped='true'";
      push @html5Data, "data-mapped-values='{".join(', ', map {'"'.$_.'":"'.$this->{valueMap}{$_}.'"'} @$values)."}'";
    } else {
      push @html5Data, "data-is-mapped='false'";
      push @html5Data, "data-mapped-values='[".join(', ', map {'"'.$_.'"'} @$values)."]'";
    }
    push @html5Data, "data-max='".(scalar(@$values)-1)."'";
  } else {

    my $min = $this->param("min") // 0;
    push @html5Data, "data-min='$min'";

    my $max = $this->param("max") // 100;
    push @html5Data, "data-max='$max'";

    my $step = $this->param("step") // 1;
    push @html5Data, "data-step='$step'";

    push @html5Data, "data-format='".$this->getFormat()."'";
  }

  my $range = $this->getRange();
  push @html5Data, "data-range='$range'" if defined $range;

  push @html5Data, "data-disabled='true'" if $isReadOnly;

  my $size = $this->{size};
  $size =~ s/\D//g;
  $size = 10 if $size < 10;
  $size += 10; # mitigate label width

  my $html = "<div class='jqSliderContainer' style='width:${size}em' ".join(" ", @html5Data)."><input type='hidden' name='$this->{name}' value='$value' /></div>";

  $this->addJavaScript();
  $this->addStyles();

  return $html;
}

sub addJavaScript {
  #my $this = shift;

  Foswiki::Plugins::JQueryPlugin::createPlugin("ui::slider");
  Foswiki::Plugins::JQueryPlugin::createPlugin("sprintf");

  Foswiki::Func::addToZone("script", "MOREFORMFIELDSPLUGIN::SLIDERFIELD", <<"HERE", "JQUERYPLUGIN::UI::SLIDER", "JQUERYPLUGIN::SPRINTF");
<script src='%PUBURLPATH%/%SYSTEMWEB%/MoreFormfieldsPlugin/build/slider.js'></script>
HERE
}

1;
