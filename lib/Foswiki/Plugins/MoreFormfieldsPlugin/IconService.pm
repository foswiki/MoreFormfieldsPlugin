# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2013-2019 Michael Daum http://michaeldaumconsulting.com
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

sub finish {
  my $this = shift;

  undef $this->{_delegate};
}

sub delegate {
  my $this = shift;

  unless ($this->{_delegate}) {
    $this->{_delegate} = Foswiki::Plugins::JQueryPlugin::getIconService();
  }
  return $this->{_delegate};
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


  my $params = {
    exactMatch => Foswiki::Func::isTrue($request->param("exact"), 0),
    skip => $skip,
    limit => $limit,
    include => $include,
    exclude => $exclude,
    category => $catPattern,
  };
  my ($results, $total) = $this->findIcon($search, $params);

  $response->header(
    -status => 200,
    -content_type => "application/json",
  );
  $response->print(JSON::to_json({
    total => $total,
    results => $results
  }, {
    pretty => 1
  }));

  return;  
}

sub findIcon {
  my ($this, $search, $params) = @_;

  my $index = 0;
  my $skip = $params->{skip} || 0;
  my $limit = $params->{limit} || 0;
  $limit += $skip;

  my @results = ();


  my $it = $this->delegate->getIconIterator();
  while ($it->hasNext) {
    my $icon = $it->next;

    next if $params->{include} && $icon->{id} !~ /$params->{include}/;
    next if $params->{exclude} && $icon->{id} =~ /$params->{exclude}/;

    my $found = 0;
    if ($params->{exactMatch}) {
      $found = 1 if 
        $icon->{id} =~ /^($search)$/ || 
        $icon->{text} =~ /^($search)$/ || 
        ($icon->{filter} && grep(/^($search)$/, @{$icon->{filter}}));
    } else {
      $found = 1 if 
        $icon->{id} =~ /$search/i || 
        $icon->{text} =~ /$search/i || 
        ($icon->{filter} && grep(/$search/i, @{$icon->{filter}}));
    }
    next unless $found;

    my @matchedCats = ();
    if (defined $params->{category}) {
      foreach my $cat (@{$icon->{categories}}) {
        my $catLabel = $cat;
        if ($catLabel =~ /$params->{category}/i) {
          $catLabel =~ s/^FamFamFam//; # clean up
          $catLabel = Foswiki::Func::spaceOutWikiWord($catLabel);
          push @matchedCats, $catLabel;
        }
      }
      next unless @matchedCats;
    }

    $index++;
    if ($index > $skip && (!$limit || $index <= $limit)) {
      push @results, {
	id => $icon->{id},
	text => $icon->{text},
	url => $icon->{url},
	categories => \@matchedCats,
      };
    }
  }

  return wantarray?(\@results, $index):$results[0];
}

1;
