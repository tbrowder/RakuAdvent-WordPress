[![Build Status](https://travis-ci.org/tbrowder/RakuAdvent-WordPress.svg?branch=master)](https://travis-ci.org/tbrowder/RakuAdvent-WordPress)

# RakuAdvent::WordPress

This module provides a Raku tool (*make-wp-input*) to aid Raku Advent
authors in preparing their article source for conversion to a format
compatible with the html and css used by WordPress (WP).

## Installation
```raku
zef install RakuAdvent::WordPress;
```
## Documentation
```raku
zef install p6doc
p6doc RakuAdvent::WordPress;
```
## Example uses

See the example html source file included with
the module:
```raku
$ make-wp-input -eg > advent.html
```

Create a raw html source file and format it
for input to WordPress (with automatic error checking):
```raku
$ make-wp-input advent.html
Normal end.
See output files:
  'wordpress.html'
  '.wordpress.html.tmp.no-inserted-code'
```

Check headings for desired sequence and size:
```raku
$ make-wp-input advent.html -x
<h3>Introduction</h3>
<h3>Background</h3>
<h4>Article creation</h4>
<h3>Summary</h3>
<h2>APPENDIX</h2>
<h3>Notes</h3>
<h3>References</h3>
```

Note the source html must meet some simple rules
to ensure success with the current state of *make-wp-input*:

1. The following opening tags should be the only characters on their respective
lines:

- \<ul>
- \<ol>

2. At the moment do **not** use any html comments except:

- \<!-- Day N - My Advent Post Title --> [ON THE FIRST LINE ONLY]
- \<!-- insert file-name code-type -->

See the example file for an illustration of the title line.  See the
test file `t/02-example-advent-html.t` for an example of inserting
code into the source file.

Note the interaction of other html source tags with WP may not be as
expected. You are encouraged to preview results and experiment for
yourself. The WP website is still under development, and user input is
encouraged.

## Planned features
- Convert html to Github-flavored markdown
- Allow paragraphs in the source html to be
  recognized by either blank lines above and below
  the text or a line with a closing tag on the
  line before the text or an opening tag on
  the line following the text
- Use the WordPress API to do all interaction
  with the user via the command line including:
    - posting the generated WP html
    - setting the scheduled publication time
    - changes to the post or scheduled time

## References
- <a href="https://developer.wordpress.org/rest-api/">WordPress API</a>
- <a href="https://developer.github.com/v3/">Github API</a>

## See also
- `PasteBin::Gist`
- `Text::Wrap`
- `Acme::Advent::Highlighter`

## LICENSE

Artistic 2.0. See the license [here](./LICENSE).

## COPYRIGHT

Copyright (C) 2019 Thomas M. Browder, Jr. <<tom.browder@gmail.com>>
