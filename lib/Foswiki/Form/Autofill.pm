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

package Foswiki::Form::Autofill;

use strict;
use warnings;

use Foswiki::Form::BaseField ();
use Foswiki::Plugins ();
use Foswiki::Func ();
use Foswiki::Sandbox ();
use Foswiki::Form ();
use Foswiki::Render ();
our @ISA = ('Foswiki::Form::BaseField');

sub new {
  my $class = shift;
  my $this = $class->SUPER::new(@_);

  $this->{_formfieldClass} = 'foswikiAutoFillField';

  return $this;
}

sub isEditable { return 0; }
sub isTextMergeable { return 0; }

sub renderForEdit {
  my ($this, $topicObject, $value) = @_;

  return (
    '',
    Foswiki::Render::html("input", {
      "type" => "hidden",
      "name" => $this->{name},
      "value" => $value,
    }) .
    Foswiki::Render::html("div", {
      "class" => $this->{_formfieldClass},
    }, $value)
  );
}

sub getDisplayValue {
  my ($this, $value, $web, $topic) = @_;

  my $format = $this->param("display");
  if ($format) {
    $format =~ s/\$value\b/$value/g;
    $format = Foswiki::Func::decodeFormatTokens($format);
    $format = Foswiki::Func::expandCommonVariables($format) if $format =~ /%/;

    return $format;
  }

  my $type = $this->param("type");
  if ($type) {
    my $fieldDef = $this->createField($type);
    return $fieldDef->getDisplayValue($value, $web, $topic) if $fieldDef;
  }

  return $value unless defined $format;
}

sub createField {
  my ($this, $type) = @_;

  my $class = "Foswiki::Form::".ucfirst($type);

  eval 'require ' . $class;

  if ($@) {
    print STDERR "error in typecast: $@\n";
    return;
  }

  return $class->new( 
    session => $this->{session}, 
    type => $type,
    name => $this->{name},
    attributes => $this->{attributes},
    description => $this->{description},
    type => $type,
    size => $this->{size},
    validModifiers => $this->{validModifiers},
  );
}

sub saveMetaDataHandler {
  my ($this, $record, $formDef) = @_;

  my $fieldName = $this->{name};
  #print STDERR "... saveMetaDataHandler($fieldName)\n";
  
  my $fieldValue = $record->{$fieldName} || '';

  my $fields = $this->param("source") || $this->param("fields");
  my $format = $this->param("format");
  my $sep = $this->param("separator") || '';
  my $onlyNew = Foswiki::Func::isTrue($this->param("onlynew"), 0);

  return if $onlyNew && $fieldValue ne "";

  my @fields = ();
  @fields = split(/\s*,\s*/, $fields) if defined $fields;

  my $result;

  if (defined($format)) {
    $result = $format;

    @fields = map {$_->{name}} @{$formDef->getFields()};

    foreach my $name (@fields) {
      my $value = $record->{$name};
      unless (defined $value) {
        my $fieldDef = $formDef->getField($name);
        $value = $fieldDef->getDefaultValue() if $fieldDef->can("getDefaultValue");
        $value = $fieldDef->{default} unless defined $value;
      }
      $result =~ s/\$$name\b/\0$value\0/g;
    }
    $result =~ s/\0//g;

  } else {

    my @result = ();
    foreach my $name (@fields) {
      my $value = $record->{$name};
      unless (defined $value) {
        my $fieldDef = $formDef->getField($name);
        $value = $fieldDef->getDefaultValue() if $fieldDef->can("getDefaultValue");
        $value = $fieldDef->{default} unless defined $value;
      }
      push @result, $value if defined $value && $value ne "";
    }

    $result = join($sep, @result);
  }

  return unless defined $result;

  my $value = $this->formatValue($result);
  return if $value eq $fieldValue;

  $record->{$fieldName} = $value;
}

sub afterSaveHandler {
  my ($this, $topicObject) = @_;

  #print STDERR "called Foswiki::Form::Autofill::afterSaveHandler(".$topicObject->web.".".$topicObject->topic.")\n";
  #print STDERR "webName=$this->{session}{webName}, topicName=$this->{session}{topicName}\n";

  my $fields = $this->param("source") || $this->param("fields");
  my $format = $this->param("format");
  my $sep = $this->param("separator") || '';
  my $onlyNew = Foswiki::Func::isTrue($this->param("onlynew"), 0);

  my $thisField = $topicObject->get('FIELD', $this->{name});
  $thisField = {
    name => $this->{name},
    title => $this->{name},
    value => "",
  } unless defined $thisField;

  #print STDERR "current value of $thisField->{name}: $thisField->{value}\n";
  return if $onlyNew && $thisField->{value} ne "";

  my @fields = ();
  @fields = split(/\s*,\s*/, $fields) if defined $fields;

  my $result;

  if (defined($format)) {
    $result = $format;
    
    @fields = $this->getFieldNames($topicObject) unless @fields;

    foreach my $name (@fields) {
      my $value = $this->getFieldValue($topicObject, $name) // '';
      $result =~ s/\$$name\b/\0$value\0/g;
    }
    $result =~ s/\0//g;

  } else {

    my @result = ();
    foreach my $name (@fields) {
      my $value = $this->getFieldValue($topicObject, $name);
      push @result, $value if defined $value && $value ne "";
    }

    $result = join($sep, @result);
  }
  return unless defined $result;

  # remove it from the request so that it doesn't override things here
  my $request = Foswiki::Func::getRequestObject();
  $request->delete($this->{name});

  my $value = $this->formatValue($result, $topicObject->web, $topicObject->topic, $topicObject);
  return if $thisField->{value} eq $value;

  $thisField->{value} = $value;
  $topicObject->putKeyed('FIELD', $thisField);

  return 1; # trigger mustSave
}

sub formatValue {
  my ($this, $value, $web, $topic, $meta) = @_;

  my $header = $this->param("header") || '';
  my $footer = $this->param("footer") || '';
  my $result = Foswiki::Func::decodeFormatTokens($header . $value . $footer);
  $result = Foswiki::Func::expandCommonVariables($result, $topic, $web, $meta) if $result =~ /%/;

  #print STDERR "formatValue($value, $web, $topic) for $this->{name} = $result\n";
  return $result;
}

sub getFieldValue {
  my ($this, $obj, $name) = @_;

  my $field = $obj->get('FIELD', $name);
  return "" unless defined $field;
  my $value = $field->{value};

  if (!defined($value) || $value eq '') {
    my $request = Foswiki::Func::getRequestObject();
    $value = $request->param($name);
  }

  $value = $this->getFieldDefault($obj, $name) unless defined $value;

  return $value;
}

sub getFieldDefault {
  my ($this, $obj, $name) = @_;

  my $form = $this->getFormDef($obj);
  return unless $form;

  my $fieldDef = $form->getField($name);
  return unless $fieldDef;

  return $fieldDef->getDefaultValue() if $fieldDef->can("getDefaultValue");
  return $fieldDef->{default};
}

sub getFieldNames {
  my ($this, $obj) = @_;

  my $formDef = $this->getFormDef($obj);
  return unless $formDef;
  return map {$_->{name}} @{$formDef->getFields()};
}

sub getFormDef {
  my ($this, $obj) = @_;

  my ($web, $topic) = Foswiki::Func::normalizeWebTopicName($obj->web, $obj->getFormName());
  return new Foswiki::Form($this->{session}, $web, $topic);
}

1;
