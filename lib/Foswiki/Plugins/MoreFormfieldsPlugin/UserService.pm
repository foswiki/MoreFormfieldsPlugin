# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2018-2019 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Plugins::MoreFormfieldsPlugin::UserService;

use strict;
use warnings;

use Foswiki::Func ();
use JSON ();
use constant TRACE => 0;

sub new {
  my $class = shift;

  Foswiki::Func::readTemplate("moreformfields");
  Foswiki::Func::readTemplate("user");

  my $this = bless({
    thumbnailFormat => Foswiki::Func::expandTemplate("select2::user::thumbnail::url"),
    userPhotoSize => Foswiki::Func::expandTemplate("user::photo::size"),
    @_
  }, $class);

  return $this;
}

sub finish {
  my $this = shift;

  undef $this->{thumbnailFormat};
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

  my $group = $request->param("group");
  $params{groups} = [];
  $params{groups} = [split(/\s*,\s*/, $group)] if defined $group;

  $params{limit} = $request->param("limit") || 10;
  $params{page} = $request->param("page") || 1;
  $params{skip} = $params{limit} * ($params{page}-1);

  $params{include} = $request->param("include");
  $params{exclude} = $request->param("exclude");

  return \%params;
}

sub getUsers {
  my ($this, $params) = @_;

  my $results = [];

  my $it = Foswiki::Func::eachUser();
  my $thisUser = Foswiki::Func::getWikiName();

  while ($it->hasNext()) {
    my $user = $it->next();
    my $topicTitle = Foswiki::Func::getTopicTitle($Foswiki::cfg{UsersWebName}, $user);

    next if defined($params->{search}) && $user !~ /$params->{search}/i && $topicTitle !~ /$params->{search}/i;
    next if defined($params->{include}) && $user !~ /$params->{include}/ && $topicTitle !~ /$params->{include}/;
    next if defined($params->{exclude}) && ($user =~ /$params->{exclude}/ || $topicTitle =~ /$params->{exclude}/);

    next if Foswiki::Func::topicExists($Foswiki::cfg{UsersWebName}, $user) &&
            !Foswiki::Func::checkAccessPermission("VIEW", $thisUser, undef, $user, $Foswiki::cfg{UsersWebName});

    next if scalar(@{$params->{groups}}) && !_isGroupMember($user, @{$params->{groups}});

    push @$results, {
      id => $user,
      text => $topicTitle
    };
  }

  return $results;
}

sub getGroups {
  my ($this, $params) = @_;

  my $results = [];

  my $it = Foswiki::Func::eachGroup();
  my $thisUser = Foswiki::Func::getWikiName();

  while ($it->hasNext()) {
    my $group = $it->next();
    my $topicTitle = Foswiki::Func::getTopicTitle($Foswiki::cfg{UsersWebName}, $group);

    next if defined($params->{search}) && $group !~ /$params->{search}/i && $topicTitle !~ /$params->{search}/i;
    next if defined($params->{include}) && $group !~ /$params->{include}/ && $topicTitle !~ /$params->{include}/;
    next if defined($params->{exclude}) && ($group =~ /$params->{exclude}/ || $topicTitle =~ /$params->{exclude}/);

    next if Foswiki::Func::topicExists($Foswiki::cfg{UsersWebName}, $group) &&
            !Foswiki::Func::checkAccessPermission("VIEW", $thisUser, undef, $group, $Foswiki::cfg{UsersWebName});

    push @$results, {
      id => $group,
      isGroup => 1,
      text => $topicTitle
    };
  }

  return $results;
}

sub handleUsers {
  my ($this, $session, $subject, $verb, $response) = @_;

  my $params = $this->getParams();
  my $results = $this->getUsers($params);

  my $total = scalar(@$results);
  @$results = sort {$a->{text} cmp $b->{text}} @$results;

  @$results = splice(@$results, $params->{skip}, $params->{limit});

  foreach my $item (@$results) {
    my $thumbnail = $this->{thumbnailFormat};
    $thumbnail =~ s/%topic%/$item->{id}/g;
    $thumbnail =~ s/%web%/$Foswiki::cfg{UsersWebName}/g;
    $thumbnail =~ s/%size%/$this->{userPhotoSize}/g;
    $item->{thumbnail} = Foswiki::Func::expandCommonVariables($thumbnail);
  }

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

sub handleGroups {
  my ($this, $session, $subject, $verb, $response) = @_;

  my $params = $this->getParams();

  my $results = $this->getGroups($params);

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

sub handleUserOrGroup {
  my ($this, $session, $subject, $verb, $response) = @_;

  my $params = $this->getParams();

  my $users = $this->getUsers($params);
  my $groups = $this->getGroups($params);

  my $results = [];
  push @$results, @$users if defined $users;
  push @$results, @$groups if defined $groups;

  my $total = scalar(@$results);
  @$results = sort {$a->{text} cmp $b->{text}} @$results;

  @$results = splice(@$results, $params->{skip}, $params->{limit});

  foreach my $item (@$results) {
    my $thumbnail = $this->{thumbnailFormat};
    $thumbnail =~ s/%topic%/$item->{id}/g;
    $thumbnail =~ s/%web%/$Foswiki::cfg{UsersWebName}/g;
    $thumbnail =~ s/%size%/$this->{userPhotoSize}/g;
    $item->{thumbnail} = Foswiki::Func::expandCommonVariables($thumbnail);
  }

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

sub _isGroupMember {
  my ($user, @groups) = @_;

  foreach my $group (@groups) {
    return 1 if Foswiki::Func::isGroupMember($group, $user, {expand => 1});
  }

  return 0;
}

1;

