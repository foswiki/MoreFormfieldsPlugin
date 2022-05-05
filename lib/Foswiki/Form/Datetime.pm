# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2021-2022 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Form::Datetime;

use strict;
use warnings;

use Foswiki::Form::Date2 ();
use Foswiki::Plugins::JQueryPlugin ();
use Foswiki::Time ();
our @ISA = ('Foswiki::Form::Date2');

sub getDateTimeFormat {
  my $this = shift;

  return $this->param("format") || $Foswiki::cfg{DateManipPlugin}{DefaultDateTimeFormat} || '%d %b %Y - %H:%M';
}

sub formatDate {
  my ($this, $epoch, $params) = @_;

  $params ||= $this->param();
  $params->{lang} = $this->getLang();

  my $dateFormat = $this->getDateTimeFormat();
  my $timezone = $params->{tz} || $this->param("timezone") || $Foswiki::cfg{DisplayTimeValues} || 'servertime';

  return Foswiki::Time::formatTime($epoch, $dateFormat, $timezone, $params);
}

#use Data::Dump qw(dump);
sub saveMetaDataHandler {
  my ($this, $record, $formDef) = @_;

  my $fieldName = $this->{name};
  #print STDERR "called saveMetaDataHandler($fieldName)\n";
  #print STDERR "... record=".dump($record)."\n";

  my $dateStr;
  my $timeStr;

  my $request = Foswiki::Func::getRequestObject();
  foreach my $urlParam ($request->param()) {
    unless ($urlParam =~ /^META:(.*?):(id\d*):(.+)$/) {
      #print STDERR "urlParam does not match: $urlParam\n";
      next;
    }
    #print STDERR "got urlParam=$urlParam\n";
    my $metaDataName = $1;
    my $name = $2;
    my $field = $3;

    #print STDERR "...metaDataName=$metaDataName, name=$name, field=$field\n";
    if ($field =~ /${fieldName}_date/) {
      $dateStr = $request->param($urlParam);
    }
    if ($field =~ /${fieldName}_time/) {
      $timeStr = $request->param($urlParam);
    }

    last if $dateStr && $timeStr;
  }

  delete $record->{"${fieldName}_date"};
  delete $record->{"${fieldName}_time"};

  return unless $dateStr && $timeStr;

  $record->{$fieldName} = $this->combineDateTime($dateStr, $timeStr);
}

sub beforeSaveHandler {
  my ($this, $meta, $form) = @_;

  my $request = Foswiki::Func::getRequestObject();
  my $dateStr = $request->param($this->{name} . '_date');
  my $timeStr = $request->param($this->{name} . '_time');
  return unless defined $dateStr && defined $timeStr;

  my $epoch = $this->combineDateTime($dateStr, $timeStr);
  my $reformat = $epoch ? $this->formatDate($epoch) : "";
  #print STDERR "date=$dateStr, time=$timeStr, epoch=$epoch, reformat=$reformat\n";

  my $field = $meta->get('FIELD', $this->{name});
  $field //= {
    name => $this->{name},
    title => $this->{name},
  };
  $field->{value} = $epoch ? $epoch : "";
  $field->{origvalue} = $reformat;

  $meta->putKeyed('FIELD', $field);
}

sub combineDateTime {
  my ($this, $dateStr, $timeStr) = @_;

  my $dateEpoch = $this->parseDate($dateStr) // 0;
  my $timeEpoch = 0;
  if ($timeStr =~ /^\s*(\d\d):(\d\d)\s*$/) {
    $timeEpoch += $1 * 3600 + $2 * 60;
  }

  return $dateEpoch + $timeEpoch;
}

sub renderForEdit {
  my ($this, $meta, $value) = @_;

  my ($web, $topic);

  unless (ref($meta)) {
    # Pre 1.1
    ($this, $web, $topic, $value) = @_;
    undef $meta;
  }

  Foswiki::Plugins::JQueryPlugin::createPlugin("ui::datepicker");
  Foswiki::Plugins::JQueryPlugin::createPlugin("clockpicker");

  my $epoch;
  if ($value =~ /^\-?\d+$/) {
    $epoch = $value;
  } else {
    $epoch = $this->parseDate($value, {tz => "GMT"});
    $value = $epoch if defined $epoch;
  }

  my $dateFormat = $this->convertFormatToJQueryUI($this->getDateFormat());
  my $timeValue = $value ? Foswiki::Time::formatTime($value, "%H:%M") : "";

  my $html = Foswiki::Render::html("input", {
      type => "text",
      name => $this->{name} . '_date',
      id => 'id' . $this->{name} . int(rand() * 1000),
      size => $this->{size},
      value => $value ? $value : "",
      "data-auto-size" => "true",
      "data-change-month" => "true",
      "data-change-year" => "true",
      "data-date-format" => $dateFormat,
      "data-lang" => $this->getLang(),
      "data-show-on" => "both",
      "class" => $this->cssClasses('foswikiInputField', 'jqUIDatepicker')
    }) . 

    Foswiki::Render::html("span", {
      "class" => "ui-clockpicker-sep"
    }, "-") .

    Foswiki::Render::html("div", {
      "class" => "jqClockPicker foswikiTimeField",
      "data-autoclose" => 'true',
    }, Foswiki::Render::html( "input", {
        "type" => 'text',
        "name" => $this->{name} . '_time',
        "size" => 1,
        "value" => $timeValue,
        "class" => $this->cssClasses('foswikiInputField')
      })
      . Foswiki::Render::html("button", {
        "class" => "input-group-addon ui-clockpicker-trigger",
        "tabindex" => -1,
      }, Foswiki::Render::html( "i", {
          "class" => "fa fa-clock-o",
        })
      )
    );

  return ('', $html);
}

1;
