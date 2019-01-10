# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2010-2019 Michael Daum http://michaeldaumconsulting.com
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

sub getLang {
  my ($this) = @_;

  return $this->param("lang")
    || $this->param("language")
    || Foswiki::Func::getPreferencesValue("LANGUAGE")
    || $Foswiki::Plugins::SESSION->i18n->language()
    || 'en'; 
}

sub getDisplayValue {
  my ($this, $value) = @_;

  #my ($pkg, undef, $line) = caller;
  #print STDERR "called getDisplayValue($value) by $pkg, line $line\n";

  my $epoch = $value;
  $epoch = $this->parseDate($value) unless $value =~ /^\-?\d+$/;

  return $value unless $epoch;
  my $result = $this->formatDate($epoch);

  #print STDERR "... result=$result\n";
  return $result;
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

  my $epoch;
  if ($value =~ /^\-?\d+$/) {
    $epoch = $value;
  } else {
    $epoch = $this->parseDate($value);
    $value = $epoch if defined $epoch;
  }

  my $dateFormat = _convertFormatToJQueryUI($this->param("format") || $Foswiki::cfg{DefaultDateFormat} || '$year/$mo/$day');

  $value = CGI::textfield({
      name => $this->{name},
      id => 'id' . $this->{name} . int(rand() * 1000),
      size => $this->{size},
      value => $value,
      "data-change-month" => "true",
      "data-change-year" => "true",
      "data-date-format" => $dateFormat,
      "data-lang" => $this->getLang(),
      class => $this->can('cssClasses')
      ? $this->cssClasses('foswikiInputField', 'jqUIDatepicker')
      : 'foswikiInputField jqUIDatepicker'
    }
  );

  return ('', $value);
}

sub DIS_saveMetaDataHandler {
  my ($this, $record, $formDef) = @_;

  my $fieldName = $this->{name};
  my $fieldValue = $record->{$fieldName};
  return unless defined $fieldValue;

  my $epoch = $this->parseDate($fieldValue);

  #print STDERR "saveMetaDataHandler() $fieldName=$fieldValue, epoch=".($epoch//'undef')."\n";

  if (defined $epoch) { 
    $record->{$fieldName."_origvalue"} = $fieldValue;
    $record->{$fieldName} = $epoch;
  } else {
    Foswiki::Func::writeWarning("ERROR: invalid date string $fieldValue");
  }
}

sub createMetaKeyValues {
  my ($this, $query, $meta, $keyvalues) = @_;

  my $epoch = $this->parseDate($keyvalues->{value});

  #print STDERR "createMetaKeyValues($keyvalues->{value}), epoch=".($epoch//'undef')."\n";

  if (defined $epoch) { 
    $keyvalues->{origvalue} = $keyvalues->{value};
    $keyvalues->{value} = $epoch;
  } else {
    #Foswiki::Func::writeWarning("ERROR: invalid date string $keyvalues->{value}");
  }

  return $keyvalues;
}

# convert to jquery-ui dateformat
# | *jQuery* | *Foswiki* | *Printf*   | *Description* |
# | d        |           | %e         | day of month (no leading zero) |
# | dd       | $day      | %d         | day of month (two digit) |
# | o        |           |            | day of the year (no leading zeros)
# | oo       |           | %j         | day of the year (three digit) |
# | D        | $wday     | %a         | day name short |
# | DD       |           | %A         | day name long |
# | m        |           | %f         | month of year (no leading zero) |
# | mm       | $mo       | %m         | month of year (two digit) |
# | M        | $month    | %b,%h      | month name short |
# | MM       |           | %B         | month name long |
# | y        | $ye       | %y         | year (two digit) |
# | yy       | $year     | %Y         | year (four digit) |
# | @        | $epoch    | %s,%o      | Unix timestamp (ms since 01/01/1970) |
# | yy-mm-dd | $iso      | %Y-%mm-%dd | ISO format |
sub _convertFormatToJQueryUI {
  my $dateFormat = shift;

  my $result = $dateFormat;

  # foswiki -> jQuery
  $result =~ s/\$day/dd/g;
  $result =~ s/\$wday/D/g;
  $result =~ s/\$mont?h?s?/M/g;
  $result =~ s/\$mo/mm/g;
  $result =~ s/\$year?s?/yy/g;
  $result =~ s/\$ye/y/g;
  $result =~ s/\$iso/yy-mm-dd/g;
  $result =~ s/\$epoch/\@/g;

  # printf -> jQuery
  $result =~ s/%[eE]/d/g;
  $result =~ s/%d/dd/g;
  $result =~ s/%j/oo/g;
  $result =~ s/%a/D/g;
  $result =~ s/%A/DD/g;
  $result =~ s/%f/m/g;
  $result =~ s/%[bh]/M/g;
  $result =~ s/%B/MM/g;
  $result =~ s/%y/y/g;
  $result =~ s/%Y/yy/g;
  $result =~ s/%[so]/@/g;

  # clean up unsupported printf tokens
  $result =~ s/%[a-zA-Z][a-zA-Z]?\b//g;

  return $result;
}

sub formatDate {
  my ($this, $epoch, $params) = @_;

  $params ||= $this->param();
  $params->{lang} = $this->getLang();

  my $dateFormat = $this->param("format") || $Foswiki::cfg{DefaultDateFormat} || '$year/$mo/$day';
  my $timezone = $this->param("timezone") || $Foswiki::cfg{DisplayTimeValues} || 'servertime';

  return Foswiki::Time::formatTime($epoch, $dateFormat, $timezone, $params);
}

sub parseDate {
  my ($this, $string, $params) = @_;

  $params ||= $this->param();
  $params->{lang} = $this->getLang();

  return Foswiki::Time::parseTime($string, 1, $params);
}

1;
