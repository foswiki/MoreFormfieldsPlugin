package Foswiki::Plugins::MoreFormfieldsPlugin::Clockpicker;

use strict;
use warnings;

use Foswiki::Plugins::JQueryPlugin::Plugin ();
our @ISA = qw( Foswiki::Plugins::JQueryPlugin::Plugin );

sub new {
  my $class = shift;

  my $this = bless(
    $class->SUPER::new(
      name => 'Clockpicker',
      version => '0.07',
      author => 'Wang Shenwei',
      homepage => 'http://weareoutman.github.io/clockpicker',
      javascript => ['clockpicker.js'],
      css => ['clockpicker.css'],
      documentation => 'MoreFormfieldsPlugin',
      puburl => '%PUBURLPATH%/%SYSTEMWEB%/MoreFormfieldsPlugin/build',
    ),
    $class
  );

  return $this;
}

1;
