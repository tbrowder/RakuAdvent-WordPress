#| A class to load data for a Wordpress HTML tag and its data
unit class RakuAdvent::WPTag;

has $.tag;
has $.str;  # paras, list items
has @.strs; # lists, pre (code)

method write-html($fh) {
    my $t = $.tag;
    if $t ~~ /[ol|ul]/ {
        $fh.say: "<$t>";
        for @.strings -> $s {
            $fh.say: "<li>$s</li>";
        }
        $fh.say: "</$t>";
    }
    elsif $t eq 'hr' {
        $fh.say: '<hr />';
    }
}

method write-md($fh) {
}


