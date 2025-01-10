# ---+ Extensions
# ---++ MoreFormfieldsPlugin
# This is the configuration used by the <b>MoreFormfieldsPlugin</b>.

# **BOOLEAN LABEL="Translate WebTitles"**
# Disable if I18N is slowing down getting the web list.
$Foswiki::cfg{MoreFormfieldsPlugin}{TranslateWebTitles} = 1;

# ---++ JQueryPlugin
# ---+++ Extra plugins
# **STRING EXPERT**
$Foswiki::cfg{JQueryPlugin}{Plugins}{Clockpicker}{Module} = 'Foswiki::Plugins::MoreFormfieldsPlugin::Clockpicker';
# **BOOLEAN**
$Foswiki::cfg{JQueryPlugin}{Plugins}{Clockpicker}{Enabled} = 1;

1;
