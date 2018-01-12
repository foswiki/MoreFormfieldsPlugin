# Plugin for Foswiki -V The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2013-2018 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Plugins::MoreFormfieldsPlugin;

use strict;
use warnings;

use Foswiki::Func ();
use Foswiki::Form ();
use Foswiki::OopsException ();
use Foswiki::Plugins ();

use Error qw(:try);

our $VERSION = '4.10';
our $RELEASE = '12 Jan 2018';
our $SHORTDESCRIPTION = 'Additional formfield types for %SYSTEMWEB%.DataForms';
our $NO_PREFS_IN_TOPIC = 1;

our $iconService;

sub initPlugin {

  Foswiki::Func::registerRESTHandler('icon', sub {
    unless (defined $iconService) {
      require Foswiki::Plugins::MoreFormfieldsPlugin::IconService;
      $iconService = Foswiki::Plugins::MoreFormfieldsPlugin::IconService->new();
    }
    $iconService->handleRest(@_);
  }, 
    authenticate => 0,
    validate => 0,
    http_allow => 'GET,POST',
  );

  if (Foswiki::Func::getContext()->{DBCachePluginEnabled}) {
    require Foswiki::Plugins::DBCachePlugin;
  }

  return 1;
}

sub beforeSaveHandler {
  my ($text, $topic, $web, $meta) = @_;
  
  my $form = $meta->get("FORM");
  return unless $form;

  my $formName = $form->{name};

  my $session = $Foswiki::Plugins::SESSION;

  $form = undef;
  try {
    $form = new Foswiki::Form($session, $web, $formName);
  } catch Foswiki::OopsException with {
    my $error = shift;
    #print STDERR "Error reading form definition for $formName ... baling out\n";
  };
  return unless $form;

  # forward to formfields
  foreach my $field (@{$form->getFields}) {
    if ($field->can("beforeSaveHandler")) {
      $field->beforeSaveHandler($meta, $form);
    }
  }

  if (Foswiki::Func::getContext()->{DBCachePluginEnabled}) {
    Foswiki::Plugins::DBCachePlugin::disableSaveHandler(); # we will call it manually after we finished our afterSaveHandler
  }
}

sub afterSaveHandler {
  my ( $text, $topic, $web, $error, $meta ) = @_;

  return if $error;
  
  my $form = $meta->get("FORM");
  return unless $form;

  my $formName = $form->{name};

  my $session = $Foswiki::Plugins::SESSION;

  $form = undef;
  try {
    $form = new Foswiki::Form($session, $web, $formName);
  } catch Foswiki::OopsException with {
    my $error = shift;
    #print STDERR "Error reading form definition for $formName ... baling out\n";
  };
  return unless $form;

  # forward to formfields

  # move all autofill formfields to the end
  my @fields = @{$form->getFields};
  @fields = sort {
    if ($a->isa("Foswiki::Form::Autofill")) {
      if ($b->isa("Foswiki::Form::Autofill")) {
        return 0;
      } else {
        return 1;
      }
    } else {
      if ($b->isa("Foswiki::Form::Autofill")) {
        return -1;
      } else {
        return 0;
      }
    }
  } @fields;

  #print STDERR "fields: ".join(", ", map {$_->{name}} @fields)."\n";

  my $mustSave = 0;
  foreach my $field (@fields) {
    if ($field->can("afterSaveHandler")) {
      #print STDERR "calling afterSaveHandler for field $field - $field->{name}\n";
      $mustSave = 1 if $field->afterSaveHandler($meta, $form);
    }
  }

  if ($mustSave) {
    #print STDERR "saving $web.$topic in MoreFormfieldsPlugin::afterSaveHandler()\n";
    $meta->saveAs(dontlog => 1, minor => 1);
  }

  if (Foswiki::Func::getContext()->{DBCachePluginEnabled}) {
    Foswiki::Plugins::DBCachePlugin::enableSaveHandler(); 
    Foswiki::Plugins::DBCachePlugin::afterSaveHandler($text, $topic, $web, $error, $meta);
  }
}

1;

