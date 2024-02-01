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
package Foswiki::Form::Attachment;

use strict;
use warnings;

use Foswiki::Func();
use Foswiki::Form::BaseField ();
use Foswiki::Plugins::JQueryPlugin ();
our @ISA = ('Foswiki::Form::BaseField');

sub new {
  my $class = shift;
  my $this = $class->SUPER::new(@_);
  my $size = $this->{size} || '';
  $size =~ s/\D//g;
  $size = 10 if (!$size || $size < 1);
  $this->{size} = $size;

  Foswiki::Func::readTemplate("moreformfields");

  $this->{_formfieldClass} = 'foswikiAttachmentField';
  $this->{_web} = $this->param("web") || $this->{session}{webName};
  $this->{_topic} = $this->param("topic") || $this->{session}{topicName};
  $this->{_url} = Foswiki::Func::expandTemplate("select2::attachments::url");
  $this->{_enableUpload} = Foswiki::Func::isTrue($this->param("upload"));
  return $this;
}

sub isMultiValued { return (shift->{type} =~ m/\+multi/); }

sub isTextMergeable { return 0; }

sub finish {
  my $this = shift;
  $this->SUPER::finish();
  undef $this->{_options};
}

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
  my ($this, $topicObject) = @_;

  return $this->{_options} if $this->{_options};

  if ($topicObject) {
    $this->{_options} = [''];

    foreach my $attachment ($topicObject->find('FILEATTACHMENT')) {
      push @{$this->{_options}}, $attachment->{name};
    }

    return $this->{_options};
  }

  return [];
}

sub getDisplayValue {
  my ($this, $value, $web, $topic) = @_;

  return '' unless defined $value && $value ne '';

  $web ||= $this->{_web};
  $topic ||= $this->{_topic};

  my @result = ();
  my $format = Foswiki::Func::expandTemplate("attachments::preview");

  if ($this->isMultiValued) {
    foreach my $val (split(/\s*,\s*/, $value)) {
      my $line = $format;
      my ($href, $cls) = _getHref($web, $topic, $val);
      $line =~ s/\$file\b/$val/g;
      $line =~ s/\$href\b/$href/g;
      $line =~ s/\$class\b/$cls/g;
      push @result, $line;
    }
  } else {
    my ($href, $cls) = _getHref($web, $topic, $value);
    $format =~ s/\$file\b/$value/g;
    $format =~ s/\$href\b/$href/g;
    $format =~ s/\$class\b/$cls/g;
    push @result, $format;
  }

  $this->addStyles();

  my $result = join("", @result);
  return $result =~ /%/ ? Foswiki::Func::expandCommonVariables($result, $topic, $web) : $result;
}

sub _getHref {
  my ($web, $topic, $attachment) = @_;

  my $href = Foswiki::Func::getPubUrlPath($web, $topic, $attachment);
  my $cls = "";
  if (Foswiki::Func::getContext()->{TopicInteractionPluginEnabled}) {
    my $webDAVFilter = $Foswiki::cfg{TopicInteractionPlugin}{WebDAVFilter};
    my $encName = Foswiki::urlEncode($attachment);

    if (defined($webDAVFilter) && $attachment =~ /\.($webDAVFilter)$/i) {
      my $webDavUrl = $Foswiki::cfg{TopicInteractionPlugin}{WebDAVUrl} || 'webdav://$host/dav/$web/$topic_files/$attachment';
      my $host = Foswiki::Func::getUrlHost();
      $webDavUrl =~ s/\$host/$host/g;
      $webDavUrl =~ s/\$web/$web/g;
      $webDavUrl =~ s/\$topic/$topic/g;
      $webDavUrl =~ s/\$attachment/$encName/g;

      $href = $webDavUrl;
      $cls = "jqWebDAVLink";
    }
  }

  return wantarray ? ($href, $cls) : $href;
}

sub renderForEdit {
  my ($this, $topicObject, $value) = @_;

  my $default = $this->getDefaultValue();
  $value = "" if $value eq $default; # don't insert default

  $this->getOptions($topicObject);

  my $web = $topicObject->web;
  my $topic = $topicObject->topic;

  my @htmlData = ();
  push @htmlData, 'type="hidden"';
  push @htmlData, 'class="' . $this->cssClasses($this->{_formfieldClass}) . '"';
  push @htmlData, 'name="' . $this->{name} . '"';
  push @htmlData, 'value="' . $value . '"';
  push @htmlData, 'data-multiple="true"' if $this->isMultiValued;

  my @uploadButtonHtmlData = ();
  push @uploadButtonHtmlData, "data-topic='$web.$topic'";
  push @uploadButtonHtmlData, "data-auto-upload='false'";
  push @uploadButtonHtmlData, "data-multi-file-upload='true'" if $this->isMultiValued;

  my $size = $this->{size};
  if (defined $size) {
    $size .= "em";
  } else {
    $size = "element";
  }
  push @htmlData, 'data-width="' . $size . '"';

  unless (defined $this->param("url")) {
    if (defined $this->{_url}) {
      my $url = $this->{_url};
      $url = $url =~ /%/ ? Foswiki::Func::expandCommonVariables($url, $this->{_topic}, $this->{_web}) : $url;
      push @htmlData, 'data-url="' . $url . '"';
    }
    push @htmlData, 'data-topic="' . $this->{_web} . '.' . $this->{_topic} .'"';
  }

  while (my ($key, $val) = each %{$this->param()}) {
    next if $key =~ /^_DEFAULT$/;
    $key = lc(Foswiki::spaceOutWikiWord($key, "-"));
    if ($key eq 'filter') {
      $val = join("|", split(/\s*,\s*/, $val));
      push @uploadButtonHtmlData, 'data-accept-file-types-="' . $val . '"';
      push @htmlData, 'data-' . $key . '="' . $val . '"';
    } else {
      push @htmlData, 'data-' . $key . '="' . $val . '"';
    }
  }


  $this->addJavaScript();
  $this->addStyles();

  my $htmlData = join(" ", @htmlData);
  my $result = "<input $htmlData />";

  my $uploadButtonHtmlData = join(" ", @uploadButtonHtmlData);
  my $input = "<input type='file' name='_$this->{name}' / >";
  $input = "<input type='file' name='_".$this->{name}."[]' multiple / >" if $this->isMultiValued;

  if ($this->{_enableUpload}) {
    $result .= <<HERE;
 <span class='jqButton jqButtonSimple jqUploadButton' $uploadButtonHtmlData>
  <i class='jqButtonIcon fa-fw fa fa-upload'></i>
  $input
</span>
HERE
  }

  return ('', $result);
}

sub addJavaScript {
  #my $this = shift;

  Foswiki::Plugins::JQueryPlugin::createPlugin("fontawesome");
  Foswiki::Plugins::JQueryPlugin::createPlugin("uploader");
  Foswiki::Plugins::JQueryPlugin::createPlugin("select2");
  Foswiki::Func::addToZone("script", "FOSWIKI::ATTACHMENTFIELD", <<"HERE", "JQUERYPLUGIN::SELECT2, JQUERYPLUGIN::UPLOADER");
<script src='%PUBURLPATH%/%SYSTEMWEB%/MoreFormfieldsPlugin/attachmentfield.js'></script>
HERE
}

1;
