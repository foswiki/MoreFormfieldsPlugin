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

package Foswiki::Form::Natedit;

use strict;
use warnings;

use Foswiki::Form::Textarea ();
use Foswiki::Form::BaseField ();
use Foswiki::Func();

our @ISA = ('Foswiki::Form::Textarea', 'Foswiki::Form::BaseField'); 

sub new {
  my $class = shift;

  my $this = $class->SUPER::new(@_);

  if ($this->{size} =~ m/^\s*(\d+)x(\d+)\s*$/) {
    $this->{cols} = $1;
    $this->{rows} = $2;
  } else {
    $this->{cols} = 50;
    $this->{rows} = 4;
  }

  return $this;
}

sub getDefaultValue {
  my $this = shift;

  return $this->Foswiki::Form::BaseField::getDefaultValue(@_);
}

sub renderForEdit {
  my ($this, $topicObject, $value) = @_;

  Foswiki::Plugins::JQueryPlugin::createPlugin("natedit");
  my $web = $topicObject->web;
  my $topic = $topicObject->topic;
  Foswiki::Func::pushTopicContext($web, $topic);

  my @html5Data = ();

  foreach my $param (keys %{$this->param()}) {
    my $key = $param;
    my $val = $this->param($key);
    if ($key =~ /^(lineWrapping|engine|keymap|normalizeTables|purify|spellcheck)$/) {
      Foswiki::Func::setPreferencesValue("NATEDIT_".uc($key), $val);
      next;
    }
    if ($key =~ /^(nowysiwyg)$/) {
      Foswiki::Func::setPreferencesValue(uc($key), $val);
      next;
    }
    $key =~ s/([[:upper:]])/-\l$1/g;
    $key = 'data-'.$key unless $key eq 'style';
    push @html5Data, $key.'="'.$val.'"';
  }

  #Foswiki::Func::readTemplate("editbase");
  my $html5Data = Foswiki::Func::expandTemplate("natedit::options") || '';
  $html5Data = Foswiki::Func::expandCommonVariables($html5Data, $topic, $web, $topicObject) if $html5Data =~ /%/;
  $html5Data .= " " . join(" ", @html5Data);

  $value =~ s/</&lt;/g;
  $value =~ s/>/&gt;/g;

  my $classes = $this->cssClasses("foswikiTextarea", "natedit");

  my $textarea = '<textarea class="'.$classes.'" rows="'.$this->{rows}.'" cols="'.$this->{cols}.'" '.$html5Data." name='$this->{name}'>\n$value</textarea>";

  Foswiki::Func::popTopicContext();

  return ('', $textarea);
}

1;
