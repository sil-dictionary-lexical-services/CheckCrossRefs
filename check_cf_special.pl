
use feature ':5.10';
use warnings;
use Data::Dumper qw(Dumper);
use Time::Piece;
use Config::Tiny;
use utf8;

# Created:	2018	Cindy Mooney
# Modified:	
# Modified:	13 Feb 2020	Beth Bryson	add more comments
# ToDo: should use the following features, cf /SubentryPromotion/se2lx/se2lx.pl
# $USAGE variable for "or die" clauses
# Getopt::Long to get:
#		$inifile - use File::Basename to derive the default ini filename from the scriptname
#		$inisection - can have multiple runs with different configs



my $counter = 0;
my $row;
my @record;
my %fileArray;     #hash of entire file after hm corrections
my @controlArray;  #array of lexemes to insure output is in the same order as input file
my $hWord;
my $hm;
my $hWord_hm;
my $citForm;
my $lxRow;
my $cf_HWrd;
my @cf_Rec;
my @citForm_Array;   #array of citation forms which may match a cross ref
my $CRLF = "\n";
my @file_Array;     #array of the entire file before hm corrections
my %lx_Array;       #hash which links the lexemes to an array of homograph numbers
my @tmpRec;
my $TO_PRINT = "TRUE";    #Switch used to indicate no duplicates hm found in the file
my $DUPLICATE = "FALSE";
my @print_Array;    #array of entire file after hm corrections.  
my @list_to_check;  #items found in the ini file.  List of lex rels to check
my $CF_tag ;        #lex rel to check 
my @special_char_list =qw(* QQ ZZ);  #ZZ is dagger QQ is bullet
my $checker;
foreach my $s (@special_char_list){
	say $s;
}


my $date = localtime->strftime("%m/%d/%Y");

# EDIT THE FOLLOWING LINE TO PROVIDE THE NAME OF THE .INI FILE
my $ini_file = "check_cf.ini";

my $config = Config::Tiny->read($ini_file, 'crlf')
	or die "Could not open $ini_file $!";

my $infile = $config->{check_cf}->{infile};
my $outfile = $config->{check_cf}->{outfile};
my $log_file = $config->{check_cf}->{logfile};
my $LC_tag = $config->{check_cf}->{cit_form};
$list_to_check = $config->{check_cf}->{list_to_check};
if ( $list_to_check =~ ','){
	@list_to_check = split(',', $list_to_check);
}
else {@list_to_check = $list_to_check; }

open(my $fhlogfile, '>:encoding(UTF-8)', $log_file) 
	or die "Could not open file '$log_file' $!";

open(my $fhoutfile, '>:encoding(UTF-8)', $outfile) 
	or die "Could not open file '$outfile' $!";

open(my $fhinfile, '<:encoding(UTF-8)', $infile)
  or die "Could not open file '$infile' $!";


write_to_log("Input file $infile Output file $outfile   $date");

##########################  Add homographs if needed.  Verify no duplicates. ######################
# build a hash lexeme->[hm,hm,hm] or lexeme->[0] if it is not a homonym.
# Read the file into memory
 
while ( $row = <$fhinfile> ) {
      
	if ( $row =~ /^\\lx/ ) {
		$lxRow = $row;
		$hWord = substr $row, 4;

 		#remove any extra spaces at the beginning and end of the headword.
                $hWord =~ s/^\s+|\s+$//g; 

		if ( !exists $lx_Array{$hWord} ){
			@{$lx_Array{$hWord}{index}} = 0;
		}
		else {
	 		@tmpRec = @{$lx_Array{$hWord}{index}};
			push @tmpRec, 0;
			@{$lx_Array{$hWord}{index}} = @tmpRec;
		}

		push @file_Array, $lxRow;
	}
	elsif ( $row =~ /^\\hm/ ) { 
		my $hm_row = $row;
		#get the hm number
		$row =~ /\\hm\s+(\d+)/;
		$hm = $1;
	
		# add the hm number to the array associated with the key.
		
	 	@tmpRec = @{$lx_Array{$hWord}{index}};
		pop @tmpRec;
		push @tmpRec, $hm;
		@{$lx_Array{$hWord}{index}} = @tmpRec;
		push @file_Array, $hm_row;
	}
	elsif ( $row =~ /^\\_sh/  || $row =~ /^$/ ) {

		#do nothing

	}
	else {

		push @file_Array, $row; 

	}

}


#print Dumper(\%lx_Array);

#I've built my hash array of lexeme->[0|hm+].   Iterate through each of the hm lists and 
#fill in the zero's with the next largest number if the record is a homonym.
#
write_to_log("\n######### Checking homographs  ##########\n");

foreach my $key ( keys %lx_Array ){
my %seen;
my $hm_val;
my @dup_rec;

	$DUPLICATE = "FALSE";
	@tmpRec = @{$lx_Array{$key}{index}};
	if ( scalar @tmpRec > 1 ){
		#this is a homonym
		#check here to see if we have any duplicate \hm for this lexeme.
	 	@dup_rec = @tmpRec;
		@dup_rec = grep { $_  != 0 } @dup_rec;
		foreach $hm_val (@dup_rec){
			next unless $seen{$hm_val}++;
			$DUPLICATE = "TRUE";
		
		}
		if ($DUPLICATE eq "TRUE"){
			write_to_log(qq(CANNOT PROCEED: Duplicate homograph value for lexeme $key));
			$TO_PRINT = "FALSE";

	 	}	
		else {
			for (my $i=0; $i< scalar @tmpRec; $i++ ){
				if ( $tmpRec[$i] == 0 ){
					#get max number 
					my @sorted = sort { $a <=> $b } @tmpRec;
					my $largest = pop @sorted;
					$largest++;
					@tmpRec[$i]=$largest;
					write_to_log("Updating lexeme $key with hm $largest");
				}
			}
		}
	}
	@{$lx_Array{$key}{index}} = @tmpRec;
}

			

#print Dumper(\%lx_Array);




if ($TO_PRINT eq "TRUE"){

	foreach my $r (@file_Array){

		if ( $r =~ /^\\lx/ ){
	
			$hWord = substr $r, 4;
       		        $hWord =~ s/^\s+|\s+$//g; 
			push @print_Array, "\n";
			push @print_Array, $r;


			my $hm = shift @{$lx_Array{$hWord}{index}};
			if ( $hm > 0 ){
				my $tmpRow = "\\hm $hm\n";
				push @print_Array, $tmpRow; 
			}
		}
		elsif ($r =~ /^\\hm/) {}
		else { 
			push @print_Array, $r;	
			
		}
	}
}
else {
	write_to_log (qq(Duplicate \\hm values have been found. SFM file must be corrected.));
	print $fhoutfile (qq(No data has been written. See details in log file.));
	close $fhlogfile;
	close $fhinfile;
	close $fhoutfile;
	exit;
}


##################  Verify cross refs.  If cf has no matching lx or lc, update tag to cf_NF #################
#homographs checked and added if needed.  Now on to checking cross refs...

foreach $row (@print_Array) {
      
	if ( $row =~ /^\\lx/ ) {
		$lxRow = $row;
		$counter = 0;

		#add the headword to the controlArray.
		$hWord = substr $row, 4;

 		#remove any extra spaces at the beginning and end of the headword.
                $hWord =~ s/^\s+|\s+$//g; 
		
		push @controlArray, $hWord;
		$fileArray{$hWord}{record}[$counter++] = $lxRow;
	}
	elsif ( $row =~ /^\\$LC_tag/ ) { 
		#build citation form list. Must check this as well.
		
		$row =~ /\\$LC_tag\s+(.*)$/;
		$citForm = $1;

 		#remove any extra spaces at the beginning and end.
		$citForm =~ s/^\s+|\s+$//g; 

		#remove any extra digits representing sense numbers.

		push @citForm_Array, $citForm;
		$fileArray{$hWord}{record}[$counter++] = $row;
	}
	elsif ( $row =~ /^\\hm/ ) { 
		
		#get the hm number
		$row =~ /\\hm\s+(\d+)/;
		$hm = $1;

		# add the hm number to the headword to be used as a key
		$hWord_hm = $hWord.$hm;
		
		#because I changed the headword to use the hm number as well, I need to change 
		#the values in the control array and also the file array. 

		pop @controlArray; 
		push @controlArray, $hWord_hm;

	 	my @tmpRec = @{$fileArray{$hWord}{record}};
		delete $fileArray{$hWord};

		$counter = @tmpRec;
		$hWord = $hWord_hm;
		@{$fileArray{$hWord}{record}} = @tmpRec;
		$fileArray{$hWord}{record}[$counter++] = $row;
	}
	elsif ( $row =~ /^\\_sh/  || $row =~ /^$/ ) {

		#do nothing

	}
	else {

		$fileArray{$hWord}{record}[$counter++] = $row;
	}

}
 	
#print Dumper(\%fileArray);
my $IS_FOUND = "FALSE";
foreach my $l (@list_to_check){
	$CF_tag = $l;
	my $CF_tag_not_found = $CF_tag."_NF";
	write_to_log("\n########  Checking $CF_tag  #########\n");
	foreach my $i (@controlArray) {
		@record = @{$fileArray{$i}{record}};
		#process record... 
		foreach my $r (@record) {
			if ( $r =~ /^\\lx/ ) {
				$hWord = substr $r, 4;
                		$hWord =~ s/^\s+|\s+$//g; 
			}
			elsif ( $r =~ /^\\$CF_tag / ) {
				
				$r =~ /\\$CF_tag\s+(.*)$/;
				$cf_HWrd = $1;
				my $saved = $cf_HWrd;
                		$cf_HWrd =~ s/^\s+|\s+$//g; 
				#
				#remove digits indicating sense number. Pattern for homograph # and sense #'s 
				#is \cf word\d \d where the first \d is the homograph and the second digit is the sense 
				#note the sense number may be sense.subsense.  
				#
				#
				#use the word|hm combo to check the hash for matching key (lxhm).
				#removing sense numbering if any.
				$cf_HWrd =~ s/\s+\d.*//g;
				my $cf_HWrd_hm = $cf_HWrd;
				#
				#use the word without homograph digits to check the citation form array.
				#
				my $cf_HWrd_no_digits = $cf_HWrd; 
				$cf_HWrd_no_digits =~ s/\d.*//g;
			
			
				if (length($cf_HWrd_hm) > 0 ){
					my $z;
					if ($cf_HWrd_hm eq $i ){   
						write_to_log("WARNING! \\$CF_tag $cf_HWrd is a cross ref to the record in which it's found: $i");
					}
					
					elsif (!exists  $fileArray{$cf_HWrd_hm} ){
						$IS_FOUND = "FALSE";
						foreach my $zz (@special_char_list){
							$checker = $zz.$cf_HWrd_hm;	
							
							foreach my $q (@controlArray){
								if ( $q eq $checker ){
									$IS_FOUND = "TRUE";
									$z=$zz;
									last;
								}
							}
						}
						
						if ($IS_FOUND eq "TRUE"){
							#update the cf line to match the lx 
			 				$r = "\\$CF_tag $z$saved\n"; 
							delete $fileArray{$i};
							@{$fileArray{$i}{record}} = @record;
							write_to_log("Updated \\$CF_tag $cf_HWrd -> \\$CF_tag $z$cf_HWrd");
					
					
						}
						else {
			  				#here is the interesting case.  If I haven't found a matching \lx or \lc 
							#then I need to update the original \cf line to \cf_NF (meaning cross ref Not Found).
			  				#
			 				$r =~ s/\\$CF_tag/\\$CF_tag_not_found/; 
							delete $fileArray{$i};
							@{$fileArray{$i}{record}} = @record;
							write_to_log("No match for  \\$CF_tag $cf_HWrd  - \\lx $hWord");
						}#if !$IS_FOUND
					}
					#new
					else { write_to_log("Found \\$CF_tag $cf_HWrd - \\lx $hWord");
					}	
				} #length > 0
		    	} #elsif I found \cf
		}#foreach r
	} #foreach $i
}#foreach $list_to_check

#now print the file
foreach my $i (@controlArray) { 
	
@record = @{$fileArray{$i}{record}};
print $fhoutfile @record;
print $fhoutfile "\n";

}




sub write_to_log{

        my ($message) = @_;
	        print $fhlogfile $message;
		print $fhlogfile $CRLF;
}



close $fhlogfile;
close $fhinfile;
close $fhoutfile;

