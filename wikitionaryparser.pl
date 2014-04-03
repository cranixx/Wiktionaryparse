#!/usr/bin/perl -w

#TODO:Write code, wich will download a latest dump of wikitionary,
#and decompress it to plaintex, command line args handling, also needed

use strict;
use warnings;
use strict 'vars';

use Data::Dumper;
use XML::Twig;

# at most one div will be loaded in memory
my $twig=XML::Twig->new(
twig_handlers =>
{
        text => \&text_tag,          # process list elements
},
);

$twig->parsefile( 'plwiktionary-latest-pages-articles.xml');

sub text_tag
{
    open (POKREWNE,">>pokrewne.csv");
        my ($line,@lines,$title);
        #Check, if given word belongs to the Polish language
        if ($_->text =~ /^== .* \(\{\{j.zyk polski\}\}\) ==/)
        {
                @lines = (split /\n/, $_->text);
        }

    else
    {
            return;
    }

    $title = $lines[0];
    while (@lines)
    {
        $line = shift @lines;
        if ($line =~ /pokrewne/)
        {
                $line = shift @lines;
                while ($line =~ /^:/)
                {
                        #Usunięcie niepotrzebnych znaków wokół słowa
                        $title =~ s/== //g;
                        $title =~ s/ ==//g;
                        $title =~ s/\(\{\{j.zyk polski\}\}\)//;
                        $title =~ s/\s$//g;

                        $line =~ s/:\s*//g;
                        $line =~ s/\{\{.*\}\}//g;
                        $line =~ s/\[\[//g;
                        $line =~ s/\]\]/,/g;
                        $line =~ s/,\s*$//g;
                        if ($line)
                        {
                            print POKREWNE $title . "," .$line . "\n";
                        }
                        else
                        {
                            print POKREWNE $title . "\n";
                        }
                        $line = shift @lines;
                }
        }
    }

    close POKREWNE;
}

