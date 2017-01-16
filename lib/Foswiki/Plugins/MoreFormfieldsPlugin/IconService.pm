# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2013-2017 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Plugins::MoreFormfieldsPlugin::IconService;

use strict;
use warnings;

use JSON ();
use constant TRACE => 0;

sub new {
  my $class = shift;

  my $this = bless({
    @_
  }, $class);

  return $this;
}

sub handleRest {
  my ($this, $session, $subject, $verb, $response) = @_;

  my $request = Foswiki::Func::getRequestObject();

  my $search = $request->param("q");
  if (!defined $search || $search eq '') {
    $search = ".";
  } else {
    $search = quotemeta($search);
  }

  my $include = $request->param("include") || '';
  $include = join("|", split(/\s*,\s*/, $include));

  my $exclude = $request->param("exclude") || '';
  $exclude = join("|", split(/\s*,\s*/, $exclude));

  my $catPattern = $request->param("cat");
  if (defined $catPattern) {
    $catPattern = join("|", map {quotemeta($_)} split(/\s*,\s*/, $catPattern));
  } else {
    $catPattern = ".";
  }

  my $limit = $request->param("limit");
  $limit = 20 unless defined $limit;

  my $page = $request->param("page") || 1;
  my $skip = $limit*($page-1);
  $limit += $skip;

  my $doExactMatch = Foswiki::Func::isTrue($request->param("exact"), 0);

  $this->init;

  my @results = ();

  my $index = 0;

  foreach my $icon (@{$this->{icons}}) {
    next if $include && $icon->{id} !~ /$include/;
    next if $exclude && $icon->{id} =~ /$exclude/;

    my $found = 0;
    if ($doExactMatch) {
      $found = 1 if 
        $icon->{id} =~ /^($search)$/ || 
        ($icon->{filter} && grep(/^($search)$/, @{$icon->{filter}}));
    } else {
      $found = 1 if 
        $icon->{id} =~ /$search/i || 
        ($icon->{filter} && grep(/$search/i, @{$icon->{filter}}));
    }
    next unless $found;

    my @matchedCats = ();
    foreach my $cat (@{$icon->{categories}}) {
      my $catLabel = $cat;
      if ($catLabel =~ /$catPattern/i) {
        $catLabel =~ s/^FamFamFam//; # clean up
        $catLabel = Foswiki::Func::spaceOutWikiWord($catLabel);
        push @matchedCats, $catLabel;
      }
    }
    next unless @matchedCats;

    $index++;

    if ($skip < $index && $index <= $limit) {
      push @results, {
        id => $icon->{id},
        text => $icon->{text},
        url => $icon->{url},
        categories => \@matchedCats,
      };
    }
  }

  $response->header(
    -status => 200,
    -content_type => "application/json",
  );
  $response->print(JSON::to_json({
    total => $index,
    results => \@results
  }));

  return;  
}

sub init {
  my $this = shift;

  return if $this->{icons};

  # read fontawesome icons
  my $iconFile = $Foswiki::cfg{PubDir}.'/'.$Foswiki::cfg{SystemWebName}.'/MoreFormfieldsPlugin/fontawesome.json';
  my $text = Foswiki::Func::readFile($iconFile);
  my $json = JSON::decode_json($text);

  my @icons = ();
  my %cats = ();

  foreach my $entry (@{$json->{icons}}) {
    $entry->{text} = $entry->{id};
    $entry->{id} = 'fa-'.$entry->{id};
    push @{$entry->{categories}}, "fontawesome";
    push @icons, $entry;

    if ($entry->{aliases}) {
      foreach my $alias (@{$entry->{aliases}}) {
        my %clone = %$entry;
        $clone{text} = $alias;
        $clone{id} = 'fa-'.$alias;
        $clone{_isAlias} = 1;
        push @icons, \%clone;
      }
    }
  }

  # read icons from icon path
  my $iconSearchPath = $Foswiki::cfg{JQueryPlugin}{IconSearchPath}
    || 'FamFamFamSilkIcons, FamFamFamSilkCompanion1Icons, FamFamFamSilkCompanion2Icons, FamFamFamSilkGeoSilkIcons, FamFamFamFlagIcons, FamFamFamMiniIcons, FamFamFamMintIcons';

  my @iconSearchPath = split( /\s*,\s*/, $iconSearchPath );

  foreach my $item (@iconSearchPath) {

      my ( $web, $topic ) = Foswiki::Func::normalizeWebTopicName(
          $Foswiki::cfg{SystemWebName}, $item );

      my $iconDir =
          $Foswiki::cfg{PubDir} . '/'
        . $web . '/'
        . $topic . '/';

      opendir(my $dh, $iconDir) || next;
      foreach my $icon (grep { /\.(png|gif|jpe?g)$/i } readdir($dh)) {
        next if $icon =~ /^(SilkCompanion1Thumb|index_abc|geosilk|silk\-companion\-II|igp_.*)\.png$/; # filter some more
        my $id = $icon;
        $id =~ s/\.(png|gif|jpe?g)$//i;
        push @icons, {
          id => $id,
          text => $id,
          url => Foswiki::Func::getPubUrlPath() . '/' . $web . '/' . $topic . '/' . $icon,
          categories => [$topic],
        };
      }
      closedir $dh;
  }

  @icons = sort {lc($a->{text}) cmp lc($b->{text})} @icons;
  $this->{icons} = \@icons;
}

1;
