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
package Foswiki::Form::Attachment;

use strict;
use warnings;

use Foswiki::Func();
use Foswiki::Form::FieldDefinition ();
use Foswiki::Plugins::JQueryPlugin ();
our @ISA = ('Foswiki::Form::FieldDefinition');

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
  return $this;
}

sub isMultiValued { return (shift->{type} =~ m/\+multi/); }

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

sub param {
  my ($this, $key) = @_;

  unless (defined $this->{_params}) {
    my %params = Foswiki::Func::extractParameters($this->{value});
    $this->{_params} = \%params;
  }

  return (defined $key) ? $this->{_params}{$key} : $this->{_params};
}

sub getDisplayValue {
  my ($this, $value) = @_;

  return '' unless defined $value && $value ne '';

  my @result = ();
  my $format = Foswiki::Func::expandTemplate("attachments::preview");

  if ($this->isMultiValued) {
    foreach my $val (split(/\s*,\s*/, $value)) {
      my $line = $format;
      $line =~ s/\$file/$val/g;
      push @result, $line;
    }
  } else {
    $format =~ s/\$file/$value/g;
    push @result, $format;
  }

  return Foswiki::Func::expandCommonVariables(join("", @result), $this->{_topic}, $this->{_web});
}

sub renderForDisplay {
  my ($this, $format, $value, $attrs) = @_;

  my $displayValue = $this->getDisplayValue($value);
  $format =~ s/\$value\(display\)/$displayValue/g;
  $format =~ s/\$value/$value/g;

  return $this->SUPER::renderForDisplay($format, $value, $attrs);
}

sub renderForEdit {
  my ($this, $topicObject, $value) = @_;

  $this->getOptions($topicObject);

  my @htmlData = ();
  push @htmlData, 'type="hidden"';
  push @htmlData, 'class="' . $this->cssClasses($this->{_formfieldClass}) . '"';
  push @htmlData, 'name="' . $this->{name} . '"';
  push @htmlData, 'value="' . $value . '"';

  my @uploadButtonHtmlData = ();
  push @uploadButtonHtmlData, "data-topic='%WEB%.%TOPIC%'";
  push @uploadButtonHtmlData, "data-auto-upload='false'";

  my $size = $this->{size};
  if (defined $size) {
    $size .= "em";
  } else {
    $size = "element";
  }
  push @htmlData, 'data-width="' . $size . '"';

  unless (defined $this->param("url")) {
    if (defined $this->{_url}) {
      my $url = Foswiki::Func::expandCommonVariables($this->{_url}, $this->{_topic}, $this->{_web});
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

  if ($this->isMultiValued) {
    push @htmlData, 'data-multiple="true"';
  }

  $this->addJavascript();
  $this->addStyles();

  my $htmlData = join(" ", @htmlData);
  my $result = "<input $htmlData />";

  my $uploadButtonHtmlData = join(" ", @uploadButtonHtmlData);
  my $name = "_" . $this->{name} . ($this->isMultiValued ? '[]' : '');
  $result .= <<HERE;
 <span class='jqButton jqButtonSimple jqUploadButton' $uploadButtonHtmlData>
  <i class='jqButtonIcon fa-fw fa fa-upload'></i>
  <input type='file' name='$name' / >
</span>
HERE

  return ('', $result);
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

  Foswiki::Plugins::JQueryPlugin::createPlugin("fontawesome");
  Foswiki::Plugins::JQueryPlugin::createPlugin("uploader");
  Foswiki::Plugins::JQueryPlugin::createPlugin("select2");
  Foswiki::Func::addToZone("script", "FOSWIKI::ATTACHMENTFIELD", <<"HERE", "JQUERYPLUGIN::SELECT2, JQUERYPLUGIN::UPLOADER");
<script type='text/javascript' src='%PUBURLPATH%/%SYSTEMWEB%/MoreFormfieldsPlugin/attachmentfield.js'></script>
HERE
}

1;
