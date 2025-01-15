# Plugin for Foswiki -V The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2013-2025 Michael Daum http://michaeldaumconsulting.com
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

our $VERSION = '11.52';
our $RELEASE = '%$RELEASE%';
our $SHORTDESCRIPTION = 'Additional formfield types for %SYSTEMWEB%.DataForms';
our $LICENSECODE = '%$LICENSECODE%';
our $NO_PREFS_IN_TOPIC = 1;

our $iconService;
our $userService;
our $webService;

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
    description => 'Gets a list of icons.'
  );

  Foswiki::Func::registerRESTHandler("users", sub {
    unless (defined $userService) {
      require Foswiki::Plugins::MoreFormfieldsPlugin::UserService;
      $userService = Foswiki::Plugins::MoreFormfieldsPlugin::UserService->new();
    }
    $userService->handleUsers(@_);
  },
    authenticate => 1,
    validate     => 0,
    http_allow   => 'GET,POST',
    description => 'Expand the list of users.'
  );

  Foswiki::Func::registerRESTHandler("groups", sub {
    unless (defined $userService) {
      require Foswiki::Plugins::MoreFormfieldsPlugin::UserService;
      $userService = Foswiki::Plugins::MoreFormfieldsPlugin::UserService->new();
    }
    $userService->handleGroups(@_);
  },
    authenticate => 1,
    validate     => 0,
    http_allow   => 'GET,POST',
    description => 'Expand the list of groups.'
  );

  Foswiki::Func::registerRESTHandler("userorgroup", sub {
    unless (defined $userService) {
      require Foswiki::Plugins::MoreFormfieldsPlugin::UserService;
      $userService = Foswiki::Plugins::MoreFormfieldsPlugin::UserService->new();
    }
    $userService->handleUserOrGroup(@_);
  },
    authenticate => 1,
    validate     => 0,
    http_allow   => 'GET,POST',
    description => 'Expand the list of users and groups.'
  );

  Foswiki::Func::registerRESTHandler("webs", sub {
    unless (defined $webService) {
      require Foswiki::Plugins::MoreFormfieldsPlugin::WebService;
      $webService = Foswiki::Plugins::MoreFormfieldsPlugin::WebService->new();
    }
    $webService->handleWebs(@_);
  },
    authenticate => 1,
    validate     => 0,
    http_allow   => 'GET,POST',
    description => 'Expand the list of webs.'
  );

  if (Foswiki::Func::getContext()->{DBCachePluginEnabled}) {
    require Foswiki::Plugins::DBCachePlugin;
  }

  if (Foswiki::Func::getContext()->{MetaDataPluginEnabled}) {
    require Foswiki::Plugins::MetaDataPlugin;
    Foswiki::Plugins::MetaDataPlugin::registerSaveHandler(\&saveMetaDataHandler);
  }

  return 1;
}

sub finishPlugin {

  if (defined $iconService) {
    $iconService->finish();
    undef $iconService;
  }

  if (defined $userService) {
    $userService->finish();
    undef $userService;
  }

  if (defined $webService) {
    $webService->finish();
    undef $webService;
  }
}

sub beforeEditHandler {
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
    if ($field->can("beforeEditHandler")) {
      $field->beforeEditHandler($meta, $form);
    }
  }
}

sub afterEditHandler {
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
    if ($field->can("afterEditHandler")) {
      $field->afterEditHandler($meta, $form);
    }
  }
}

sub saveMetaDataHandler {
  my ($web, $topic, $metaDataName, $record) = @_;

  #print STDERR "called saveMetaDataHandler for $web.$topic metadata=$metaDataName\n";

  my $metaDataDef = $Foswiki::Meta::VALIDATE{$metaDataName};
  return unless defined $metaDataDef;
  return unless defined $metaDataDef->{form};

  my ($formWeb, $formTopic) = Foswiki::Func::normalizeWebTopicName($web, $metaDataDef->{form});
  return unless Foswiki::Func::topicExists($formWeb, $formTopic);

  my $formDef;
  try {
    my $session = $Foswiki::Plugins::SESSION;
    $formDef = new Foswiki::Form($session, $formWeb, $formTopic);
  } catch Foswiki::OopsException with {
    my $e = shift;
    print STDERR "ERROR: can't read form definition $formWeb.$formTopic in MoreFormfieldsPlugin::saveMetaDataHandler\n";
  };
  return unless defined $formDef;

  foreach my $field (@{$formDef->getFields}) {
    if ($field->can("saveMetaDataHandler")) {
      $field->saveMetaDataHandler($record, $formDef);
    }
  }
}

sub beforeSaveHandler {
  my ($text, $topic, $web, $meta) = @_;
  
  my $form = $meta->get("FORM");
  return unless $form;

  my $formName = $form->{name};

  my $session = $Foswiki::Plugins::SESSION;

  $form = undef;
  try {
    $form = Foswiki::Form->new($session, $web, $formName);
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
    $form = Foswiki::Form->new($session, $web, $formName);
  } catch Foswiki::OopsException with {
    my $error = shift;
    #print STDERR "Error reading form definition for $formName ... bailing out\n";
  };
  return unless $form;

  # forward to formfields
  my $mustSave = 0;
  foreach my $field (@{$form->getFields}) {
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

# call afterSaveHandler when attachments have been uploaded
sub afterUploadHandler {
  my ($attrHashRef, $meta) = @_;

  my $web = $meta->web;
  my $topic = $meta->topic;
  #print STDERR "called afterUploadHandler($web, $topic)\n";

  afterSaveHandler($meta->text, $topic, $web, "", $meta);
}

# call afterSaveHandler when attachments changed
sub afterRenameHandler {
  my ($oldWeb, $oldTopic, $oldAttachment, $newWeb, $newTopic, $newAttachment) = @_;

  return unless $oldAttachment && $newAttachment;
  return if $oldWeb eq $newWeb && $oldTopic eq $newTopic;

  #print STDERR "called afterRenameHandler($oldWeb, $oldTopic, $oldAttachment, $newWeb, $newTopic, $newAttachment)\n";

  my ($meta) = Foswiki::Func::readTopic($oldWeb, $oldTopic);
  afterSaveHandler($meta->text, $oldTopic, $oldWeb, "", $meta);

  ($meta) = Foswiki::Func::readTopic($newWeb, $newTopic);
  afterSaveHandler($meta->text, $newTopic, $newWeb, "", $meta);
}

1;

