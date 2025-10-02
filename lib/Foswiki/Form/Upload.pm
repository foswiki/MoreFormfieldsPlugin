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
package Foswiki::Form::Upload;

use strict;
use warnings;

use Foswiki::Func();
use Foswiki::Form::BaseField ();
our @ISA = ('Foswiki::Form::BaseField');

sub new {
  my $class = shift;
  my $this = $class->SUPER::new(@_);
  my $size = $this->{size} || '';
  $size =~ s/\D//g;
  $size = 10 if (!$size || $size < 1);
  $this->{size} = $size;

  $this->{_formfieldClass} = 'foswikiUploadField';
  return $this;
}

sub isMultiValued { return (shift->{type} =~ m/\+multi/); }

sub isTextMergeable { return 0; }

sub renderForEdit {
  my ($this, $topicObject, $value) = @_;

  my $accept = $this->param("accept");
  $accept = "accept=\"$accept\"" if $accept;

  my $result;
  if ($this->isMultiValued) {
    $result = "<input type='file' $accept name='_".$this->{name}."[]' multiple / >" if $this->isMultiValued;
  } else {
    $result = "<input type='file' $accept name='_$this->{name}' / >";
  }

  return ('', $result);
}

1;

