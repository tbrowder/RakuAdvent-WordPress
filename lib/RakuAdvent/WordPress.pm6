unit module RakuAdvent::WordPress;

use Text::Utils :normalize-string;
use RakuAdvent::WPTag; #= a class

# some local vars
my $tmpf = '.wordpress.html.tmp.no-inserted-code';

# for regexes
my $insert-rx     = rx/^ '<!--' \h+ 'insert ' (\S+) \h+ (\S*) \h* '-->' \h* $/;

# for error conditions
my $err-start-tag-rx  = rx/^ \h* (\S+) \h* '<' ([p|li|h\d|ul|ol|pre|hr]) .* '>' /;
my $err-end-tag-rx    = rx/ '</' ([p|li|h\d|ul|ol|pre]) '>' \h* (\S+) \h* $/;
my $err-hr-end-tag-rx = rx/ ('hr') \h* '/'? '>' \h* (\S+) \h* $/;

# for tag definitions
my regex tag-chars {<[a..zA..B1..6]>}

sub get-tag-string(@lines, $tag) is export {
    #| the tags we handle here: p, h1..6, li
    #| input should be:
    #|   the array of lines remaining, including
    #|     the line with the opening tag
    #|     as the first line of the array
    #| return:
    #|   the complete tagged line normalized
    #| note the lines used are shifted off the
    #|   array of lines
}

sub cvt2md($of, @ofils, :$debug) is export {
    #| Convert the intermediate Wordpress html file to a markdown
    #| version suitable for conversion, via a Github gist, to a
    #| highlighted html file for use in Wordpress.  Any inserted code
    #| is assumed for now to be Raku code.
    #|
    #| The code insert line may have a second field
    #| to identify the type of code using Github syntax.
    my $fh = open $of, :w; # this file WILL get code inserted
    my $para    = '';
    my $linenum = 0;
    my @lines   = $tmpf.IO.lines;
    my $last-tag;
    LINE: for @lines -> $line {
        ++$linenum;
        my $tag = error-check $line, $linenum, :file($tmpf);
        say "DEBUG: Found start tag '$tag' in \$tmpf file '$tmpf'" if $debug;
        # do stuff with the tagged line, then save the $tag as $last-tag

        #if $line ~~ /^ '<!--' \h+ 'insert ' (\S+) \h+ (\S*) \h* '-->' \h* $/ {
        if $line ~~ $insert-rx {
            my $fnam     = ~$0;
            my $code-typ = $1 ?? ~$1 !! '';
            if $debug > 1 {
                say "DEBUG:";
                say "Found insert line '$line'";
                say "file name: '$fnam'";
                say "code type: '$code-typ'";
                say "DEBUG: early exit";
                exit;
            }

            insert-code $fh, $fnam, :typ($code-typ), :$debug;
            next LINE
        }
        # collapse all blank lines outside code
        elsif $line !~~ /\S/ {
            next LINE;
        }
        elsif $line ~~ /^ \h* '<p>' \N* '</p>' \h* $/ {
            # single line para
            if $para {
                note "para: |$para|";
                die "FATAL: new single-line para without an end para at line $linenum";
            }
            # process the para
            $para = normalize-line $line, :type<p>;
            # write out the para
            $fh.say: $para;
            $para = '';
        }
        elsif $line ~~ /^ \h* '<p>' / {
            # beginning of a para
            if $para {
                note "para: |$para|";
                die "FATAL: new para without an end para at line $linenum";
            }
            $para ~= $line;
        }
        elsif $line ~~ / '</p>' \h* $/ {
            # end of a para
            if !$para {
                note "para: |$para|";
                die "FATAL: para end without a begin para at line $linenum";
            }
            $para ~= ' ';
            $para ~= $line;
            # process the para
            $para = normalize-line $para;
            # write out the line
            $fh.say: $para;
            $para = '';
        }
        elsif $para {
            $para ~= ' ';
            $para ~= $line;
        }
        else {
            $fh.say: $line;
        }
    }

    $fh.close;

    @ofils.append: $of;

}

sub cvt2html($if, $of, @ofils, :$debug) is export {
    #| Convert the incoming raw html file to a version suitable for
    #| use in Wordpress.  Also writes a separate file, $imf, that
    #| retains any code-insert line and does include any external
    #| code.
    my $fh    = open $of, :w;
    my $fhtmp = open $tmpf, :w; # this file will not get code inserted

    my $para      = '';
    my $list-item = '';
    my $linenum   = 0;
    my @lines     = $if.IO.lines;
    LINE: for @lines -> $line is copy {
        ++$linenum;
        error-check $line, $linenum, :file($if);
        if $line ~~ /^ '<!--' \h+ 'insert ' (\S+) \h+ (\S*) \h* '-->' \h* $/ {
            my $fnam = ~$0;
            my $code-typ = $1 ?? ~$1 !! '';
            if 0 && $debug {
                say "DEBUG:";
                say "found insert line '$line'";
                say "file name: '$fnam'";
                say "code type: '$code-typ'";
                say "DEBUG: early exit";
                exit;
            }

            # keep the line on the tmpf file here
            $fhtmp.say: $line;

            insert-code $fh, $fnam, :typ($code-typ), :$debug;
            next LINE

        }
        # collapse all blank lines outside code
        elsif $line !~~ /\S/ {
            next LINE;
        }
        #=== PARA =======================================================
        elsif $line ~~ /^ \h* '<p>' \N* '</p>' \h* $/ {
            # single line para
            if $para {
                note "para: |$para|";
                die "FATAL: new single-line para without an end para at line $linenum";
            }
            # process the para
            $para = normalize-line $line, :type<p>;
            # write out the para
            $fh.say: $para;
            $fhtmp.say: $para;
            $para = '';
        }
        elsif $line ~~ /^ \h* '<p>' / {
            # beginning of a para
            if $para {
                note "para: |$para|";
                die "FATAL: new para without an end para at line $linenum";
            }
            $para ~= $line;
        }
        elsif $line ~~ / '</p>' \h* $/ {
            # end of a para
            if !$para {
                note "para: |$para|";
                die "FATAL: para end without a begin para at line $linenum";
            }
            $para ~= ' ';
            $para ~= $line;
            # process the para
            $para = normalize-line $para, :type<p>;
            # write out the line
            $fh.say: $para;
            $fhtmp.say: $para;
            $para = '';
        }
        elsif $para {
            $para ~= ' ';
            $para ~= $line;
        }
        #=== END PARA =======================================================
        #=== LIST ITEM =======================================================
        elsif $line ~~ /^ \h* '<li>' \N* '</li>' \h* $/ {
            # single line list item
            if $list-item {
                note "list item: |$list-item|";
                die "FATAL: new single-line list item without an end list item at line $linenum";
            }
            # process the list item
            $list-item = normalize-line $line, :type<li>;
            # write out the list-item
            $fh.say: $list-item;
            $fhtmp.say: $list-item;
            $list-item = '';
        }
        elsif $line ~~ /^ \h* '<li>' / {
            # beginning of a list item
            if $list-item {
                note "list item: |$list-item|";
                die "FATAL: new list-item without an end list item at line $linenum";
            }
            $list-item ~= $line;
        }
        elsif $line ~~ / '</li>' \h* $/ {
            # end of a list-item
            if !$list-item {
                note "list item: |$list-item|";
                die "FATAL: list item end without a begin list item at line $linenum, file: $if";
            }
            $list-item ~= ' ';
            $list-item ~= $line;
            # process the list-item
            $list-item = normalize-line $list-item, :type<li>;
            # write out the line
            $fh.say: $list-item;
            $fhtmp.say: $list-item;
            $list-item = '';
        }
        elsif $list-item {
            $list-item ~= ' ';
            $list-item ~= $line;
        }
        #=== END LIST ITEM  =======================================================
        elsif $line ~~ /^ \h* '<' [ol|ul]/ {
            # remove leading spaces
            $line ~~ s/^ \h* '<'/</;
            $fh.say: $line;
            $fhtmp.say: $line;
        }
        elsif $line ~~ /^ \h* '</' [ol|ul]/ {
            # remove leading spaces
            $line ~~ s/^ \h* '<'/</;
            $fh.say: $line;
            $fhtmp.say: $line;
        }
        else {
            $fh.say: $line;
            $fhtmp.say: $line;
        }
    }

    $fh.close;
    $fhtmp.close;

    @ofils.append: $of;
    @ofils.append: $tmpf;
}

sub extract-headings($f) is export {
    #| Extracts lines with html headings. Such lines
    #| cannot have extraneous characters outside
    #| the tags and the heading must be complete
    #| on one line.
    for $f.IO.lines -> $line {
        if $line ~~ /^\h* '<h' <[1..6]>/ {
            say $line;
        }
    }
}

sub insert-code($fh,           # output file handle
               $code-file,     # name of code file to insert
               :$typ,          # what kind of code is being inserted?
               :$debug) {
    die "FATAL: No code type entered." if !$typ;

    my @lines2  = $code-file.IO.lines;
    my $nlines2 = @lines2.elems;
    my $lnum    = 0;
    for @lines2 -> $line2 {
        if $nlines2 == 1 {
            # the first and only line
            $fh.print: '<pre><code>';
            $fh.print: $line2;
            $fh.say: '</code></pre>';
        }
        elsif !$lnum {
            # the first line
            $fh.print: '<pre><code>';
            $fh.say: $line2;
        }
        elsif $lnum == $nlines2 - 1 {
            # the last line
            $fh.print: $line2;
            $fh.say: '</code></pre>';
        }
        else {
            $fh.say: $line2;
        }
        ++$lnum;
    }
}

sub normalize-line($s is copy, :$type!) is export {
    # string s should look like one of these:
    #    |<p> some text </p>
    #    |<li> some text </li>
    if $type eq 'p' {
        # remove tags
        $s ~~ s/^ \h* '<p>'//;
        $s ~~ s/'</p>' \h* $//;
        # normalize the remainder
        $s = normalize-string $s;
        # snugly add tags back on
        $s = '<p>' ~ $s;
        $s ~= '</p>';
    }
    elsif $type eq 'li' {
        #die "not yet ready for tag 'li'";
        # remove tags
        $s ~~ s/^ \h* '<li>'//;
        $s ~~ s/'</li>' \h* $//;
        # normalize the remainder
        $s = normalize-string $s;
        # snugly add tags back on
        $s = '<li>' ~ $s;
        $s ~= '</li>';
    }
    $s
}

sub error-check($line, $linenum, :$file, :$debug) is export {
    # check for certain tags we require to be on the ends of a line
    note "DEBUG: line $linenum: |$line|" if $debug;

    my $tag = '';
    if $line ~~ $err-start-tag-rx {
        my $s = ~$0;
        my $t = ~$1;
        die "ERROR: found text '$s' in front of tag '<$t>' on line $linenum, file: $file";
    }
    if $line ~~ $err-end-tag-rx {
        my $t = ~$0;
        my $s = ~$1;
        die "ERROR: found text '$s' after closing tag '</$t>' on line $linenum, file: $file";
    }
    if $line ~~ $err-hr-end-tag-rx {
        my $t = ~$0;
        my $s = ~$1;
        die "ERROR: found text '$s' after closing tag '</$t>' on line $linenum, file: $file";
    }

    # Now report the tag
    # horizontal rule takes special handling, it can be in these forms:
    #   <hr>   # html5
    #   <hr/>  # html4
    #   <hr /> # html4
    if $line !~~ /^ \h* '<' '/'? <tag-chars>+ \h* '>' / {
        $tag = '';
    }
    elsif $line ~~ /^ \h* '<' ('hr') \h* '>' / {
        $tag = ~$0;
    }
    elsif $line ~~ /^ \h* '<' '/'? ('pre><code') '>' / {
        $tag = ~$0;
    }
    elsif $line ~~ /^ \h* '<' '/'? ('pre') '>' / {
        $tag = ~$0;
    }
    elsif $line ~~ /^ \h* '<' (\S+) '>' / {
        $tag = ~$0;
    }

    $tag;
}

sub write-example($dir, :$force) is export {
    my $s  = slurp %?RESOURCES<examples/advent-example.html>;
    my $of = "$dir/advent-example.html";
    if !$force && $of.IO.f {
        die "FATAL: File '$of' exists. Move it or use the '--force' option."
    }
    spurt $of, $s;
}

sub show-example is export {
    my $s  = slurp %?RESOURCES<examples/advent-example.html>;
    say $s;
    exit
}

sub help($usage, $of) is export {
    say $usage;
    say qq:to/HERE/;
    Converts html source in the input file
      to WordPress html in the output file '$of'.

    Use the '-x' option to extract headings from the input
      file for QC.

    Use the '-eg' option to write the example file to STDOUT.

    Use the '-c' option to convert to markdown. [NOT YET IMPLEMENTED]
    HERE
    exit;
}
