# CheckCrossRefs
PURPOSE: Find cross references without targets (in an SFM file); adjust their markers so they can be imported into a custom field and linked manually, instead of creating a spurious entry.

REQUIRED MODULE:  Config::Tiny

(See the paragraph "To install some Perl modules..." on the site  
https://sites.google.com/sil.org/importing-sfm-to-flex/workflow/set-up-infrastructure/set-up-a-linux-terminal to learn how to install this module.)

INPUT/OUTPUT FILES: specified in .ini FILE

This script uses a .ini file to determine the input file, output file, and which markers it should look at.
To use this script, first edit the .ini file with the appropriate values for your project.
Then you can run the script by simply typing the following at the command line:

USAGE:  perl check_cf_special.pl

LOGFILE: writes a logfile indicating:
 * what markers it checked
 * which references were found to have valid targets in the database
 * which references had targets that were not in the database

For the "not found" references, it modifies the marker to include _NF.  Because the "not found"
refs have a different marker from the found ones, they can be imported into a custom field in FLEx.
(Note that you need to create the custom field in the empty database you will be importing into.)

Missing targets can be the result of several things:
 - Maybe the word is not in the database at all
 - Maybe the reference has more than one target all in one field:  \va colorise, colourise
 - Maybe the reference is missing a homograph number that is needed
 - Maybe the target is misspelled

If the import specialist puts these into a custom field, the linguist can easily find them, and they can decide how they want to fix the missing link.  After they fix it, they can delete the contents of the custom field, to make it easier to see which ones have not been dealt with yet.

SAMPLE FILES:
 There is a folder called SampleData with enough files for you to test this script to see
 how it works.

  * SampleEnglish-BeforeCheckRefs.db	Sample input file
  * check_cf-Eng.ini					The .ini file, customized for this database
  * check_cf_special-Eng.pl				The script modified to use this custom .ini file (search for "EDIT THE FOLLOWING LINE" to see where the .ini file is specified)
  
SAMPLE USAGE:
 To run this customized script on this sample data, type the following at the command line, when
 you are in a directory that includes the script, the .ini file, and the input SFM file:
 
   perl check_cf_special-Eng.pl

 Running this command will produce two output files.  The folder ExpectedOutput contains files that show what output is expected.  You can compare your output files with what is in that folder, to see if your output came out as expected.
 
SAMPLE OUTPUT (in ExpectedOutput folder):

  * SampleEnglish-AfterCheckRefs.db		Shows what the output should look like
  * CheckRefs-Log.db					Show what the log looks like for this data
