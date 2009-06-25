require 5.006;
use inc::Module::Install;
name('Metabase-Client');
all_from('lib/Metabase/Client/Simple.pm');

requires('Metabase::Fact'  => 0); # min unknown; user profiles, etc
requires('HTTP::Request::Common' => 0);
requires('LWP::UserAgent'        => 0);

auto_manifest;
WriteAll;
