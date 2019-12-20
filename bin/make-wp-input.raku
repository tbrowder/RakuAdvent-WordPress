#!/usr/bin/env perl6

use lib <./lib ../lib>;
use RakuAdvent::WordPress;

my $if;
my $of    = "wordpress.html";
my $of-md = "wordpress.md";

my $usage = "Usage: $*PROGRAM <html source file> [-x][-c][-debug][-help]";
if !@*ARGS {
    say $usage;
    exit;
}

sub help {
    say $usage;
    say qq:to/HERE/;
    Converts html source in the input file
      to WordPress html in the output file '$of'.
    
    Use the '-x' option to extract headings from the input
      file for QC.
    
    Use the '-c' option to convert to markdown. [NOT YET IMPLEMENTED]
    HERE
    exit;
}

my $xtract  = 0;
my $convert = 0;
my $dd      = '';
my $debug   = 0;
for @*ARGS {
    when / '.html' $/ {
        # expected to be the input file
        $if = $_;
    }
    when /^ :i \- x/ {
        $xtract = 1;
    }
    when /^ :i \- h/ {
        help; # <== exits from there
    }
    when /^ :i \- c/ {
        $convert = 1;
    }
    when /^ :i \- d/ {
        $debug = 1;
    }
    when /^ :i \- 'd='(\d)/ {
        $debug = +$0;
    }
    default {
        note "FATAL: Unknown arg '$_'.";
        exit;
    }
}

if !$if.IO.f {
    note "FATAL: Input file '$if' not found.";
    exit;
}
elsif $if.IO.basename eq $of.IO.basename {
    note "FATAL: Input file '$if' is the same as the output file '$of'.";
    exit;
}


if 0 && $debug {
    say qq:to/HERE/;
    DEBUG:
    Input file: '$if'
    Output file name: '$of.html'
    Output file name: '$of.md'
    DEBUG early exit
    HERE
    exit;
}

if $xtract {
    extract-headings $if;
    exit;
}

my @ofils;
cvt2html $if, $of, @ofils, :$debug;

if $convert {
    # the input file is defined in the module
    cvt2md $of-md, @ofils, :$debug;
}

say "Normal end.";
my $nf = @ofils.elems;
if $nf {
    my $s = $nf > 1 ?? 's' !! '';
    say "See output file$s:";
    say "  '$_'" for @ofils;
}
else {
    say "No files generated.";
}
