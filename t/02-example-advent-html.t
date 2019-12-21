use Test;

use RakuAdvent::WordPress;

plan 3;

my $path = 't';
my $of = "$path/advent-example.html";
write-example $path;
my $s1 = slurp $of;
my $s2 = slurp "t/data/advent-example.html";
is $s1, $s2;

dies-ok { write-example $path }, 'try to overwrite existing file';

lives-ok { write-example $path, :force }, 'use --force option';

END {
    unlink $of;
}
