#!/usr/bin/perl

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

use utf8;

use XML::Twig;

use File::Which;

my @cmd = do {
    if (which('pv')) {
        ('pv plwiktionary-latest-pages-articles.xml.bz2 | bzip2 -c -d');
    } else {
        qw(bzip2 -c -d plwiktionary-latest-pages-articles.xml.bz2);
    }
};

open my $fhin, '-|', @cmd or die "Cannot run command: @cmd: $!";
open my $fhout, '>:utf8', 'pokrewne.csv';

# at most one div will be loaded in memory
my $twig = XML::Twig->new(
    twig_handlers => {
        text => sub {
            my ($t, $elem) = @_;

            my @lines = split /\n/, $elem->text;

            # == [[system]] [[plik]]ów ({{język polski}}) ==
            while ($_ = shift @lines) {
                last if s/^== (.*) \Q({{język polski}})\E ==$/$1/;
            }

            goto FREE unless $_;

            # [[stary|stara]]
            s/ \[\[ [^|\]]* \| ( [^\]]* ) \]\] /$1/xg;

            # [[miłość]]
            s/ \[\[ ( [^\]]* ) \]\] /$1/xg;

            # ''coś''
            s/ '' /\"/xg;

            my $title = $_;

            while ($_ = shift @lines) {
                last if /^\{\{(wyrazy )?pokrewne\}\}$/;
            }

            goto FREE unless $_;

            while ($_ = shift @lines) {
                last if /^\Q{{\E/;

                # Przykładowe wpisy

                # : (1.1) ''forma męska'' [[kumoś]]; zobacz też: [[kum]]
                # : {{zob|[[gryźć]]}}
                # :: {{zdrobn}} [[dynksik]] {{m}}
                # : {{rzecz}} [[właz]] {{m}}, [[łażenie]] {{n}}, [[łazik]] {{m}}, [[łazior]] {{mrz}}/{{mos}}
                # : zobacz też: [[jabłko]]
                # : (1.1-2) {{rzecz}} [[nadawca]]
                # : (1) {{czas}} [[nadawać się]]; {{rzecz}} [[nadawanie]]/[[nadanie]]
                # : {{przym}} [[ambrozjański]]; {{przest}} {{gwara}} [[Ambrożowy]]<ref>{{PoradniaPWN|id=13752|hasło=przymiotniki dzierżawcze od imion}}</ref><ref>{{PoradniaPWN|id=13793|hasło=przymiotniki dzierżawcze}}</ref>
                # : {{zdrobn}} {{przest}} [[kryska]], [[kreska]], [[kreseczka]]; {{zgrub}} {{przest}} [[krycha]], [[krecha]]; {{rzecz}} [[kresowy]] (1.4)
                # : (1.2) {{przym}} [[knajacki]] (=ordynarny, np. knajacki [[język]])
                # : {{czas}} [[umawiać]] ([[umawiać się|się]]) {{ndk}}, [[umówić]] ([[umówić się|się]]) {{dk}}
                # : {{rzecz}} [[wyznaczanie]] {{n}} / [[wyznaczenie]] {{n}}, [[niewyznaczanie]] {{n}} / [[niewyznaczenie]] {{n}}, [[wyznacznik]] {{m}}, [[znak]] {{m}}, [[znaczek]] {{m}}, [[znakownik]] {{m}}
                # : {{czas}} [[popielić]] ([[spopielić]])

                # ::
                s/ ^ :+ //x;

                # ''forma męska''
                s/ \s? '' [^\']* '' //x;

                # <ref name="Karłowicz" />
                s{ <ref \s+ [^/>]* /> }{}xg;

                # <ref name="MP">...</ref>
                s{ <ref (?: \s | > ) .*? </ref> }{}xg;

                # zobacz też:
                s{ zobacz \s też: \s }{}xg;

                # {{zob|[[gryźć]]}}
                s/ \s? \{\{ zob \| ( [^}]* ) \}\} /$1/xg;

                # {{m}}
                s/ \s? \{\{ [^}]* \}\} //xg;

                # (=ordynarny, np. knajacki [[język]])
                s/ \s? \( = [^=]* \) //xg;

                # (1.1-2,2.1)
                s/ \s? \( [0-9.,-]* \) //xg;

                # [[stary|stara]]
                s/ \[\[ [^|\]]* \| ( [^\]]* ) \]\] /$1/xg;

                # [[miłość]]
                s/ \[\[ ( [^\]]* ) \]\] /$1/xg;

                # •
                s/ \s? • //xg;

                # inne separatory na przecinek
                s{ [;/] \s? }{,}xg;

                # spacja przed i po przecinku
                s/ \s* , \s* /,/xg;

                # podwójne przecinki
                s/ , ,* /,/xg;

                # przecinek lub spacja na początku
                s/ ^ [,\s]+ //x;

                # przecinek lub spacja na końcu
                s/ [,\s]+ $ //x;

                # rozmyślić (się)
                s/ ( ^ | , ) ( [^,]* ) \s \( się \) /$1$2,$2 się/xg;

                # popielić (spopielić)
                s/ ( ^ | , ) ( [^,]* ) \s \( ( [^)]+ ) \) /$1$2,$3/xg;

                my $line = $_;

                last unless $line;

                print $fhout "$title,$line\n";
            }

            FREE: $t->purge;
        },
    },
);

$twig->parse($fhin);
