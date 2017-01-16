# See bottom of file for license and copyright information
package Foswiki::Form::Autofill;

use strict;
use warnings;

BEGIN {
  if ($Foswiki::cfg{UseLocale}) {
    require locale;
    import locale();
  }
}

use Foswiki::Form::FieldDefinition ();
use Foswiki::Plugins ();
use Foswiki::Func ();
our @ISA = ('Foswiki::Form::FieldDefinition');

sub new {
  my $class = shift;
  my $this = $class->SUPER::new(@_);

  $this->{_formfieldClass} = 'foswikiAutoFillField';

  return $this;
}

sub finish {
  my $this = shift;
  $this->SUPER::finish();
  undef $this->{_params};
}

sub isEditable {
  return 0;
}

sub renderForEdit {
  my ($this, $topicObject, $value) = @_;

  # Changing labels through the URL is a feature for Foswiki applications,
  # even though it's not accessible for standard edits. Some contribs
  # may want to override this to make labels editable.
  my $renderedValue = $topicObject->expandMacros($value);

  return (
    '',
    CGI::hidden(
      -name => $this->{name},
      -override => 1,
      -value => $value,
      )
      . CGI::div({-class => $this->{_formfieldClass},}, $renderedValue)
  );
}

sub param {
  my ($this, $key) = @_;

  unless (defined $this->{_params}) {
    my %params = Foswiki::Func::extractParameters($this->{value});
    $this->{_params} = \%params;
  }

  return (defined $key) ? $this->{_params}{$key} : $this->{_params};
}

sub afterSaveHandler {
  my ($this, $topicObject) = @_;

  #print STDERR "called Foswiki::Form::Autofill::afterSaveHandler()\n";

  my $header = $this->param("header") || '';
  my $footer = $this->param("footer") || '';
  my $fields = $this->param("source") || $this->param("fields");
  my $format = $this->param("format");
  my $sep = $this->param("separator") || '';

  my @fields = ();
  @fields = split(/\s*,\s*/, $fields) if defined $fields;

  my $result;

  if (defined($format)) {
    $result = $format;
    
    @fields = map {$_->{name}} $topicObject->find("FIELD")
      unless @fields;

    foreach my $name (@fields) {
      my $field = $topicObject->get('FIELD', $name);
      next unless defined $field;
      my $value = $field->{value};
      $value = '' unless defined $value;
      $result =~ s/\$$name/$value/g;
    }

  } else {

    my @result = ();
    foreach my $name (@fields) {
      my $field = $topicObject->get('FIELD', $name);
      next unless defined $field;
      my $value = $field->{value};
      $value = '' unless defined $value;
      push @result, $field->{value};
    }

    $result = join($sep, @result);
  }
  return unless defined $result;

  my $thisField = $topicObject->get('FIELD', $this->{name});
  $thisField = {
    name => $this->{name},
    title => $this->{name},
    value => "",
  } unless defined $thisField;

  # remove it from the request so that it doesn't override things here
  my $request = Foswiki::Func::getRequestObject();
  $request->delete($this->{name});

  my $value = Foswiki::Func::expandCommonVariables(Foswiki::Func::decodeFormatTokens($header . $result . $footer), $topicObject->topic, $topicObject->web, $topicObject);

  return if $thisField->{value} eq $value;

  $thisField->{value} = $value;
  $topicObject->putKeyed('FIELD', $thisField);

  return 1; # trigger mustSave
}

1;
__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2013-2017 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

Additional copyrights apply to some or all of the code in this
file as follows:

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
