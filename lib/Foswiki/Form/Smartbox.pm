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

package Foswiki::Form::Smartbox;

use strict;
use warnings;
use Assert;

use Foswiki::Func();
use Foswiki::Form::Checkbox ();
our @ISA = ('Foswiki::Form::Checkbox', 'Foswiki::Form::BaseField');

sub isValueMapped { return 1; }
sub isTextMergeable { return 0; }

sub getOptions {
  my $this = shift;

  my $vals = $this->SUPER::getOptions();
  return unless $vals;

  $this->{valueMap} = ();

  foreach my $val (@$vals) {
    if ($val =~ s/\*$//) {
      $this->{anyValue} = $val;
      $this->{valueMap}{$val} = join(", ", @$vals);    # map all values to 'anyValue'
    } else {
      $this->{valueMap}{$val} = $val;
    }
  }

  $this->{anyValue} = @$vals[0] unless defined $this->{anyValue};

  return $vals;
}

sub cssClasses {
  my $this = shift;
  if ($this->isMandatory()) {
    push(@_, 'foswikiMandatory');
  }

  push @_, 'foswikiSmartboxItem';

  return join(' ', @_);
}

sub getDisplayValue {
  my ($this, $value) = @_;

  return $value unless $this->isValueMapped();    # never

  $this->getOptions();
  my @vals = ();
  foreach my $val (split(/\s*,\s*/, $value)) {
    next if $val eq $this->{anyValue};
    if (defined($this->{valueMap}{$val})) {
      push @vals, $this->{valueMap}{$val};
    } else {
      push @vals, $val;
    }
  }
  return join(", ", @vals);
}

sub renderForEdit {
  my ($this, $topicObject, $value) = @_;

  Foswiki::Func::addToZone("script", "FOSWIKI::SMARTBOX", <<'HERE', "JQUERYPLUGIN");
<script src='%PUBURLPATH%/%SYSTEMWEB%/MoreFormfieldsPlugin/build/smartbox.js'></script>
HERE

  my %isSelected = map { $_ => 1 } split(/\s*,\s*/, $value);
  my $vals = $this->getOptions();

  if ($isSelected{$this->{anyValue}} || scalar(keys %isSelected) == scalar(@$vals) - 1) {
    $value = join(", ", @$vals);
  }

  my ($extra, $html) = $this->SUPER::renderForEdit($topicObject, $value);

  $html = '<div class="foswikiSmartbox" data-any-value="' . $this->{anyValue} . '">' . $html . '</div>';

  return ($extra, $html);
}

1;
