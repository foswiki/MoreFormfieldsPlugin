# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2010-2018 Michael Daum http://michaeldaumconsulting.com
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
package Foswiki::Form::Topic;

use strict;
use warnings;

use Foswiki::Func();
use Foswiki::Form::FieldDefinition ();
use Foswiki::Plugins::JQueryPlugin ();
use Assert;
our @ISA = ('Foswiki::Form::FieldDefinition');

sub new {
  my $class = shift;
  my $this = $class->SUPER::new(@_);

  Foswiki::Func::readTemplate("moreformfields");

  $this->{_formfieldClass} = 'foswikiTopicField';
  $this->{_web} = $this->param("web") || $this->{session}{webName};
  $this->{_url} = Foswiki::Func::expandTemplate("select2::topic::url");
  $this->{_thumbnailFormat} = Foswiki::Func::expandTemplate("select2::topic::thumbnail::url");

  return $this;
}

sub isMultiValued { return shift->{type} =~ /\+multi/; }
sub isValueMapped { return shift->{type} =~ /\+values/; }

sub getDefaultValue {
    my $this = shift;

    my $value = $this->{default};
    $value = '' unless defined $value;

    return $value;
}

sub finish {
  my $this = shift;
  $this->SUPER::finish();
  undef $this->{_params};
  undef $this->{_options};
  undef $this->{_descriptions};
}

sub renderForDisplay {
  my ($this, $format, $value, $attrs) = @_;

  my $displayValue = $this->getDisplayValue($value);
  $format =~ s/\$value\(display\)/$displayValue/g;
  $format =~ s/\$value/$value/g;

  return $this->SUPER::renderForDisplay($format, $value, $attrs);
}

sub populateMetaFromQueryData {
  my ($this, $query, $meta, $old) = @_;

  if ($this->isMultiValued()) {
    my @values = $query->multi_param($this->{name});

    if (scalar(@values) == 1 && defined $values[0]) {
      @values = split(/,|%2C/, $values[0]);
    }
    my %vset = ();
    foreach my $val (@values) {
      $val ||= '';
      $val =~ s/^\s*//o;
      $val =~ s/\s*$//o;

      # skip empty values
      $vset{$val} = (defined $val && $val =~ /\S/);
    }

    # populate options first
    $this->{_options} = [sort keys %vset];
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

  if ($this->isMultiValued) {
    my @result = ();
    foreach my $val (split(/\s*,\s*/, $value)) {
      my ($web, $topic) = Foswiki::Func::normalizeWebTopicName($this->{_web}, $val);
      if ($this->isValueMapped) {
        if (defined($this->{valueMap}{$val})) {
          $val = $this->{valueMap}{$val};
        }
      } else {
        $val = Foswiki::Func::getTopicTitle($web, $topic);
      }
      push @result, "<a href='%SCRIPTURLPATH{view}%/$web/$topic'>$val</a>";
    }
    $value = join(", ", @result);
  } else {
    my ($web, $topic) = Foswiki::Func::normalizeWebTopicName($this->{_web}, $value);
    if ($this->isValueMapped) {
      if (defined($this->{valueMap}{$value})) {
        $value = $this->{valueMap}{$value};
      }
    } else {
      $value = Foswiki::Func::getTopicTitle($web, $topic);
    }
    $value = "<a href='%SCRIPTURLPATH{view}%/$web/$topic'>$value</a>";
  }

  return $value;
}

sub param {
  my ($this, $key) = @_;

  unless (defined $this->{_params}) {
    my %params = Foswiki::Func::extractParameters($this->{value});
    $this->{_params} = \%params;
  }

  return (defined $key) ? $this->{_params}{$key} : $this->{_params};
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
  my $baseWeb = $this->{_web};
  my $baseTopic = $this->{session}{topicName};

  my @htmlData = ();
  push @htmlData, 'type="hidden"';
  push @htmlData, 'class="' . $this->cssClasses("foswikiTopicField", $this->{_formfieldClass}) . '"';
  push @htmlData, 'name="' . $this->{name} . '"';
  push @htmlData, 'value="' . $value . '"';

  my $size = $this->{size};
  if (defined $size) {
    $size .= "em";
  } else {
    $size = "element";
  }
  push @htmlData, 'data-width="' . $size . '"';

  if ($this->isMultiValued) {
    push @htmlData, 'data-multiple="true"';
    my @topicTitles = ();
    my @thumbnails = ();
    foreach my $v (split(/\s*,\s*/, $value)) {
      my $topicTitle = Foswiki::Func::getTopicTitle($baseWeb, $v)||$v;
      push @topicTitles, '"' . $v . '":"' . encode($topicTitle) . '"';
      my $thumb = $this->getThumbnailUrl($baseWeb, $v);
      push @thumbnails, '"' . $v .'":"'. $thumb . '"';
    }
    push @htmlData, "data-value-text='{" . join(', ', @topicTitles) . "}'";
    push @htmlData, "data-thumbnail='{" . join(', ', @thumbnails) . "}'";
  } else {
    my $topicTitle = encode(Foswiki::Func::getTopicTitle($baseWeb, $value));
    push @htmlData, 'data-value-text="' . $topicTitle . '"';
    my $thumb = $this->getThumbnailUrl($baseWeb, $value);
    push @htmlData, 'data-thumbnail="' .$thumb. '"';
  }

  unless (defined $this->param("url")) {
    if (defined $this->{_url}) {
      my $url = Foswiki::Func::expandCommonVariables($this->{_url}, $thisTopic, $thisWeb, $topicObject);
      push @htmlData, 'data-url="' . $url . '"';
    }
    push @htmlData, 'data-topic="' . $thisWeb . '.' . $thisTopic .'"';
  }

  while (my ($key, $val) = each %{$this->param()}) {
    $key = lc(Foswiki::spaceOutWikiWord($key, "-"));
    next if $key eq 'web';
    push @htmlData, 'data-' . $key . '="' . $val . '"';
  }
  push @htmlData, 'data-web="' . $baseWeb . '"';

  $this->addJavascript();
  $this->addStyles();

  my $field = "<input " . join(" ", @htmlData) . " />";

  return ('', $field);
}

sub addStyles {
  #my $this = shift;
  Foswiki::Func::addToZone("head", 
    "MOREFORMFIELDSPLUGIN::CSS", 
    "<link rel='stylesheet' href='%PUBURLPATH%/%SYSTEMWEB%/MoreFormfieldsPlugin/moreformfields.css' media='all' />",
    "JQUERYPLUGIN::SELECT2");
}

sub addJavascript {
  #my $this = shift;

  Foswiki::Plugins::JQueryPlugin::createPlugin("select2");
  Foswiki::Func::addToZone("script", "FOSWIKI::TOPICFIELD", <<"HERE", "JQUERYPLUGIN::SELECT2");
<script type='text/javascript' src='%PUBURLPATH%/%SYSTEMWEB%/MoreFormfieldsPlugin/topicfield.js'></script>
HERE
}

sub getThumbnailUrl {
  my ($this, $web, $topic, $size) = @_;

  $size ||= '32x32>';

  return "" unless $topic;

  ($web, $topic) = Foswiki::Func::normalizeWebTopicName($web, $topic);

  my $result = $this->{_thumbnailFormat};
  $result =~ s/\%web\%/$web/g;
  $result =~ s/\%topic\%/$topic/g;
  $result =~ s/\%size\%/$size/g;
  $result = Foswiki::Func::expandCommonVariables($result);

  return $result;
}


sub encode {
  my $text = shift;

  $text = Encode::encode_utf8($text) if $Foswiki::UNICODE;
  $text =~ s/([^0-9a-zA-Z-_.:~!*\/])/'%'.sprintf('%02x',ord($1))/ge;

  return $text;
}

1;
