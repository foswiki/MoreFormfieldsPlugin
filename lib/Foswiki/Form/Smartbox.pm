# See bottom of file for license and copyright information
package Foswiki::Form::Smartbox;

use strict;
use warnings;
use Assert;

use Foswiki::Func();
use Foswiki::Form::Checkbox ();
our @ISA = ('Foswiki::Form::Checkbox');

BEGIN {
    if ( $Foswiki::cfg{UseLocale} ) {
        require locale;
        import locale();
    }
}

sub isValueMapped { return 1; }

sub getOptions {
  my $this = shift;

  my $vals = $this->SUPER::getOptions();
  return unless $vals;

  $this->{valueMap} = ();

  foreach my $val (@$vals) {
    if ($val =~ s/\*$//) {
      $this->{anyValue} = $val;
      $this->{valueMap}{$val} = join(", ", @$vals); # map all values to 'anyValue'
    } else {
      $this->{valueMap}{$val} = $val;
    }
  }

  $this->{anyValue} = @$vals[0] unless defined $this->{anyValue};

  return $vals;
}

sub cssClasses {
    my $this = shift;
    if ( $this->isMandatory() ) {
        push( @_, 'foswikiMandatory' );
    }

    push @_, 'foswikiSmartboxItem';

    return join( ' ', @_ );
}

sub renderForDisplay {
  my ($this, $format, $value, $attrs) = @_;


  my $displayValue = $this->getDisplayValue($value);
  $format =~ s/\$value\(display\)/$displayValue/g;
  $format =~ s/\$value/$value/g;

  return $this->SUPER::renderForDisplay($format, $value, $attrs);
}

sub getDisplayValue {
    my ( $this, $value ) = @_;

    return $value unless $this->isValueMapped();

    $this->getOptions();
    my @vals = ();
    foreach my $val ( split( /\s*,\s*/, $value ) ) {
        if ( $val eq $this->{anyValue}) {
          @vals = $val;
          last;
        }
        if ( defined( $this->{valueMap}{$val} ) ) {
            push @vals, $this->{valueMap}{$val};
        }
        else {
            push @vals, $val;
        }
    }
    return join( ", ", @vals );
}

sub renderForEdit {
  my ( $this, $topicObject, $value ) = @_;

  Foswiki::Func::addToZone("script", "FOSWIKI::SMARTBOX", <<'HERE', "JQUERYPLUGIN");
<script type='text/javascript' src='%PUBURLPATH%/%SYSTEMWEB%/MoreFormfieldsPlugin/smartbox.js'></script>
HERE

  my %isSelected = map { $_ => 1 } split( /\s*,\s*/, $value );
  my $vals = $this->getOptions();

  if ($isSelected{$this->{anyValue}} || scalar(keys %isSelected) == scalar(@$vals) -1) {
    $value = join(", ", @$vals);
  }

  my ($extra, $html) = $this->SUPER::renderForEdit($topicObject, $value);

  $html = '<div class="foswikiSmartbox" data-any-value="'.$this->{anyValue}.'">' . $html . '</div>';

  return ($extra, $html);
}

1;
__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2008-2014 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

Additional copyrights apply to some or all of the code in this
file as follows:

Copyright (C) 2005-2007 TWiki Contributors. All Rights Reserved.
TWiki Contributors are listed in the AUTHORS file in the root
of this distribution. NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
