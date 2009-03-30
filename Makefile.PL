require 5.006;
use inc::Module::Install;
name('CPAN-Metabase-Client');
all_from('lib/CPAN/Metabase/Client/Simple.pm');

requires('HTTP::Request::Common' => 0);
requires('LWP::UserAgent'        => 0);

WriteAll;
