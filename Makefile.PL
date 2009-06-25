require 5.006;
use inc::Module::Install;
name('Metabase-Client-Simple');
all_from('lib/Metabase/Client/Simple.pm');

requires('HTTP::Request::Common' => 0);
requires('JSON'                  => 0);
requires('LWP::UserAgent'        => 0);
requires('Metabase::Fact'        => 0);

auto_manifest;
WriteAll;
