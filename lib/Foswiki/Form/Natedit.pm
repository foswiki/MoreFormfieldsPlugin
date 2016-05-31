# See bottom of file for license and copyright information
package Foswiki::Form::Natedit;

use strict;
use warnings;

use Foswiki::Form::Textarea ();
our @ISA = ('Foswiki::Form::Textarea');

BEGIN {
    if ( $Foswiki::cfg{UseLocale} ) {
        require locale;
        import locale();
    }
}

sub param {
  my ($this, $key) = @_;

  unless (defined $this->{_params}) {
    my %params = Foswiki::Func::extractParameters($this->{value});
    $this->{_params} = \%params;
  }

  return (defined $key)?$this->{_params}{$key}:$this->{_params};
}

sub finish {
  my $this = shift;

  $this->SUPER::finish();

  undef $this->{_params};
}

sub getDefaultValue {
    my $this = shift;

    my $value =
      ( exists( $this->{default} ) ? $this->{default} : '' );
    $value = '' unless defined $value;    # allow 0 values

    return $value;
}

sub renderForEdit {
  my ($this, $topicObject, $value) = @_;

  Foswiki::Plugins::JQueryPlugin::createPlugin("natedit");

  my @html5Data = ();

  foreach my $param (keys %{$this->param()}) {
    my $key = $param;
    my $val = $this->param($key);
    $key =~ s/([[:upper:]])/-\l$1/g;
    $key = 'data-'.$key;
    push @html5Data, $key.'="'.$val.'"';
  }

  $value =~ s/</&lt;/g;
  $value =~ s/>/&gt;/g;

  my $textarea = '<textarea class="foswikiTextarea natedit" rows="'.$this->{rows}.'" cols="'.$this->{cols}.'" '.join(" ", @html5Data)." name='$this->{name}'>\n$value</textarea>";

  return ('', $textarea);
}

1;
__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2008-2016 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

Additional copyrights apply to some or all of the code in this
file as follows:

Copyright (C) 2001-2007 TWiki Contributors. All Rights Reserved.
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
