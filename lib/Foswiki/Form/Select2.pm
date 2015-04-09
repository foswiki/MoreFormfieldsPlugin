# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2010-2015 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Form::Select2;

use strict;
use warnings;

use Foswiki::Form::Select ();
use Foswiki::Plugins::JQueryPlugin ();
our @ISA = ('Foswiki::Form::Select');

use Assert;

BEGIN {
  if ($Foswiki::cfg{UseLocale}) {
    require locale;
    import locale();
  }
}

sub param {
  my ($this, $key) = @_;

  unless (defined $this->{_params}) {
    my %params = Foswiki::Func::extractParameters($this->{attributes});
    $this->{_params} = \%params;
  }

  return (defined $key)?$this->{_params}{$key}:$this->{_params};
}

sub renderForEdit {
  my ($this, $topicObject, $value) = @_;

  my $choices = '';

  $value = '' unless defined $value;
  my %isSelected = map { $_ => 1 } split(/\s*,\s*/, $value);
  foreach my $item (@{$this->getOptions()}) {
    my $option = $item;    # Item9647: make a copy not to modify the original value in the array
    my %params = (class => 'foswikiOption',);
    $params{selected} = 'selected' if $isSelected{$option};
    if ($this->{_descriptions}{$option}) {
      $params{title} = $this->{_descriptions}{$option};
    }
    if (defined($this->{valueMap}{$option})) {
      $params{value} = $option;
      $option = $this->{valueMap}{$option};
    }
    $option =~ s/<nop/&lt\;nop/go;
    $choices .= CGI::option(\%params, $option);
  }

  my $size = $this->{size};
  if (defined $size) {
    $size .= "em";
  } else {
    $size = "element";
  }

  my $params = {
    class => $this->cssClasses('jqSelect2'),
    name => $this->{name},
    size => 1,
    'data-width' => $size,
    'data-allow-clear' => 'true',
    'data-placeholder' => 'None',
  };

  if ($this->isMultiValued()) {
    $params->{'multiple'} = 'multiple';
    $value = CGI::Select($params, $choices);

    # Item2410: We need a dummy control to detect the case where
    #           all checkboxes have been deliberately unchecked
    # Item3061:
    # Don't use CGI, it will insert the value from the query
    # once again and we need an empt field here.
    $value .= '<input type="hidden" name="' . $this->{name} . '" value="" />';
  } else {
    $value = CGI::Select($params, $choices);
  }

  $this->addJavascript();

  return ('', $value);
}

sub addJavascript {
  #my $this = shift;

  Foswiki::Plugins::JQueryPlugin::createPlugin("select2");
}

1;
