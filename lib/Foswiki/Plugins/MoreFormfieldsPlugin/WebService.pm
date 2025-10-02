# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2018-2025 Michael Daum http://michaeldaumconsulting.com
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
use Foswiki::Plugins::FlexWebListPlugin ();
use JSON ();

use constant TRACE => 0;

sub new {
  my $class = shift;

  my $this = bless({
    translateWebTitles => $Foswiki::cfg{MoreFormfieldsPlugin}{TranslateWebTitles} // 1,
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

  my $webs = $request->param("webs") // 'all';
  $params{webs} = [];
  $params{webs} = [split(/\s*,\s*/, $webs)] if defined $webs;

  $params{limit} = $request->param("limit") || 10;
  $params{page} = $request->param("page") || 1;
  $params{skip} = $params{limit} * ($params{page}-1);

  $params{include} = $request->param("include");
  $params{exclude} = $request->param("exclude");

  if (!defined($params{exclude}) && $webs =~ /\buser\b/) {
    $params{exclude} = "^(Applications|Archive|$Foswiki::cfg{TrashWebName}|$Foswiki::cfg{SystemWebName})";
  }

  return \%params;
}

sub handleWebs {
  my ($this, $session, $subject, $verb, $response) = @_;

  my $params = $this->getParams();
  my ($results, $total) = $this->getWebs($params);

  @$results = sort {$a->{text} cmp $b->{text}} @$results;

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

  my $limit = $params->{limit} // 10;
  my $skip = $params->{skip} // 0;

  my @webs = ();
  foreach my $web (Foswiki::Func::getListOfWebs(join(", ", @{$params->{webs}}))) {

    $web =~ s/\//./g;

    my $webTitle = $this->getWebTitle($web);
    next if defined($params->{search}) && $web !~ /$params->{search}/i && $webTitle !~ /$params->{search}/i;
    next if defined($params->{include}) && $web !~ /$params->{include}/i && $webTitle !~ /$params->{include}/i;
    next if defined($params->{exclude}) && ($web =~ /$params->{exclude}/i || $webTitle =~ /$params->{exclude}/i);
    
    push @webs, $web;
  }

  my $results = [];
  my $index = 0;
  foreach my $web (@webs) {

    $index++;
    next if $index <= $skip;
    last if $index > ($skip + $limit);

    my $webTitle = $this->getWebTitle($web);

    push @$results, {
      id => $web,
      title => $webTitle,
      text => "<div class='foswikiNoWrap'>$webTitle <span class='foswikiGrayText foswikiSmall'>($web)</span></div>",
    };

  }

  return ($results, scalar(@webs));
}

sub translate {
  my ($this, $web, $topic, $string) = @_;

  if (Foswiki::Func::getContext()->{MultiLingualPluginEnabled}) {
    require Foswiki::Plugins::MultiLingualPlugin;
    return Foswiki::Plugins::MultiLingualPlugin::translate($string, $web, $topic);
  } 
    
  return $this->{session}->i18n->maketeyt($string);
}

sub getWebTitle {
  my ($this, $web) = @_;

  my $text = Foswiki::Plugins::FlexWebListPlugin->getCore()->getWebTitle($web);
  return $this->{translateWebTitles} ? $this->translate($web, $Foswiki::cfg{HomeTopicName}, $text) : $text;
}

1;

