# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2010-2024 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Form::Userorgroup;

use strict;
use warnings;

BEGIN {
  if ($Foswiki::cfg{UseLocale}) {
    require locale;
    import locale();
  }
}

use Foswiki::Form::Topic ();
our @ISA = ('Foswiki::Form::Topic');

sub new {
  my $class = shift;
  my $this = $class->SUPER::new(@_);

  $this->{_formfieldClass} = 'foswikiUserOrGroupField';
  $this->{_web} = $this->param("web") || $Foswiki::cfg{UsersWebName};
  $this->{_url} = Foswiki::Func::expandTemplate("select2::userorgroup::url");

  return $this;
}

sub getDisplayValue {
  my ($this, $value) = @_;

  return $this->SUPER::getDisplayValue($value, $this->{_web});
}

1;
