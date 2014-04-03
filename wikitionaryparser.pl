#!/usr/bin/perl -w

use strict;
use warnings;

use utf8;

use Smart::Comments;

use XML::Twig;
use Getopt::Long;
use LWP::Simple;

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

use IO::Pipe;

unless (-e "plwiktionary-latest-pages-articles.xml.bz2")
{
    getstore ("http://dumps.wikimedia.org/plwiktionary/latest/plwiktionary-latest-pages-articles.xml.bz2","plwiktionary-latest-pages-articles.xml.bz2");
}

my $fhin = IO::Pipe->new->reader(qw(bzip2 -c -d plwiktionary-latest-pages-articles.xml.bz2)) or die "Cannot pipe: $!";
open my $fhout, '>:utf8', "$output";

# at most one div will be loaded in memory
my $twig=XML::Twig->new(
twig_handlers =>
{
        text => \&text_tag,          # process list elements
},
);

$twig->parse($fhin);

sub text_tag
{
    my ($t, $elem) = @_;

    my ($line,@lines,$title);

    my $text = $elem->text;

    #Check, if given word belongs to the Polish language
    if ($text =~ /^== .* \(\{\{język polski\}\}\) ==/)
    {
            @lines = (split /\n/, $text);
    }
    else
    {
            goto FREE;
    }

    $title = $lines[0];

    while (@lines)
    {
        $line = shift @lines;
        if ($line =~ /^\{\{$word\}\}/)
        {
                $line = shift @lines;
                while ($line =~ /^:/)
                {
                        #Usunięcie niepotrzebnych znaków wokół słowa
                        $title =~ s/== //g;
                        $title =~ s/ ==//g;
                        $title =~ s/\(\{\{język polski\}\}\)//;
                        $title =~ s/\s$//g;
                        $title =~ s/^\s+//;
                        $title =~ s/\{\{.*?\}\}//g;
                        $title =~ s/\[\[(.*?)\]\]//g;

                        $line =~ s/:\s*//g;
                        $line =~ s/\{\{.*?\}\}//g;
                        $line =~ s/\[\[(.*?)\]\]/$1,/g;
                        $line =~ s/,+\s*/,/g;
                        $line =~ s/,\s*$//g;
                        $line =~ s/,\/,/,/g;
                        $line =~ s/,,+/,/g;
                        $line =~ s/''.*?''//g;
                        $line =~ s/^\s+//;
                        $line =~ s/\(.*\)//g;
                        $line =~ s/\{\{//g;
                        
                        if ($line)
                        {
                            print $fhout $title . "," .$line . "\n";
                        }
                        else
                        {
                            print $fhout $title . "\n";
                        }

                        $line = shift @lines;
                }
        }
    }

    FREE: $t->purge;
    return;
}

sub help
{
        print "Usage: wikitionaryparser.pl --word=\$word; It will extract content\
of category '\$word' from description of Polish words to csv\n";
        print "--output; Chagnes name of the file with data, default name is \$word\n";
        print "--help; Shows this help\n";
        die;
}
