package Foswiki::Contrib::MoreFormfieldsContrib::Clockpicker;

use strict;
use warnings;

use Foswiki::Plugins::JQueryPlugin::Plugin ();
our @ISA = qw( Foswiki::Plugins::JQueryPlugin::Plugin );

sub new {
  my $class = shift;

  my $this = bless(
    $class->SUPER::new(
      name => 'Clockpicker',
      version => '0.06',
      author => 'Wang Shenwei',
      homepage => 'http://weareoutman.github.io/clockpicker',
      javascript => ['clockpicker.js', 'clockpicker.init.js'],
      css => ['clockpicker.css'],
      documentation => 'MoreFormfieldsContrib',
      puburl => '%PUBURLPATH%/%SYSTEMWEB%/MoreFormfieldsContrib',
    ),
    $class
  );

  return $this;
}

1;