#!/usr/bin/perl -w

use strict;
use warnings;
use strict 'vars';

use Data::Dumper;
use XML::Twig;
use Getopt::Long;

my $help = '';
my $output = '';
my $word = '';

GetOptions
(
    'help' => \$help,
    'output=s' => \$output,
    'word=s' => \$word
);

if ($help)
{
    &help;
}

unless ($word)
{
        &help;
}

unless ($output)
{
    $output = $word . ".csv";
}

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
    open (DATA,">>$output");
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
        if ($line =~ /$word/)
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
                            print DATA $title . "," .$line . "\n";
                        }
                        else
                        {
                            print DATA $title . "\n";
                        }
                        $line = shift @lines;
                }
        }
    }

    close DATA;
}

sub help
{
        print "Usage: wikitionaryparser.pl --word=\$word; It will extract content\
of category '\$word' from description of Polish words to csv\n";
        print "--output; Chagnes name of the file with data, default name is \$word\n";
        print "--help; Shows this help\n";
        die;
}
