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

package Foswiki::Form::Autoinc;

use strict;
use warnings;

use Foswiki::Form::BaseField ();
use Foswiki::Func ();
use Foswiki::Render ();
our @ISA = ('Foswiki::Form::BaseField');

#use Data::Dump qw(dump);

sub new {
  my $class = shift;
  my $this = $class->SUPER::new(@_);

  $this->{_formfieldClass} = 'foswikiAutoIncField';

  return $this;
}

sub isEditable { return 0; }
sub isTextMergeable { return 0; }

sub renderForEdit {
  my ($this, $meta, $value) = @_;

  return (
    '',
    Foswiki::Render::html("input", {
      "type" => "hidden",
      "name" => $this->{name},
      "value" => $value,
    }) .
    Foswiki::Render::html("div", {
      "class" => $this->{_formfieldClass}
    }, $value)
  );
}

sub afterSaveHandler {
  my ($this, $meta) = @_;

  my $thisField = $meta->get('FIELD', $this->{name});
  my $onlyNew = Foswiki::Func::isTrue($this->param("onlynew"), 1);

  return if $onlyNew && defined($thisField) && defined($thisField->{value}) && $thisField->{value} ne "";

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

  my $baseQuery = $useBaseQuery ? "form.name=~'$regexWeb$formTopic'" : "";

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

  # query for results
  my %params = (
    web => $web, 
    casesensitive => 0, 
    files_without_match => 0
  );

  my $include = $this->param("include");
  $params{topic} = $include if defined $include;
  
  my $exclude = $this->param("exclude");
  $params{excludetopic} = $exclude if defined $exclude;

  #print STDERR "query=$query\n";
  #print STDERR "params: ".dump(\%params)."\n";

  my $matches = Foswiki::Func::query($query, undef, \%params);

  # get the maximum value already in use
  my $maxValue;
  while ($matches->hasNext) {
    my ($itemWeb, $itemTopic) = Foswiki::Func::normalizeWebTopicName('', $matches->next);
    next if $itemWeb eq $meta->web && $itemTopic eq $meta->topic;
    my ($itemMeta) = Foswiki::Func::readTopic($itemWeb, $itemTopic);
    my $field = $itemMeta->get("FIELD", $this->{name});
    next unless $field;
    my $itemVal = int($field->{value} || 0);
    #print STDERR "item=$itemWeb.$itemTopic, field=$this->{name}, value=$itemVal\n";
    $maxValue = $itemVal if !(defined $maxValue) || $itemVal > $maxValue;
  }
  #print STDERR "maxValue=".($maxValue//'undef')."\n";

  # set it back to the real user
  $this->{session}{user} = $tmpUser;

  my $startValue = int($this->param("start") || 0);
  my $value = defined($maxValue) && $maxValue >= $startValue ? $maxValue + 1 : $startValue;

  #print STDERR "value=$value\n";

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
