# Extension for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2022-2025 Michael Daum http://michaeldaumconsulting.com
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

package MoreFormfieldsPluginSuite;

use strict;
use warnings;

use Unit::TestSuite;
our @ISA = 'Unit::TestSuite';

sub name { 'MoreFormfieldsPluginSuite' }

sub include_tests { 
  return (
   "MoreFormfieldsAttachmentTests",
   "MoreFormfieldsAutofillTests",
   "MoreFormfieldsAutoincTests",
   "MoreFormfieldsBaseFieldTests",
   "MoreFormfieldsBytesTests",
   "MoreFormfieldsDate2Tests",
   "MoreFormfieldsDatetimeTests",
   "MoreFormfieldsGroupTests",
   "MoreFormfieldsIconTests",
   "MoreFormfieldsIdTests",
   "MoreFormfieldsIpaddressTests",
   "MoreFormfieldsIpv6addressTests",
   "MoreFormfieldsMacaddressTests",
   "MoreFormfieldsMultitextTests",
   "MoreFormfieldsNateditTests",
   "MoreFormfieldsNetmaskTests",
   "MoreFormfieldsNetworkAddressFieldTests",
   "MoreFormfieldsPhonenumberTests",
   "MoreFormfieldsRandomTests",
   "MoreFormfieldsSelect2Tests",
   "MoreFormfieldsSliderTests",
   "MoreFormfieldsSmartboxTests",
   "MoreFormfieldsTimeTests",
   "MoreFormfieldsToggleTests",
   "MoreFormfieldsTopicTests",
   "MoreFormfieldsUserorgroupTests",
   "MoreFormfieldsUserTests",
   "MoreFormfieldsWebTests",
  );
}

1;


