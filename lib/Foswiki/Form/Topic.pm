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
package Foswiki::Form::Topic;

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

  $this->readTemplate("moreformfields");

  $this->{_formfieldClass} = 'foswikiTopicField';
  $this->{_web} = $this->param("web") || $this->{session}{webName};
  $this->{_url} = Foswiki::Func::expandTemplate("select2::topic::url");
  $this->{_templateName} = 'moreformfields';
  $this->{_definitionName} = 'select2::topic';
  $this->{_thumbnailFormat} = Foswiki::Func::expandTemplate("select2::topic::thumbnail::url");
  $this->{_separator} = $this->param("separator") // ", ";

  return $this;
}

sub finish {
  my $this = shift;
  $this->SUPER::finish();
  undef $this->{_options};
}

sub isMultiValued { return shift->{type} =~ /\+multi/ ? 1 : 0; }
sub isValueMapped { return shift->{type} =~ /\+values/ ? 1 : 0; }
sub isTextMergeable { return 0; }

sub populateMetaFromQueryData {
  my ($this, $query, $meta, $old) = @_;

  if ($this->isMultiValued()) {
    my @values = $query->multi_param($this->{name});

    if (scalar(@values) == 1 && defined $values[0]) {
      @values = grep {$_ ne ""} split(/,|%2C/, $values[0]);
    }

    my %seen = ();
    my @vset = ();
    foreach my $val (@values) {
      $val ||= '';
      $val =~ s/^\s*//;
      $val =~ s/\s*$//;
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

sub getWeb {
  my $this = shift;
  return $this->{_web};
}

sub getDisplayValue {
  my ($this, $value, $web) = @_;

  return '' unless defined $value && $value ne '';

  if ($this->isMultiValued) {
    my @result = ();
    $web //= $this->getWeb();
    foreach my $val (split(/\s*,\s*/, $value)) {
      next if $val eq "";
      my $class = $this->getFormfieldClass($val);
      my ($thisWeb, $thisTopic) = Foswiki::Func::normalizeWebTopicName($web, $val);
      if ($this->isValueMapped) {
        if (defined($this->{valueMap}{$val})) {
          $val = $this->{valueMap}{$val};
        }
      } else {
        $val = Foswiki::Func::getTopicTitle($thisWeb, $thisTopic);
      }
      my $url = Foswiki::Func::getScriptUrl($thisWeb, $thisTopic, "view");
      push @result, "<a href='$url' class='$class' data-web='$thisWeb' data-topic='$thisTopic'><noautolink>$val</noautolink></a>";
    }
    $value = join($this->{_separator}, @result);
  } else {
    my $class = $this->getFormfieldClass($value);
    my ($thisWeb, $thisTopic) = Foswiki::Func::normalizeWebTopicName($web, $value);
    if ($this->isValueMapped) {
      if (defined($this->{valueMap}{$value})) {
        $value = $this->{valueMap}{$value};
      }
    } else {
      $value = Foswiki::Func::getTopicTitle($thisWeb, $thisTopic);
    }
    my $url = Foswiki::Func::getScriptUrl($thisWeb, $thisTopic, "view");
    $value = "<a href='$url' class='$class' data-web='$thisWeb' data-topic='$thisTopic'><noautolink>$value</noautolink></a>";
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

  if ($this->isMultiValued) {
    $value = join(", ", grep {$_ ne ""} split(/\s*,\s*/, $value));
  }

  my $thisWeb = $topicObject->web;
  my $thisTopic = $topicObject->topic;
  $thisWeb =~ s/\//./g;

  my $baseWeb = $this->getWeb();
  my $baseTopic = $this->{session}{topicName};
  $baseWeb =~ s/\//./g;

  my @htmlData = ();
  push @htmlData, 'type="hidden"';
  push @htmlData, 'class="' . $this->cssClasses("foswikiTopicFieldEditor", $this->{_formfieldClass}) . '"';
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
      next if $v eq "";
      my $topicTitle = $this->getTopicTitle($baseWeb, $v);
      push @topicTitles, '"' . $v . '":"' . $this->encode($topicTitle) . '"';
      my $thumb = $this->getThumbnailUrl($baseWeb, $v);
      push @thumbnails, '"' . $v .'":"'. $thumb . '"';
    }
    push @htmlData, "data-value-text='{" . join(', ', @topicTitles) . "}'";
    push @htmlData, "data-thumbnail='{" . join(', ', @thumbnails) . "}'";
  } else {
    my $topicTitle = $this->encode($this->getTopicTitle($baseWeb, $value));
    push @htmlData, 'data-value-text="' . $topicTitle . '"';
    my $thumb = $this->getThumbnailUrl($baseWeb, $value);
    push @htmlData, 'data-thumbnail="' .$thumb. '"';
  }

  unless (defined $this->param("url")) {
    if (defined $this->{_url}) {
      my $url = $this->{_url} =~ /%/ ? Foswiki::Func::expandCommonVariables($this->{_url}, $thisTopic, $thisWeb, $topicObject) : $this->{_url};
      push @htmlData, 'data-url="' . $url . '"';
    }
    if (defined $this->{_templateName}) {
      push @htmlData, 'data-template-name="' . $this->{_templateName} . '"';
    }
    if (defined $this->{_definitionName}) {
      push @htmlData, 'data-definition-name="' . $this->{_definitionName} . '"';
    }
    push @htmlData, 'data-topic="' . $thisWeb . '.' . $thisTopic .'"';
  }

  while (my ($key, $val) = each %{$this->param()}) {
    $key = lc(Foswiki::spaceOutWikiWord($key, "-"));
    next if $key eq 'web';
    push @htmlData, 'data-' . $key . '="' . $val . '"';
  }
  push @htmlData, 'data-web="' . $baseWeb . '"';

  push @htmlData, 'data-relative="on"' if Foswiki::Func::isTrue($this->param("relative"));

  $this->addJavaScript();
  $this->addStyles();

  my $field = "<input " . join(" ", @htmlData) . " />";

  return ('', $field);
}

sub getTopicTitle {
  my ($this, $web, $topic) = @_;

  my $format = $this->param("format") // '$topictitle';
  $format = Foswiki::Func::decodeFormatTokens($format);

  my $topicTitle = Foswiki::Func::getTopicTitle($web, $topic);

  $format =~ s/\$topictitle\b/$topicTitle/g;
  $format =~ s/\$web\b/$web/g;
  $format =~ s/\$topic\b/$topic/g;
  $format = Foswiki::Func::expandCommonVariables($format, $topic, $web) if $format =~ /%/;

  return $format;
}

sub addJavaScript {

  Foswiki::Plugins::JQueryPlugin::createPlugin("select2");
  Foswiki::Func::addToZone("script", "FOSWIKI::TOPICFIELD", <<"HERE", "JQUERYPLUGIN::SELECT2");
<script src='%PUBURLPATH%/%SYSTEMWEB%/MoreFormfieldsPlugin/build/topicfield.js'></script>
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
  $result = Foswiki::Func::expandCommonVariables($result) if $result =~ /%/;

  return $result;
}

1;
