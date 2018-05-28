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

package Foswiki::Form::Date2;

use strict;
use warnings;

use Foswiki::Form::FieldDefinition ();
use Foswiki::Plugins::JQueryPlugin ();
use Foswiki::Time ();
use Time::ParseDate ();
our @ISA = ('Foswiki::Form::FieldDefinition');

sub new {
  my $class = shift;
  my $this = $class->SUPER::new(@_);
  my $size = $this->{size} || '';
  $size =~ s/[^\d]//g;
  $size = 20 if (!$size || $size < 1);    # length(31st September 2007)=19
  $this->{size} = $size;
  return $this;
}

sub getDefaultValue {
  my $this = shift;

  my $value = $this->{default};
  $value = '' unless defined $value;

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

sub DIS_beforeSaveHandler {
  my ($this, $meta) = @_;

  my $field = $meta->get('FIELD', $this->{name});
  return unless $field;

  my $epoch = $this->parseDate($field->{value});

  if (defined $epoch) {
    $field->{value} = $epoch;
    $meta->putKeyed('FIELD', $field);
  }
}

sub beforeEditHandler {
  my ($this, $meta) = @_;

  my $field = $meta->get('FIELD', $this->{name});
  return unless $field;

  my $epoch = $this->parseDate($field->{value});

  if (defined $epoch) {
    my $val = $this->formatDate($epoch);
    $field->{value} = $val;
    $meta->putKeyed('FIELD', $field);
  }
}

sub renderForDisplay {
  my ($this, $format, $value, $attrs) = @_;

  my $epoch = $this->parseDate($value);

  if (defined $epoch) {
    $value = $this->formatDate($epoch);
  }

  return $this->SUPER::renderForDisplay($format, $value, $attrs);
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

  my $epoch = $this->parseDate($value);
  $value = $this->formatDate($epoch) if defined $epoch;

  my $dateFormat = _convertFormatToJQueryUI($this->param("format") || $Foswiki::cfg{DefaultDateFormat} || '$year/$mo/$day');

  $value = CGI::textfield({
      name => $this->{name},
      id => 'id' . $this->{name} . int(rand() * 1000),
      size => $this->{size},
      value => $value,
      "data-change-month" => "true",
      "data-change-year" => "true",
      "data-date-format" => $dateFormat,
      class => $this->can('cssClasses')
      ? $this->cssClasses('foswikiInputField', 'jqUIDatepicker')
      : 'foswikiInputField jqUIDatepicker'
    }
  );

  return ('', $value);
}

# convert to jquery-ui dateformat
sub _convertFormatToJQueryUI {
  my $dateFormat = shift;

  $dateFormat =~ s/\$day/dd/g;
  $dateFormat =~ s/\$wday/D/g;
  $dateFormat =~ s/\$mont?h?/M/g;
  $dateFormat =~ s/\$mo/mm/g;
  $dateFormat =~ s/\$year/yy/g;
  $dateFormat =~ s/\$ye/y/g;
  $dateFormat =~ s/\$iso/yy-mm-dd/g;
  $dateFormat =~ s/\$epoch/\@/g;

  return $dateFormat;
}

sub formatDate {
  my ($this, $epoch) = @_;

  my $dateFormat = $this->param("format") || $Foswiki::cfg{DefaultDateFormat} || '$year/$mo/$day';
  my $timezone = $this->param("timezone") || $Foswiki::cfg{DisplayTimeValues} || 'servertime';
  return Foswiki::Time::formatTime($epoch, $dateFormat, $timezone);
}

sub parseDate {
  my ($this, $time) = @_;

  return unless defined $time && $time ne "";

  if (ref($time) eq 'DateTime') {
    return $time->epoch();
  }

  $time =~ s/^\s+|\s+$//g;

  # yyyymmdd ... 8 digits
  if ($time =~ /^(\d\d\d\d)(\d\d)(\d\d)$/) {
    $time = "$1-$2-$3";
  } 

  # epoch seconds ... 10 digits
  elsif ($time =~ /^\d\d\d\d\d\d\d\d\d\d$/) {
    return $time;
  }

  # dd.mm.yyyy
  elsif ($time =~ /^(\d\d)\.(\d\d)\.(\d\d\d\d)$/) {
    $time = "$3-$2-$1";
  } 
  
  # 20111224T1200000
  elsif ($time =~ /^(\d\d\d\d)(\d\d)(\d\d)T(\d\d)(\d\d)(\d\d)(Z.*?)$/) {
    $time = "$1-$2-$3T$4:$5:$6$7";
  }

  my $result = Time::ParseDate::parsedate($time);

  #print STDERR "parseDate($time)=".($result//'undef')."\n";
  
  unless (defined $result) {
    Foswiki::Func::writeWarning("Foswiki::Form::Date2 - cannot parse time '$time'");
  }

  return $result;
}

1;
