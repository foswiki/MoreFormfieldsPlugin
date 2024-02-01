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

package Foswiki::Form::Icon;

use strict;
use warnings;

use Foswiki::Plugins::JQueryPlugin ();
use Foswiki::Form::BaseField ();
our @ISA = ('Foswiki::Form::BaseField');

sub new {
  my $class = shift;
  my $this = $class->SUPER::new(@_);

  my $size = $this->{size} || '';
  $size =~ s/\D//g;
  $size = 10 if (!$size || $size < 1);
  $this->{size} = $size;

  return $this;
}

sub isTextMergeable { return 0; }

sub renderForEdit {
  my ($this, $topicObject, $value) = @_;

  Foswiki::Plugins::JQueryPlugin->getIconService()->loadAllIconFonts();
  $this->addJavaScript();

  my @htmlData = ();
  push @htmlData, "type='hidden'";
  push @htmlData, "class='" . $this->cssClasses("foswikiIconField") . "'";
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
  push @htmlData, 'data-width="' . $size . '"';

  my $field = "<input " . join(" ", @htmlData) . "></input>";

  return ('', $field);
}

sub addJavaScript {
  my $this = shift;

  Foswiki::Plugins::JQueryPlugin::createPlugin("select2");
  Foswiki::Func::addToZone("script", "FOSWIKI::ICONFIELD", <<'HERE', "JQUERYPLUGIN::SELECT2");
<script src='%PUBURLPATH%/%SYSTEMWEB%/MoreFormfieldsPlugin/iconfield.js'></script>
HERE
}

sub getDisplayValue {
  my ($this, $value) = @_;

  return Foswiki::Plugins::JQueryPlugin::getIconService->renderIcon($value);
}

1;
