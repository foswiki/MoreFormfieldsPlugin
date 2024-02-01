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

package Foswiki::Form::Multitext;

use strict;
use warnings;

use Foswiki::Func ();
use Foswiki::Plugins::JQueryPlugin ();
use Foswiki::Form::Text ();
our @ISA = ('Foswiki::Form::Text', 'Foswiki::Form::BaseField'); 

sub isMultiValued { return 1; }
sub isTextMergeable { return 0; }

sub param {
  my ($this, $key) = @_;

  unless ($this->{_params}) {
    my %params = Foswiki::Func::extractParameters($this->{value});
    $this->{_params} = \%params;
  }

  return (defined $key) ? $this->{_params}{$key} : $this->{_params};
}

sub getDisplayValue {
  my ($this, $value) = @_;

  $value =~ s/([<>%'"])/'&#'.ord($1).';'/ge;
  my $sep = Foswiki::expandStandardEscapes($this->param("separator") || '\s*,\s*');

  return
    join("<span class='jqMultiTextSep'>, </span>", 
      map { "<span class='jqMultiTextItem'>$_</span>"} 
        split (/$sep/, $value));
}

sub getOptions {
  my $this = shift;

  my $query = Foswiki::Func::getCgiQuery();

  # trick this in
  my @values = ();
  my @valuesFromQuery = $query->multi_param($this->{name});
  my $sep = $this->param("separator") || '\s*,\s*';

  foreach my $item (@valuesFromQuery) {
    next unless defined $item;

    $item =~ s/^\s*//;
    $item =~ s/\s*$//;

    foreach my $value (split(/$sep/, $item)) {
      push @values, $value if defined $value;
    }
  }

  return \@values;
}

sub populateMetaFromQueryData {
  my ($this, $query, $meta, $old) = @_;
  my $value;
  my $bPresent = 0;

  return unless $this->{name};

  my %names = map { $_ => 1 } $query->multi_param;

  my $sep = Foswiki::expandStandardEscapes($this->param("separator") || ",");

  if ($names{$this->{name}}) {

    # Field is present in the request
    $bPresent = 1;
    my @values = $query->multi_param($this->{name});

    if (scalar(@values) == 1 && defined $values[0]) {
      @values = split(/$sep/, $values[0]);
    }
    my %vset = ();
    foreach my $val (@values) {
      $val ||= '';
      $val =~ s/^\s*//;
      $val =~ s/\s*$//;

      # skip empty values
      $vset{$val} = (defined $val && $val =~ m/\S/);
    }
    $value = '';
    my $isValues = ($this->{type} =~ m/\+values/);

    foreach my $option (@{$this->getOptions()}) {
      $option =~ s/^.*?[^\\]=(.*)$/$1/ if $isValues;

      # Maintain order of definition
      if ($vset{$option}) {
        $value .= $sep if length($value);
        $value .= $option;
      }
    }
  }

  # Find the old value of this field
  my $preDef;
  foreach my $item (@$old) {
    if ($item->{name} eq $this->{name}) {
      $preDef = $item;
      last;
    }
  }
  my $def;

  if (defined($value)) {

    # mandatory fields must have length > 0
    if ($this->isMandatory() && length($value) == 0) {
      return (0, $bPresent);
    }

    # NOTE: title and name are stored in the topic so that it can be
    # viewed without reading in the form definition
    my $title = $this->{title};
    if ($this->{definingTopic}) {
      $title = '[[' . $this->{definingTopic} . '][' . $title . ']]';
    }
    $def = $this->createMetaKeyValues(
      $query, $meta,
      {
        name => $this->{name},
        title => $title,
        value => $value
      }
    );
  } elsif ($preDef) {
    $def = $preDef;
  } else {
    return (0, $bPresent);
  }

  $meta->putKeyed('FIELD', $def) if $def;

  return (1, $bPresent);
}

sub addJavaScript {

  Foswiki::Func::addToZone("script", 
    "MOREFORMFIELDSPLUGIN::MULTITEXT::JS",
    "<script src='%PUBURLPATH%/%SYSTEMWEB%/MoreFormfieldsPlugin/multitext.js'></script>", 
    "JQUERYPLUGIN::FOSWIKI, JQUERYPLUGIN::UI");

  Foswiki::Plugins::JQueryPlugin::createPlugin("ui");
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

  my @html5Data = ();

  foreach my $param (keys %{$this->param()}) {
    my $key = $param;
    my $val = $this->param($key);
    $val = Foswiki::expandStandardEscapes($val);
    $val = _encode($val);

    $key =~ s/([[:upper:]])/-\l$1/g;
    $key = 'data-'.$key;
    push @html5Data, $key.'="'.$val.'"';
  }

  my $result = '<input type="text" '
    . 'class="'.$this->cssClasses('foswikiInputField jqMultiText').'" '
    . 'size="'.$this->{size}.'" '
    . 'name="'.$this->{name}.'" '
    . 'value="'._encode($value).'" '
    . join(" ", @html5Data).' />';

  return ('', $result);
}

sub _encode {
  my $text = shift;

  $text =~ s/([\r\n<>%'"])/'%'.sprintf('%02x',ord($1))/ge;

  return $text;
}

1;
