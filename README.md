Wikitionaryparse
================

Parser for dump of Wikitionary base.
This script automaticly downloads file whith data,
from https://dumps.wikimedia.org/plwiktionary
if there is no such file in current directory.

Usage:
wikitionaryparse.pl --help shows help message.
wikitionaryparse.pl --word $word genereates file with $word attribute
of all Polish words in datafile.
wikitionaryparse.pl --output sets alternative name of output file.
Default name is $word.csv

