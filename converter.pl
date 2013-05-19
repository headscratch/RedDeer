#!/usr/bin/perl

#Each course has a course number 'Ssbsect Crse Numb'
#Each course could have multiple offerings 
#Each offering has a clas numer 'Ssbsect Crn'

use RTF::Writer;
use strict;
use warnings;
use Text::CSV;
use Date::Manip;
use Date::Manip::Date;

my $file_to_convert; 
my $handle;
my $courses;


if (exists($ARGV[0])){
	$file_to_convert = $ARGV[0];
	}	
else{
	$file_to_convert = 'cal_report.csv';
}

 my $csv = Text::CSV->new ({ binary => 1, eol => $/ });
 open my $io, "<", $file_to_convert or die "$file_to_convert $!";
 my $header = $csv->getline ($io);
 my $rows = [];
 MOO:

#This loop puts the csv data into an array of hashes
#The keys for the hash are the column header names
 while (my $read_row = $csv->getline ($io)) {
		my %hashed_row;
		my $i = 0;
		foreach my $col(@$header){
			$hashed_row{$col} = @$read_row[$i];
			$i ++;
		}
		push(@$rows,\%hashed_row);

}

foreach my $row(@$rows){
	while ((my $key, my $value) = each(%$row)){
		print $key.": ".$value."\n";
	}
	print "\n\n";
}

#Creates a hash of course numbers containg the general course info
#And a hash of each class for the course
foreach my $row(@$rows){
	$courses->{$row->{'Ssbsect Crse Numb'}}->{'title'} = $row->{'Section-Course Title'};
	$courses->{$row->{'Ssbsect Crse Numb'}}->{'subject_code'} = $row->{'Ssbsect Subj Code'};
	$courses->{$row->{'Ssbsect Crse Numb'}}->{'desc'} = $row->{'zst_clob_to_string  \'SCBDESC\' '};	
	#this is each start and end date for a class
	$courses->{$row->{'Ssbsect Crse Numb'}}->{'class'}->{$row->{'Ssbsect Crn'}}->{'dates'}->{$row->{'Ssrmeet Start Date'}} = $row->{'Ssrmeet End Date'} ;		
	#this is the days of the week the class occurs on
	$courses->{$row->{'Ssbsect Crse Numb'}}->{'class'}->{$row->{'Ssbsect Crn'}}->{'days'} = split('',$row->{'Ssrmeet All Days'});			
}

while ((my $key, my $value) = each (%$courses)){
	print "Course Num: ". $key . " Title: ". $value->{'title'}. "\n";
#	print "Course Num: ". $key . " Subject Code: ". $value->{'subject_code'}. "\n";
#	print "Course Num: ". $key . " Description: ". $value->{'desc'}. "\n";
	while ((my $cls_num, my $cls) = each (%$value->{'class'})){
		print "Class Num: ". $cls_num. "\n";
		my $first_loop = 0;
		print $cls->{'days'}."\n";
		
		#set up date comparitors
		my $s_date = new Date::Manip::Date; 
		my $e_date = new Date::Manip::Date; 

		
		$s_date = ParseDate('01 Jan 1973, 1:01:01');
		$e_date = ParseDate('01 Jan 1973, 1:01:01');
		
		my $num_of_days = 0;
		
		#loop through all the dates for an offering and find the min start date
		#and the max start date
		while ((my $start_date, my $end_date) = each (%$cls->{'dates'})){
			
			my $temp_s_date = new Date::Manip::Date->new(); 
			my $temp_e_date = new Date::Manip::Date; 
			
			$temp_s_date = ParseDate($start_date);
			$temp_e_date = ParseDate($end_date);
			
			if (Date_Cmp($s_date,$temp_s_date) == 1 || $first_loop == 0){
				$s_date = $temp_s_date;
				$first_loop = 1;
			}
			if (Date_Cmp($e_date,$temp_e_date) == -1){
				$e_date = $temp_e_date;
			}
			
			my $dec = 0;
			my $date_diff = DateCalc($temp_s_date,$temp_e_date);
			my $num_days = Delta_Format($date_diff,$dec,'%ht');

			print "num of days: ".$date_diff."\n$num_days";
			#following ifs are to check how many days the class actually occurs
			
			#in the case where the class has no days of the week it's assumed 
			#that it happens on every day for the date range determined by 
			#it's end_date - start_date
			if ($cls->{'days'} < 1){
				$num_of_days += 1;
			}
			
			print "  Str Date: ". $start_date."\n";
			print "  End Date: ". $end_date."\n";

		}
			print $s_date. "\n";
			print $e_date. "\n";
	}
	print "***********************************\n";
}

# open $handle, '<', $file_to_convert  or die "Can't open $file_to_convert. Please rename the csv to 'cal_report.csv' or enter the file name when running the script. : $!";
# chomp(my @lines = <$handle>);
# close $handle or die "Can't close $file_to_convert.: $!";

# $header = shift(@lines);
# $header =~ s/(,)(?=(?:[^"]|"[^"]*")*$)/###############################/mg;


# @$headers = split('###############################',$header);

# #print $header;
# #print join(' moo ', @$headers);

# FOO: {
# foreach my $line (@lines){
	# $line =~ s/(,)(?=(?:[^"]|"[^"]*")*$)/###############################/mg;
	# my @line_arr = split(',',$line);
	# print "\n\n\n" . join(' moo ', @line_arr);
	# last FOO;
# }
 # }
my $rtf = RTF::Writer->new_to_file("greetings.rtf");
$rtf->prolog( 'title' => "Greetings, hyoomon", 'fonts' => [ "Courier New", "Georgia"] );
$rtf->number_pages;
$rtf->paragraph(
  \'\f1\fs20\b',  # 20pt, bold, italic
  "Hi there!"
);
$rtf->close;