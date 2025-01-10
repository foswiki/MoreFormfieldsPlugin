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

package Foswiki::Form::User;

use strict;
use warnings;

use Foswiki::Form::Topic ();
our @ISA = ('Foswiki::Form::Topic');

sub new {
  my $class = shift;
  my $this = $class->SUPER::new(@_);

  # SMELL: template only present in NatSkin
  $this->readTemplate("user");

  #$this->{_formfieldClass} = 'foswikiUserField';
  $this->{_web} = $this->param("web") || $Foswiki::cfg{UsersWebName};

  $this->{_url} = Foswiki::Func::expandTemplate("select2::user::url");

  # SMELL: template only present in NatSkin
  $this->{_thumbnailFormat} = Foswiki::Func::expandTemplate("user::photo::thumbnail::url") || $this->{_thumbnailFormat};

  return $this;
}

sub getDisplayValue {
  my ($this, $value) = @_;

  return $this->SUPER::getDisplayValue($value, $this->{_web});
}

sub getFormfieldClass {
  my ($this, $val) = @_;

  return $this->{_formfieldClass} if Foswiki::Func::getCanonicalUserID($val);
  return "$this->{_formfieldClass}  foswikiAlert";
}

1;
