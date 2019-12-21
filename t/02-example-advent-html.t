use Test;

use RakuAdvent::WordPress;

plan 1;


my $path = '.';
my $of = "$path/advent-example.html";
write-example $path;
my $s1 = slurp $of;
my $s2 = slurp "t/data/advent-example.html";
is $s1, $s2;

END {
    unlink $of;
}
