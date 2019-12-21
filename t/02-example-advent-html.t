use Test;

use RakuAdvent::WordPress;

plan 5;

my $path = 't';
my $of = "$path/advent-example.html";
unlink $of;
write-example $path;
my $s1 = slurp $of;
my $s2 = slurp "t/data/advent-example.html";
is $s1, $s2;

dies-ok { write-example $path }, 'try to overwrite existing file';

lives-ok { write-example $path, :force }, 'use --force option';

my $incfil = "t/data/Mod.pm6";
my $simfil = "t/data/simple.html";
shell "perl6 -Ilib ./bin/make-wp-input $simfil";
# use the output files
my $w1 = 'wordpress.html';
my $w2 = '.wordpress.html.tmp.no-inserted-code';

$s1 = slurp $w1;
$s2 = slurp $w2;

is $s1, q:to/HERE/;
<p>intro</p>
<pre><code>unit module Mod;

say "boo"</code></pre>
<p>summary</p>
HERE

is $s2, q:to/HERE/;
<p>intro</p>
<!-- insert t/data/Mod.pm6 raku -->
<p>summary</p>
HERE

END {
    unlink $of;
    unlink $w1;
    unlink $w2;
}
