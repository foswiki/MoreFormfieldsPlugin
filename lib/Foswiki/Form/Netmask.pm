# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2010-2016 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Form::Netmask;

use strict;
use warnings;

use Foswiki::Form::NetworkAddressField ();
our @ISA = ('Foswiki::Form::NetworkAddressField');

sub new {
  my $class = shift;
  my $this = $class->SUPER::new(@_);
  $this->{_class} = 'foswikiNetmask';
  return $this;
}

sub beforeSaveHandler {
  my ($this, $topicObject) = @_;

  my $field = $topicObject->get('FIELD', $this->{name});

  $field = {
    name => $this->{name},
    title => $this->{name},
  } unless defined $field;

  my @segments = ();
  foreach my $segment (split(/\./, $field->{value})) {
    push @segments, sprintf("%03d", $segment);
  }
  $field->{value} = join(".", @segments);

  $topicObject->putKeyed('FIELD', $field);
}


1;
