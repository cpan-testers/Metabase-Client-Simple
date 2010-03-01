require 5.006;
use inc::Module::Install;
name('Metabase-Client-Simple');
all_from('lib/Metabase/Client/Simple.pm');

requires      ('HTTP::Request::Common'        => 5.824   );
requires      ('HTTP::Status'                 => 5.817   );
requires      ('JSON'                         => 2.17    );
requires      ('LWP::UserAgent'               => 5.834   );
requires      ('URI'                          => 1.51    );
build_requires('Test::More'                   => 0.88    );

auto_manifest;
WriteAll;
