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

package Foswiki::Form::Autoinc;

use strict;
use warnings;

use Foswiki::Form::FieldDefinition ();
use Foswiki::Func ();
our @ISA = ('Foswiki::Form::FieldDefinition');

sub new {
  my $class = shift;
  my $this = $class->SUPER::new(@_);

  $this->{_formfieldClass} = 'foswikiAutoIncField';

  return $this;
}

sub finish {
  my $this = shift;
  $this->SUPER::finish();
  undef $this->{_params};
}

sub isEditable {
  return 0;
}

sub renderForEdit {
  my ($this, $meta, $value) = @_;

  return (
    '',
    CGI::hidden(
      -name => $this->{name},
      -override => 1,
      -value => $value,
      )
      . CGI::div({-class => $this->{_formfieldClass},}, $value)
  );
}

sub param {
  my ($this, $key) = @_;

  unless (defined $this->{_params}) {
    my %params = Foswiki::Func::extractParameters($this->{value});
    $this->{_params} = \%params;
  }

  return (defined $key) ? $this->{_params}{$key} : $this->{_params};
}

sub getDefaultValue {
  my $this = shift;

  my $value = $this->{default};
  $value = '' unless defined $value;

  return $value;
}

sub afterSaveHandler {
  my ($this, $meta) = @_;

  my $thisField = $meta->get('FIELD', $this->{name});
  return if defined($thisField) && defined($thisField->{value}) && $thisField->{value} ne "";

  $thisField = {
    name => $this->{name},
    title => $this->{name},
    value => "",
  } unless defined $thisField;

  my $topic = $meta->topic;
  my $web = $this->param("web") || $meta->web;

  my $formName = $meta->getFormName();
  my ($formWeb, $formTopic) = Foswiki::Func::normalizeWebTopicName($web, $formName);
  my $query = $this->param("query") // "";

  my $useBaseQuery = Foswiki::Func::isTrue($this->param("basequery"), 1);
  my $regexWeb = "(?:$formWeb.)?";
  $regexWeb =~ s/[^\\]\./\\./g;
  $regexWeb =~ s/\//\[\/\\.\]/g;

  my $baseQuery = $useBaseQuery ? "form.name=~'$regexWeb$formTopic' and name!='$topic'" : "name!='$topic'";

  if ($query eq '') {
    $query = $baseQuery;
  } else {
    my @fields = map { $_->{name} } $meta->find("FIELD");
    foreach my $name (@fields) {
      my $field = $meta->get('FIELD', $name);
      my $value = defined($field) ? $field->{value} // "" : "";
      $query =~ s/\$$name\b/$value/g;
    }

    $query = $baseQuery . " and " . $query;
  }

  #print STDERR "query=$query\n";

  # become admin user to bypass any acl filter part of the query algorithm -> we don't want to miss any topic in the set
  my $adminUser = Foswiki::Func::getCanonicalUserID($Foswiki::cfg{AdminUserLogin});
  my $tmpUser = $this->{session}{user};
  $this->{session}{user} = $adminUser;

  # get the maximum value already in use
  my $maxValue;
  my $matches = Foswiki::Func::query($query, undef, {web => $web, casesensitive => 0, files_without_match => 0});
  while ($matches->hasNext) {
    my ($itemWeb, $itemTopic) = Foswiki::Func::normalizeWebTopicName('', $matches->next);
    my ($itemMeta) = Foswiki::Func::readTopic($itemWeb, $itemTopic);
    my $field = $itemMeta->get("FIELD", $this->{name});
    next unless $field;
    my $itemVal = int($field->{value} || 0);
    #print STDERR "item=$itemWeb.$itemTopic, field=$this->{name}, value=$itemVal\n";
    $maxValue = $itemVal if !(defined $maxValue) || $itemVal > $maxValue;
  }

  # set it back to the real user
  $this->{session}{user} = $tmpUser;

  my $startValue = int($this->param("start") || 0);
  my $value = defined($maxValue) && $maxValue >= $startValue ? $maxValue + 1 : $startValue;

  my $size = $this->{size} || 1;
  $size =~ /(\d+)/;
  $size = $1;
  $value = sprintf("%0" . $size . "d", $value);

  # remove it from the request so that it doesn't override things here
  my $request = Foswiki::Func::getRequestObject();
  $request->delete($this->{name});

  return if $thisField->{value} eq $value;

  $thisField->{value} = $value;
  $meta->putKeyed('FIELD', $thisField);

  return 1;    # trigger mustSave
}

1;
