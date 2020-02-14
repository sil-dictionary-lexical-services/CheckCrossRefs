# CheckCrossRefs
Find cross references without targets (in an SFM file); adjust their markers so they can be imported into a custom field and linked manually, instead of creating a spurious entry

REQUIRED MODULE:  Config::Tiny

To install the Perl module Config::Tiny in your Perl system, there are a number of options.
One easy way is with CPAN.
At the command prompt, type:

cpan Config::Tiny

This should download the module and install it.

USES .ini FILE

This script uses a .ini file to determine the input file, output file, and which markers it should look at.
To use this script, first edit the .ini file with the appropriate values for your project.
Then you can run the script by simply typing the following at the command line:

perl check_cf_special.pl

OUTPUTS LOG FILES

As the script runs, it reports on the cross references that it checked, reporting both found targets and missing targets.

Missing targets can be the result of several things:
 - Maybe the word is not in the database at all
 - Maybe the reference has more than one target all in one field:  \va colorise, colourise
 - Maybe the reference is missing a homograph number that is needed
 - Maybe the target is misspelled
By putting these into a custom field, the linguist can easily find them, and they can decide how they want to fix the missing link.  After they fix it, they can delete the contents of the custom field, to make it easier to see which ones have not been dealt with yet.
