use Test;

use RakuAdvent::WordPress;

plan 2;

my $w1 = 'wordpress.html';
my $w2 = '.wordpress.html.tmp.no-inserted-code';

my $r = 'test.raku';
spurt $r, q:to/HERE/;
say "boo"
HERE

my $f = 'test.html';
spurt $f, q:to/HERE/;
<p>some
text</p>

 <ol>
<li>item 1
</li>
  </ol>

<!-- insert test.raku raku -->
HERE

my $s;

shell "perl6 -Ilib ./bin/make-wp-input $f";

$s = slurp $w1;
is $s, q:to/HERE/;
<p>some text</p>
<ol>
<li>item 1</li>
</ol>
<pre><code>say "boo"</code></pre>
HERE

$s = slurp $w2;
is $s, q:to/HERE/;
<p>some text</p>
<ol>
<li>item 1</li>
</ol>
<!-- insert test.raku raku -->
HERE

END {
    unlink $r;
    unlink $f;
    unlink $w1;
    unlink $w2;
}
