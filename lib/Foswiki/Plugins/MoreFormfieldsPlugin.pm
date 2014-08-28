# Plugin for Foswiki -V The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2013-2014 Michael Daum http://michaeldaumconsulting.com
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

our $VERSION = '0.11';
our $RELEASE = '0.11';
our $SHORTDESCRIPTION = 'Additionall formfield types for %SYSTEMWEB%.DataForms';
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
}

1;

