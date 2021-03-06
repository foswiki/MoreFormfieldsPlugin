# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2010-2019 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Form::Id;

use strict;
use warnings;

use Foswiki::Form::FieldDefinition ();
use Foswiki::Plugins ();
our @ISA = ('Foswiki::Form::FieldDefinition');

sub new {
  my $class = shift;
  my $this = $class->SUPER::new(@_);

  $this->{_formfieldClass} = 'foswikiIDField';

  return $this;
}

sub finish {
  my $this = shift;
  $this->SUPER::finish();
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

sub afterSaveHandler {
  my ($this, $topicObject) = @_;

  #print STDERR "called Foswiki::Form::Id::afterSaveHandler()\n";

  my $topic = $topicObject->topic;

  return unless $topic =~ /(\d+)$/;
  my $number = $1;
  my $size = $this->{size} || 1;
  $size =~ /(\d+)/;
  $size = $1;
  my $value = sprintf("%0".$size."d", $number);

  my $thisField = $topicObject->get('FIELD', $this->{name});
  $thisField = {
    name => $this->{name},
    title => $this->{name},
    value => "",
  } unless defined $thisField;

  # remove it from the request so that it doesn't override things here
  my $request = Foswiki::Func::getRequestObject();
  $request->delete($this->{name});

  return if $thisField->{value} eq $value;

  $thisField->{value} = $value;
  $topicObject->putKeyed('FIELD', $thisField);

  return 1; # trigger mustSave
}

1;
