# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2010-2014 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Form::Topic;

use strict;
use warnings;
use Foswiki::Func ();
use Foswiki::Form::ListFieldDefinition ();
use Assert;
our @ISA = ('Foswiki::Form::ListFieldDefinition');

BEGIN {
    if ( $Foswiki::cfg{UseLocale} ) {
        require locale;
        import locale();
    }
}

sub new {
    my $class = shift;
    my $this  = $class->SUPER::new(@_);

    $this->{_formfieldClass} = 'foswikiTopicField';
    $this->{_web} = $this->param("web") || $this->{session}{webName};

    return $this;
}

sub isMultiValued { return shift->{type} =~ /\+multi/; }
sub isValueMapped { return shift->{type} =~ /\+values/; }

sub getDefaultValue { return ''; }

sub finish {
  my $this = shift;
  $this->SUPER::finish();
  undef $this->{_params};
}

sub renderForDisplay {
  my ($this, $format, $value, $attrs) = @_;


  my $displayValue = $this->getDisplayValue($value);
  $format =~ s/\$value\(display\)/$displayValue/g;
  $format =~ s/\$value/$value/g;

  return $this->SUPER::renderForDisplay($format, $value, $attrs);
}

sub populateMetaFromQueryData {
  my ( $this, $query, $meta, $old ) = @_;

  if ( $this->isMultiValued() ) {
      my @values = $query->param( $this->{name} );

      if ( scalar(@values) == 1 && defined $values[0] ) {
	  @values = split( /,|%2C/, $values[0] );
      }
      my %vset = ();
      foreach my $val (@values) {
	  $val ||= '';
	  $val =~ s/^\s*//o;
	  $val =~ s/\s*$//o;

	  # skip empty values
	  $vset{$val} = ( defined $val && $val =~ /\S/ );
      }

      # populate options first
      $this->{_options} = [sort keys %vset];
  }

  return $this->SUPER::populateMetaFromQueryData($query, $meta, $old);
}

sub getDisplayValue {
  my ($this, $value) = @_;

  return '' unless defined $value && $value ne '';

  $this->getOptions($value);

  if ($this->isMultiValued) {
    my @result = ();
    foreach my $val (split(/\s*,\s*/, $value)) {
      my $origVal = $val;
      if ($this->isValueMapped) {
        if (defined($this->{valueMap}{$val})) {
          $val = $this->{valueMap}{$val};
        } 
      } else {
        $val = $this->getTopicTitle($this->{_web}, $val);
      }
      push @result, "<a href='%SCRIPTURLPATH{view}%/$this->{_web}/$origVal'>$val</a>";
    }
    $value = join(", ", @result);
  } else {
    my $origVal = $value;
    if ($this->isValueMapped) {
      if (defined($this->{valueMap}{$value})) {
        $value = $this->{valueMap}{$value};
      }
    } else {
      $value = $this->getTopicTitle($this->{_web}, $value);
    }
    $value = "<a href='%SCRIPTURLPATH{view}%/$this->{_web}/$origVal'>$value</a>"
  }

  return $value;
}

sub param {
  my ($this, $key) = @_;

  unless (defined $this->{_params}) {
    my %params = Foswiki::Func::extractParameters($this->{value});
    $this->{_params} = \%params;
  }

  return (defined $key)?$this->{_params}{$key}:$this->{_params};
}

sub renderForEdit {
  my ($this, $param1, $param2, $param3) = @_;

  my $value;
  my $web;
  my $topic;
  my $topicObject;
  if (ref($param1)) {    # Foswiki > 1.1
    $topicObject = $param1;
    $value = $param2;
  } else {
    $web = $param1;
    $topic = $param2;
    $value = $param3;
  }

  my @htmlData = ();
  push @htmlData, 'type="hidden"';
  push @htmlData, 'class="'.$this->{_formfieldClass}.'"';
  push @htmlData, 'name="'.$this->{name}.'"';
  push @htmlData, 'value="'.$value.'"';

  my $baseWeb = $this->param("web") || $this->{session}{webName};
  push @htmlData, 'data-base-web="'.$baseWeb.'"';

  my $size = $this->{size};
  if (defined $size) {
    $size .= "em";
  } else {
    $size = "element";
  }
  push @htmlData, 'data-width="'.$size.'"';

  if ($this->isMultiValued) {
    my @topicTitles = ();
    foreach my $v (split(/\s*,\s*/, $value)) {
      push @topicTitles, '"'.$v.'":"'.encode($this->getTopicTitle($baseWeb, $v)).'"';
    }
    push @htmlData, "data-value-text='{".join(', ', @topicTitles)."}'";
  } else {
    my $topicTitle = encode($this->getTopicTitle($baseWeb, $value));
    push @htmlData, 'data-value-text="'.$topicTitle.'"';
  }

  while (my ($key, $val) = each %{$this->param()}) {
    next if $key =~ /^(web)$/;
    $key = lc(Foswiki::spaceOutWikiWord($key, "-"));
    push @htmlData, 'data-'.$key.'="'.$val.'"';
  }

  if ($this->isMultiValued) {
    push @htmlData, 'data-multiple="true"';
  }

  $this->addJavascript();
  $this->addStyles();

  my $field = "<input ".join(" ", @htmlData)." />"; 

  return ('', $field);
}

sub addStyles {
  #my $this = shift;
  Foswiki::Func::addToZone("head", 
    "MOREFORMFIELDSPLUGIN::CSS",
    "<link rel='stylesheet' href='%PUBURLPATH%/%SYSTEMWEB%/MoreFormfieldsPlugin/moreformfields.css' media='all' />");

}

sub addJavascript {
  #my $this = shift;

  Foswiki::Plugins::JQueryPlugin::createPlugin("select2");
  Foswiki::Func::addToZone("script", "FOSWIKI::TOPICFIELD", <<"HERE", "JQUERYPLUGIN::SELECT2");
<script type='text/javascript' src='%PUBURLPATH%/%SYSTEMWEB%/MoreFormfieldsPlugin/topicfield.js'></script>
HERE
}

sub getTopicTitle {
  my ($this, $web, $topic) = @_;

  my ($meta, undef) = Foswiki::Func::readTopic($web, $topic);

  # read the formfield value
  my $title = $meta->get('FIELD', 'TopicTitle');
  if ($title) {
    $title = $title->{value};
  }

  # read the topic preference
  unless ($title) {
    $title = $meta->get('PREFERENCE', 'TOPICTITLE');
    if ($title) {
      $title = $title->{value};
    }
  }

  # read the preference
  unless ($title) {
    Foswiki::Func::pushTopicContext($web, $topic);
    $title = Foswiki::Func::getPreferencesValue('TOPICTITLE');
    Foswiki::Func::popTopicContext();
  }

  # default to topic name
  $title ||= $topic;

  $title =~ s/\s*$//;
  $title =~ s/^\s*//;

  return $title;
}

sub encode {
  my $text = shift;

  $text =~ s/([^0-9a-zA-Z-_.:~!*\/])/'%'.sprintf('%02x',ord($1))/ge;

  return $text;
}

1;
