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
package Foswiki::Form::Web;

use strict;
use warnings;

use Foswiki::Func();
use Foswiki::Form::BaseField ();
use Foswiki::Plugins::JQueryPlugin ();
use Assert;
our @ISA = ('Foswiki::Form::BaseField');

sub new {
  my $class = shift;
  my $this = $class->SUPER::new(@_);

  Foswiki::Func::readTemplate("moreformfields");

  $this->{_formfieldClass} = 'foswikiWebField';
  $this->{_url} = Foswiki::Func::expandTemplate("select2::web::url");

  return $this;
}

sub finish {
  my $this = shift;
  $this->SUPER::finish();
  undef $this->{_options};
}

sub isMultiValued { return shift->{type} =~ /\+multi/; }
sub isValueMapped { return shift->{type} =~ /\+values/; }
sub isTextMergeable { return 0; }

sub populateMetaFromQueryData {
  my ($this, $query, $meta, $old) = @_;

  if ($this->isMultiValued()) {
    my @values = $query->multi_param($this->{name});

    if (scalar(@values) == 1 && defined $values[0]) {
      @values = split(/,|%2C/, $values[0]);
    }
    my %seen = ();
    my @vset = ();
    foreach my $val (@values) {
      $val ||= '';
      $val =~ s/^\s*//o;
      $val =~ s/\s*$//o;
      next if $seen{$val};

      # skip empty values
      if (defined $val && $val =~ /\S/) {
        push @vset, $val; # preserve order
        $seen{$val} = 1;
      }
    }

    # populate options first
    $this->{_options} = \@vset;
  }

  return $this->SUPER::populateMetaFromQueryData($query, $meta, $old);
}

sub getOptions {
  my $this = shift;
  return $this->{_options};
}

sub getDisplayValue {
  my ($this, $value) = @_;

  return '' unless defined $value && $value ne '';

  my $webHome = $Foswiki::cfg{HomeTopicName};

  if ($this->isMultiValued) {
    my @result = ();
    foreach my $val (split(/\s*,\s*/, $value)) {
      my $text;
      if ($this->isValueMapped) {
        if (defined($this->{valueMap}{$val})) {
          $text = $this->{valueMap}{$val};
        }
      } else {
        $text = Foswiki::Func::getTopicTitle($val, $webHome);
      }
      my $url = Foswiki::Func::getScriptUrl($val, $webHome, "view");
      push @result, "<a href='$url' class='".$this->{_formfieldClass}."'>$text</a>";
    }
    $value = join(", ", @result);
  } else {
    my $text;
    if ($this->isValueMapped) {
      if (defined($this->{valueMap}{$value})) {
        $text = $this->{valueMap}{$value};
      }
    } else {
      $text = Foswiki::Func::getTopicTitle($value, $webHome);
    }
    my $url = Foswiki::Func::getScriptUrl($value, $webHome, "view");
    $value = "<a href='$url' class='".$this->{_formfieldClass}."'>$text</a>";
  }

  return $value;
}

sub renderForEdit {
  my ($this, $param1, $param2, $param3) = @_;

  my $value;
  my $web;
  my $topic;
  my $topicObject;
  if (ref($param1)) {    # Foswiki > 1.1
    $topicObject = $param1;
    $value = $param2;
  } else {
    $web = $param1;
    $topic = $param2;
    $value = $param3;
  }

  my $thisWeb = $topicObject->web;
  my $thisTopic = $topicObject->topic;

  my @htmlData = ();
  push @htmlData, 'type="hidden"';
  push @htmlData, 'class="' . $this->cssClasses("foswikiWebFieldEditor", $this->{_formfieldClass}) . '"';
  push @htmlData, 'name="' . $this->{name} . '"';
  push @htmlData, 'value="' . $value . '"';

  my $size = $this->{size};
  if (defined $size) {
    $size .= "em";
  } else {
    $size = "element";
  }
  push @htmlData, 'data-width="' . $size . '"';

  my $webHome = $Foswiki::cfg{HomeTopicName};
  if ($this->isMultiValued) {
    push @htmlData, 'data-multiple="true"';
    my @topicTitles = ();
    foreach my $v (split(/\s*,\s*/, $value)) {
      my $topicTitle = Foswiki::Func::getTopicTitle($v, $webHome);
      push @topicTitles, '"' . $v . '":"' . $this->encode($topicTitle) . '"';
    }
    push @htmlData, "data-value-text='{" . join(', ', @topicTitles) . "}'";
  } else {
    my $topicTitle = $this->encode(Foswiki::Func::getTopicTitle($value, $webHome));
    push @htmlData, 'data-value-text="' . $topicTitle . '"';
  }

  unless (defined $this->param("url")) {
    if (defined $this->{_url}) {
      my $url = $this->{_url} =~ /%/ ? Foswiki::Func::expandCommonVariables($this->{_url}, $thisTopic, $thisWeb, $topicObject) : $this->{_url};
      push @htmlData, 'data-url="' . $url . '"';
    }
    push @htmlData, 'data-topic="' . $thisWeb . '.' . $thisTopic .'"';
  }

  while (my ($key, $val) = each %{$this->param()}) {
    $key = lc(Foswiki::spaceOutWikiWord($key, "-"));
    next if $key eq 'web';
    push @htmlData, 'data-' . $key . '="' . $val . '"';
  }

  $this->addJavaScript();
  $this->addStyles();

  my $field = "<input " . join(" ", @htmlData) . " />";

  return ('', $field);
}

sub addJavaScript {
  #my $this = shift;

  Foswiki::Plugins::JQueryPlugin::createPlugin("select2");
  Foswiki::Func::addToZone("script", "FOSWIKI::WEBFIELD", <<"HERE", "JQUERYPLUGIN::SELECT2");
<script src='%PUBURLPATH%/%SYSTEMWEB%/MoreFormfieldsPlugin/webfield.js'></script>
HERE
}

1;
