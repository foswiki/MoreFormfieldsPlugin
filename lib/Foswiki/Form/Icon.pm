# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2010-2017 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Form::Icon;

use strict;
use warnings;

use Foswiki::Plugins::JQueryPlugin ();
use Foswiki::Form::FieldDefinition ();
our @ISA = ('Foswiki::Form::FieldDefinition');

BEGIN {
  if ($Foswiki::cfg{UseLocale}) {
    require locale;
    import locale();
  }
}

sub new {
  my $class = shift;
  my $this = $class->SUPER::new(@_);

  my $size = $this->{size} || '';
  $size =~ s/\D//g;
  $size = 10 if (!$size || $size < 1);
  $this->{size} = $size;

  return $this;
}

sub param {
  my ($this, $key) = @_;

  unless (defined $this->{_params}) {
    my %params = Foswiki::Func::extractParameters($this->{value});
    $this->{_params} = \%params;
  }

  return (defined $key)?$this->{_params}{$key}:$this->{_params};
}

sub renderForEdit {
  my ($this, $topicObject, $value) = @_;

  Foswiki::Plugins::JQueryPlugin::createPlugin("fontawesome");
  Foswiki::Plugins::JQueryPlugin::createPlugin("select2");

  Foswiki::Func::addToZone("script", "FOSWIKI::ICONFIELD", <<'HERE', "JQUERYPLUGIN::FONTAWESOME, JQUERYPLUGIN::SELECT2");
<script type='text/javascript' src='%PUBURLPATH%/%SYSTEMWEB%/MoreFormfieldsPlugin/iconfield.js'></script>
HERE

  my @htmlData = ();
  push @htmlData, "type='hidden'";
  push @htmlData, "class='".$this->cssClasses("foswikiIconField")."'";
  push @htmlData, "name='$this->{name}'";
  push @htmlData, "value='$value'";
  
  my $cat = $this->param("cat");
  push @htmlData, "data-cat='$cat'" if $cat;

  my $include = $this->param("include");
  push @htmlData, "data-include='$include'" if $include;

  my $exclude = $this->param("exclude");
  push @htmlData, "data-exclude='$exclude'" if $exclude;

  my $size = $this->{size};
  if (defined $size) {
    $size .= "em";
  } else {
    $size = "element";
  }
  push @htmlData, 'data-width="'.$size.'"';

  my $field .= "<input ".join(" ", @htmlData)."></input>";

  return ('', $field);
}


sub renderForDisplay {
    my ( $this, $format, $value, $attrs ) = @_;

    Foswiki::Plugins::JQueryPlugin::createPlugin("fontawesome");

    my $displayValue = $this->getDisplayValue($value);
    $format =~ s/\$value\(display\)/$displayValue/g;
    $format =~ s/\$value/$value/g;

    return $this->SUPER::renderForDisplay( $format, $value, $attrs );
}

sub getDisplayValue {
    my ( $this, $value ) = @_;

    my $icon = Foswiki::Plugins::JQueryPlugin::handleJQueryIcon($this->{session}, {
      _DEFAULT => $value
    });

    my $text = $value;
    $text =~ s/^fa\-//;
    return $icon.' '.$text;
}

1;
