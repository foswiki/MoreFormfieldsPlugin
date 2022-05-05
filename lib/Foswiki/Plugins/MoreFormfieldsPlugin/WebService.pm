# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2018-2022 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Plugins::MoreFormfieldsPlugin::WebService;

use strict;
use warnings;

use Foswiki::Func ();
use JSON ();
use constant TRACE => 0;

sub new {
  my $class = shift;

  my $this = bless({
    @_
  }, $class);

  return $this;
}

sub finish {
  my $this = shift;
}

sub getParams {
  my ($this) = @_;

  my $request = Foswiki::Func::getRequestObject();

  my %params = ();

  my $search = $request->param("q");
  if (!defined $search || $search eq '') {
    $search = ".";
  } else {
    $search = quotemeta($search);
  }
  $params{search} = $search;

  my $webs = $request->param("webs") // 'user';
  $params{webs} = [];
  $params{webs} = [split(/\s*,\s*/, $webs)] if defined $webs;

  $params{limit} = $request->param("limit") || 10;
  $params{page} = $request->param("page") || 1;
  $params{skip} = $params{limit} * ($params{page}-1);

  $params{include} = $request->param("include");
  $params{exclude} = $request->param("exclude");

  if (!defined($params{exclude}) && $webs =~ /\buser\b/) {
    $params{exclude} = "^(Applications|$Foswiki::cfg{TrashWebName}|$Foswiki::cfg{SystemWebName})";
  }

  return \%params;
}

sub handleWebs {
  my ($this, $session, $subject, $verb, $response) = @_;

  my $params = $this->getParams();
  my $results = $this->getWebs($params);

  my $total = scalar(@$results);
  @$results = sort {$a->{text} cmp $b->{text}} @$results;
  @$results = splice(@$results, $params->{skip}, $params->{limit});

  $results = JSON::to_json({
    "results" => $results,
    "total" => $total,
  }, {
    pretty => 1
  });

  $response->header(
    -status => 200,
    -type => 'application/json',
  );

  $response->print($results);

  return "";
}

sub getWebs {
  my ($this, $params) = @_;

  my $results = [];
  foreach my $web (Foswiki::Func::getListOfWebs(join(", ", @{$params->{webs}}))) {
    my $topicTitle = Foswiki::Func::getTopicTitle($web, $Foswiki::cfg{HomeTopicName});

    $web =~ s/\//./g;

    next if defined($params->{search}) && $web !~ /$params->{search}/i && $topicTitle !~ /$params->{search}/i;
    next if defined($params->{include}) && $web !~ /$params->{include}/i && $topicTitle !~ /$params->{include}/i;
    next if defined($params->{exclude}) && ($web =~ /$params->{exclude}/i || $topicTitle =~ /$params->{exclude}/i);

    push @$results, {
      id => $web,
      text => $topicTitle,
    };
  }

  return $results;
}

1;

