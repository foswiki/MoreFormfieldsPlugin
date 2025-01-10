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

package Foswiki::Form::Phonenumber;

use strict;
use warnings;

use Foswiki::Render();
use Foswiki::Form::BaseField ();
use Foswiki::Form::Text ();
use Foswiki::Plugins::JQueryPlugin();
our @ISA = ('Foswiki::Form::Text', 'Foswiki::Form::BaseField');

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

  $this->addJavaScript();
  $this->addStyles();

  return (
    '',
    Foswiki::Render::html("input", {
      "type" => "text",
      "class" => $this->cssClasses('foswikiInputField foswikiPhoneNumber'),
      "name" => $this->{name},
      "size" => $this->{size},
      "value" => $value,
    })
  );
}

sub getDisplayValue {
  my ($this, $value) = @_;

  my $number = $value;
  $number =~ s/\s+//g;
  $number =~ s/\(.*?\)//g;
  $number =~ s/^\+/00/;

  my $prot = $this->param("protocol") || 'tel';

  return "<a href='$prot:$number' class='foswikiPhoneNumber'>$value</a>";
}

sub addJavaScript {
  #my $this = shift;

  Foswiki::Plugins::JQueryPlugin::createPlugin("validate");
  Foswiki::Func::addToZone("script", 
    "MOREFORMFIELDSPLUGIN::PHONENUMBER::JS",
    "<script src='%PUBURLPATH%/%SYSTEMWEB%/MoreFormfieldsPlugin/build/phonenumber.js'></script>", 
    "JQUERYPLUGIN::FOSWIKI, JQUERYPLUGIN::VALIDATE");
}

1;
