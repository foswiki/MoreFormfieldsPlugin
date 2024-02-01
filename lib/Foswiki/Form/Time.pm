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

package Foswiki::Form::Time;

use strict;
use warnings;

use Foswiki::Render();
use Foswiki::Plugins::JQueryPlugin ();
use Foswiki::Form::BaseField ();
our @ISA = ('Foswiki::Form::BaseField');

sub new {
  my $class = shift;
  my $this = $class->SUPER::new(@_);

  my $size = $this->{size} || '';
  $size =~ s/[^\d]//g;
  $size = 20 if (!$size || $size < 1);    # length(31st September 2007)=19
  $this->{size} = $size;

  return $this;
}

sub isTextMergeable { return 0; }

sub beforeSaveHandler {
  my ($this, $meta, $form) = @_;

  my $request = Foswiki::Func::getRequestObject();
  my $timeStr = $request->param($this->{name});
  return if !defined($timeStr) || $timeStr =~ /^\d*$/;

  my ($hour, $min) = split(/:/, $timeStr);
  $timeStr = sprintf("%02d:%02d", $hour, $min);

  my $field = $meta->get('FIELD', $this->{name});
  $field //= {
    name => $this->{name},
    title => $this->{title},
  };
  $field->{value} = $timeStr;
  $meta->putKeyed('FIELD', $field);
}

sub renderForEdit {
  my ($this, $topicObject, $value) = @_;

  Foswiki::Plugins::JQueryPlugin::createPlugin("ClockPicker");
  Foswiki::Plugins::JQueryPlugin::createPlugin("imask");

  return (
    '',
    Foswiki::Render::html("div", {
        "class" => "jqClockPicker foswikiTimeField",
        "data-autoclose" => 'true',
      }, Foswiki::Render::html( "input", {
          "type" => 'text',
          "name" => $this->{name},
          "size" => $this->{size},
          "value" => $value,
          "class" => $this->cssClasses('foswikiInputField imask'),
          "data-type" => "time",
          "placeholder" => "hh:mm"
        })

        . Foswiki::Render::html("button", {
          "class" => "input-group-addon ui-clockpicker-trigger",
          "tabindex" => -1,
        }, Foswiki::Render::html( "i", {
            "class" => "fa fa-clock-o",
          })
        )
    )
  );
}

1;

