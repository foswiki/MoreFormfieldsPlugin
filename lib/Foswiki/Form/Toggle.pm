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

package Foswiki::Form::Toggle;

use strict;
use warnings;
use Assert;

use Foswiki::Form::BaseField ();
use Foswiki::Func ();
use Foswiki::Sandbox ();
use Foswiki::Render ();
use Foswiki::Meta ();

our @ISA = ('Foswiki::Form::BaseField');

sub new {
  my $class = shift;
  my $this = $class->SUPER::new(@_);

  $this->{_formfieldClass} = 'foswikiToggleButton';
  $this->{size} ||= 2;
  $this->{size} = 2 if $this->{size} > 2;

  $this->getOptions();

  return $this;
}

sub isValueMapped { return (shift->{type} =~ m/\+values/); }

sub isTextMergeable { return 0; }

sub isEnabled {
  my ($this, $value) = @_;

  return ($value eq $this->{options}->[0]) ? 1 : 0;
}

sub finish {
  my $this = shift;
  $this->SUPER::finish();

  undef $this->{valueMap};
  undef $this->{options};
}

sub getOptions {
  my $this = shift;

  return $this->{options} if $this->{options};

  my @vals = ();

  my $default;
  if ($this->isValueMapped) {
    $default = ($this->{size} == 1) ? "on=1": "on=1, off=0";
  } else {
    $default = ($this->{size} == 1) ? "on": "on, off";
  }

  @vals = split(/\s*,\s*/, $this->{value} || $default);

  if (!scalar(@vals)) {
    my $topic = $this->{definingTopic} || $this->{name};
    my $session = $this->{session};

    my ($fieldWeb, $fieldTopic) =
      $session->normalizeWebTopicName($this->{web}, $topic);

    $fieldWeb = Foswiki::Sandbox::untaint($fieldWeb, \&Foswiki::Sandbox::validateWebName);
    $fieldTopic = Foswiki::Sandbox::untaint($fieldTopic, \&Foswiki::Sandbox::validateTopicName);

    if ($session->topicExists($fieldWeb, $fieldTopic)) {

      my $meta = Foswiki::Meta->load($session, $fieldWeb, $fieldTopic);
      if ($meta->haveAccess('VIEW')) {

        # Process SEARCHES for Lists
        my $text = $$meta->text();
        $text = $meta->expandMacros($text) if $text =~ /%/;

        # SMELL: yet another table parser
        my $inBlock = 0;
        foreach (split(/\r?\n/, $text)) {
          if (/^\s*\|\s*\*Name\*\s*\|/) {
            $inBlock = 1;
          } elsif (/^\s*\|\s*([^|]*?)\s*\|(?:\s*([^|]*?)\s*\|)?/) {
            if ($inBlock) {
              push @vals, $1;
            }
          } else {
            $inBlock = 0;
          }
        }
      }
    }
  }
  @vals = map { my $tmp = $_; $tmp =~ s/^\s*(.*?)\s*$/$1/; $tmp; } @vals;
  @vals = map { my $tmp = $_; $tmp = HTML::Entities::decode_entities($tmp); $tmp } @vals;

  if ($this->isValueMapped()) {

    # create a values map
    $this->{valueMap} = ();
    $this->{options} = [];

    my $str;
    foreach my $val (@vals) {
      if ($val =~ m/^(.*[^\\])*=(.*)$/) {
        $str = $1 || '';    # label
        $val = $2;
        $str =~ s/\\=/=/g;
      } else {
        $str = $val;
      }

      $str =~ s/%([\da-f]{2})/chr(hex($1))/gei;

      $this->{valueMap}{$val} = $str;
      push @{$this->{options}}, $val;
    }
  } else {
    $this->{options} = \@vals;
  }

  return $this->{options};
}


sub getDisplayValue {
  my ($this, $value) = @_;

  # SMELL: shouldn't this be in getDisplayValue?
  if (defined($this->{valueMap}{$value})) {
    $value = $this->{valueMap}{$value};
  }

  return $value;
}

sub renderForEdit {
  my ($this, $obj, $value) = @_;

  $value //= $this->getDefaultValue($obj->web, $obj->topic);

  my $attrs = {
    type => "checkbox",
    class => $this->{_formfieldClass},
    name => $this->{name},
    value => $this->{options}->[0],
  };
  $attrs->{checked} = "checked" if $this->isEnabled($value);

  my $result;

  if ($this->{size} > 1) {
    $result = Foswiki::Render::html(
      "label", undef,

      Foswiki::Render::html("input", $attrs) .
      Foswiki::Render::html(
        "span", {
          class => 'foswikiToggleOnValue',
          style => $this->isEnabled($value) ? '' : 'display:none',
        },
        $this->getDisplayValue($this->{options}->[0])
      ) .
      Foswiki::Render::html(
        "span", {
          class => 'foswikiToggleOffValue',
          style => $this->isEnabled($value) ? 'display:none' : '',
        },
        $this->getDisplayValue($this->{options}->[1])
      ). 
      Foswiki::Render::html(
        "input", {
          type => 'hidden',
          name => $this->{name},
          value => $this->{options}->[1]
        }
      )
    );
  } else {
    $result = Foswiki::Render::html(
      "label", undef,
      Foswiki::Render::html("input", $attrs).
      Foswiki::Render::html(
        "span", {
          class => 'foswikiToggleValue',
        },
        $this->getDisplayValue($this->{options}->[0])
      ).
      Foswiki::Render::html(
        "input", {
          type => 'hidden',
          name => $this->{name},
          value => ""
        }
      )
    );
  }

  $this->addStyles();

  return ("", $result);
}

1;
