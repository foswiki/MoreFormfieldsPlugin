# See bottom of file for license and copyright information
# See bottom of file for license and copyright details
# This packages subclasses Foswiki::Form::FieldDefinition to implement
# the =date= type

package Foswiki::Form::Date2;

use strict;
use warnings;

use Foswiki::Form::FieldDefinition      ();
use Foswiki::Plugins::JQueryPlugin ();
use Foswiki::Time ();
our @ISA = ('Foswiki::Form::FieldDefinition');

sub new {
    my $class = shift;
    my $this  = $class->SUPER::new(@_);
    my $size  = $this->{size} || '';
    $size =~ s/[^\d]//g;
    $size = 20 if ( !$size || $size < 1 );    # length(31st September 2007)=19
    $this->{size} = $size;
    return $this;
}

sub renderForDisplay {
    my ( $this, $format, $value, $attrs ) = @_;

    my $epoch = Foswiki::Time::parseTime($value);
    $epoch = 0 unless defined $epoch;
    $value = Foswiki::Time::formatTime($epoch, $Foswiki::cfg{DefaultDateFormat} || '$year/$mo/$day', 'gmtime');

    return $this->SUPER::renderForDisplay($format, $value, $attrs);
}

sub renderForEdit {
    my ( $this, $topicObject, $value ) = @_;
    my ( $web, $topic );

    unless ( ref($topicObject) ) {

        # Pre 1.1
        ( $this, $web, $topic, $value ) = @_;
        undef $topicObject;
    }

    Foswiki::Plugins::JQueryPlugin::createPlugin("ui::datepicker");
    
    $value = CGI::textfield(
        {
            name  => $this->{name},
            id    => 'id' . $this->{name} . int(rand()*1000),
            size  => $this->{size},
            value => $value,
            "data-change-month" => "true",
            "data-change-year" => "true",
            class => $this->can('cssClasses')
            ? $this->cssClasses( 'foswikiInputField',
                'jqUIDatepicker' )
            : 'foswikiInputField jqUIDatepicker'
        }
    );

    return ( '', $value );
}

1;
__DATA__

Copyright (C) 2015-2017 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
