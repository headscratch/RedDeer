#!/usr/bin/perl

#Each course has a course number 'Ssbsect Crse Numb'
#Each course could have multiple offerings 
#Each offering has a clas numer 'Ssbsect Crn'


use strict;
use warnings;
use Text::CSV;
use Date::Manip::Date;
use RTF::Writer;

my $file_to_convert; 
my $subj_code = ""; 
my $handle;
my $courses;


if (exists($ARGV[0])){
	$file_to_convert = $ARGV[0];
	}	
else{
	$file_to_convert = 'cal_report.csv';
}

my $csv = Text::CSV->new ({ binary => 1, auto_diag => 1 }) or die "Cannot use CSV: ".Text::CSV->error_diag ();
open my $io, "<", $file_to_convert or die "$file_to_convert $!";
my $header = $csv->getline ($io);
my $rows = [];

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
$csv->eof or $csv->error_diag();
close $io or die "Cannot close csv $!";

 $csv->eol ("\r\n");


#capture the subject code from the command line
if (defined($ARGV[1]) && $ARGV[1]=~ m/\w+/){
	$subj_code = $ARGV[1];
	$subj_code =~ s/(\w*).*/$1/;
	$subj_code = uc($subj_code);
}
else{
	$subj_code = "AllSubjects";
}

#Creates a hash of course numbers containg the general course info
#And a hash of each class for the course
foreach my $row(@$rows){
	my @days ;
	if ( uc($row->{'Ssbsect Subj Code'}) eq $subj_code || $subj_code eq 'AllSubjects'){
		$courses->{$row->{'Ssbsect Crse Numb'}}->{'title'} = $row->{'Section-Course Title'};
		$courses->{$row->{'Ssbsect Crse Numb'}}->{'subject_code'} = $row->{'Ssbsect Subj Code'};
		$courses->{$row->{'Ssbsect Crse Numb'}}->{'desc'} = $row->{'zst_clob_to_string  \'SCBDESC\' '};	
		#this is each start and end date for a class
		$courses->{$row->{'Ssbsect Crse Numb'}}->{'class'}->{$row->{'Ssbsect Crn'}}->{'dates'}->{$row->{'Ssrmeet Start Date'}} = $row->{'Ssrmeet End Date'} ;		
		$courses->{$row->{'Ssbsect Crse Numb'}}->{'class'}->{$row->{'Ssbsect Crn'}}->{'start_time'} = $row->{'Ssrmeet Begin Time'};
		$courses->{$row->{'Ssbsect Crse Numb'}}->{'class'}->{$row->{'Ssbsect Crn'}}->{'end_time'} = $row->{'Ssrmeet End Time'};
		$courses->{$row->{'Ssbsect Crse Numb'}}->{'class'}->{$row->{'Ssbsect Crn'}}->{'cost'} = $row->{'Ssrfees Fees c'};
		$courses->{$row->{'Ssbsect Crse Numb'}}->{'class'}->{$row->{'Ssbsect Crn'}}->{'gst'} = $row->{'Ssrfees GST c'};
		#this is the days of the week the class occurs on
		
		#look for 'SU' for sunday in the listed days
		#if found remove it and replace it with 'N' because it will break the split
		$row->{'Ssrmeet All Days'} =~ s/SU/N/g;
		
		foreach my $day (split('',$row->{'Ssrmeet All Days'})){
				if ($day eq 'M' ){$courses->{$row->{'Ssbsect Crse Numb'}}->{'class'}->{$row->{'Ssbsect Crn'}}->{'days'}[0] = 'Mon,';}
				elsif ($day eq 'T'){$courses->{$row->{'Ssbsect Crse Numb'}}->{'class'}->{$row->{'Ssbsect Crn'}}->{'days'}[1] = 'Tues,';}
				elsif ($day eq 'W'){$courses->{$row->{'Ssbsect Crse Numb'}}->{'class'}->{$row->{'Ssbsect Crn'}}->{'days'}[2] = 'Wed,';}
				elsif ($day eq 'R'){$courses->{$row->{'Ssbsect Crse Numb'}}->{'class'}->{$row->{'Ssbsect Crn'}}->{'days'}[3] = 'Thurs,';}
				elsif ($day eq 'F'){$courses->{$row->{'Ssbsect Crse Numb'}}->{'class'}->{$row->{'Ssbsect Crn'}}->{'days'}[4] = 'Fri,';}
				elsif ($day eq 'S'){$courses->{$row->{'Ssbsect Crse Numb'}}->{'class'}->{$row->{'Ssbsect Crn'}}->{'days'}[5] = 'Sat,';}	
				elsif ($day eq 'N'){$courses->{$row->{'Ssbsect Crse Numb'}}->{'class'}->{$row->{'Ssbsect Crn'}}->{'days'}[6] = 'Sun,';}	
		}
	}
}

#Open up an RTF to fill
my $rtf = RTF::Writer->new_to_file("$subj_code.rtf");
$rtf->prolog( 'title' => "$subj_code", 'fonts' => [ "Arial"] );
$rtf->number_pages;

while ((my $key, my $value) = each (%$courses)){
	my $output = "";
	my $title = "";

	$title =  "$value->{'title'}";
#	print "Course Num: ". $key . " Subject Code: ". $value->{'subject_code'}. "\n";
	$output .= "$value->{'desc'} \n\n";
	my %class_hash = %{$value->{'class'}};
	while ((my $cls_num, my $cls) = each (%class_hash)){
		$output .= "Course  #". $cls_num. "\n";
		my $first_loop = 0;

		my $days_week_count = 0;
		foreach my $d(@{$cls->{days}}){
			if ($d){
				 $days_week_count ++;
			}
		}
#		print "Count of days: $days_week_count \n";
		
		#set up date comparitors
		my $s_date = new Date::Manip::Date; 
		my $e_date = new Date::Manip::Date; 

		
		my $err1 = $s_date->parse('1973-01-01 12:00 AM');
		my $err2 = $e_date->parse('1973-01-01 12:00 AM');
		
		my $num_of_days = 0;
		
		#loop through all the dates for an offering and find the min start date
		#and the max start date
		my %date_hash = %{$cls->{'dates'}};
		while ((my $start_date, my $end_date) = each (%date_hash)){
			
			my $temp_s_date = new Date::Manip::Date; 
			my $temp_e_date = new Date::Manip::Date; 
			
			$temp_s_date->parse($start_date);
			$temp_e_date->parse($end_date);
			
			if ($s_date->cmp($temp_s_date) == 1 || $first_loop == 0){
				$s_date = $temp_s_date;
				$first_loop = 1;
			}
			if ($e_date->cmp($temp_e_date) == -1){
				$e_date = $temp_e_date;
			}
			
			my $dec = 0;
			my $date_diff = $temp_s_date->calc($temp_e_date,'exact');
			my @diff_delta = $date_diff->value();
			my $num_days = int(($diff_delta[4]/24) +0.5);

			#following ifs are to check how many days the class actually occurs
			
			#in the case where the class has no days of the week it's assumed 
			#that it happens on every day for the date range determined by 
			#it's end_date - start_date
			if ($days_week_count < 1){
				$num_of_days += $num_days;
			}
			
			#Class only falls on one day of the week and occurs over a one week period
			elsif ($days_week_count == 1 and $num_days < 7){
				$num_of_days += 1;
			}
			
			elsif ($days_week_count == 1 and $num_days >= 7){
				$num_of_days += 2;
			}
			
			elsif ($days_week_count == 2 and $num_days < 7){
				$num_of_days += 2;
			}
			
			elsif ($days_week_count == 2 and $num_days >= 7){
				$num_of_days += 3;
			}
			
			elsif ($days_week_count > 2){
				$num_of_days += 3;
			}
			# print "  Str Date: ". $start_date."\n";
			# print "  End Date: ". $end_date."\n";
		
		}
			
		my $output_format_s = '%b %e';
		my $output_format_e = '%b %e';
		
		#Check if the start and end date fall in the same month
		if ($s_date->printf('%Y%m') == $e_date->printf('%Y%m')){
			$output_format_e = '%e';
		}
		my $s_d = $s_date->printf($output_format_s);
		my $e_d = $e_date->printf($output_format_e);
		
		#cut off any leading zeros from the day
		$s_d =~ s/0(\d)/$1/;
		$e_d =~ s/^0(\d)/$1/;
		
		#cut off any leading whitespace
		$s_d =~ s/^\s(.*)/$1/;
		$e_d =~ s/^\s(.*)/$1/;
		
		
		if ($num_of_days > 2){
			$output .= $s_d. " - ". $e_d. "\n";
		}
		elsif($num_of_days == 2){
			$output .= $s_d. " & ". $e_d. "\n";
		}
		elsif($num_of_days < 2){
			$output .= $s_d. "\n";
		}
		
		#logic for creating the days of the week string. 
		my $days_string = '';
		foreach my $i  (@{$cls->{'days'}}){
			if ($i){
				$days_string .= $i;
			}
			else{
				$days_string .='#'
			}
		}

		#Check for days of the week that are interrupted in the middle
		#If they are just list all the class days seperated by commas
		#M,R,F
		if ($days_string =~ m/\w+,+#+\w+/){
			$days_string =~ s/#//g;
			#If only two days are listed replace the comma between them with '&'
			if ($days_string =~  m/^\w+,\w+,$/){
				$days_string =~ s/(\w+),(\w+),/$1\ & $2,/g;
			}
			$output .= $days_string." "; 
		}
		
		#Check for un-interrupted consecutive days that the course is offered
		#If there is a string of days replace the middle ones with a dash
		#M-W
		elsif ($days_string =~ m/\w+,+#+$|^#+\w+,+/){
			$days_string =~ s/#//g;
			$days_string =~ s/^(\w+),(.*),(\w+,)/$1 - $3/g;
			#If only two days are listed replace the comma between them with '&'
			if ($days_string =~  m/^\w+,\w+,$/){
				$days_string =~ s/(\w+),(\w+),/$1\ & $2,/g;
			}
			$output .= $days_string." "; 
		}
		#All days of the week are listed
		#Replace all middle days with a dash
		#M-F
		else{
			$days_string =~ s/^(\w+),(.*),(\w+,)/$1 - $3/g;
			#Check if it's just an empty string at this point
			#If only two days are listed replace the comma between them with '&'
			if ($days_string =~  m/^\w+,\w+,$/){
				$days_string =~ s/(\w+),(\w+),/$1\ & $2,/g;
			}
			if($days_string){
				$output .= $days_string." ";
			}
		}
		
		#Code to print out what time the class is offered
		
		my $s_time = new Date::Manip::Date; 
		my $e_time = new Date::Manip::Date;
		my $minute = new Date::Manip::Delta;
		
		$minute->parse('0:0:0:0:0:1:0');
		
		if ($cls->{'start_time'} && $cls->{'end_time'}){
			
#			$s_time->parse($cls->{'start_time'});
#			$e_time->parse($cls->{'end_time'});
			$s_time->parse_format('%H%M',$cls->{'start_time'});
			$e_time->parse_format('%H%M',$cls->{'end_time'});
			
			if ($cls->{'start_time'} =~ m/.*9$/){
				$s_time = $s_time->calc($minute);
			}
			
			if ($cls->{'end_time'} =~ m/.*9$/){
				$e_time = $e_time->calc($minute);
			}
			
			
			my $start_time = $s_time->printf('%i:%M %p');
			my $end_time = $e_time->printf('%i:%M %p');
			
			#cut off any leading zeros
			$start_time =~ s/^0(.*)/$1/;
			$end_time =~ s/^0(.*)/$1/;
			
			#cut off any leading whitespace
			$start_time =~ s/^\s(.*)/$1/;
			$end_time =~ s/^\s(.*)/$1/;
			
			#replace the AM or PM with a.m. p.m.
			$start_time  =~ tr/[A-Z]/[a-z]/;
			$start_time  =~ s/([a-z])/$1\./g;
			$end_time =~ tr/[A-Z]/[a-z]/;
			$end_time =~ s/([a-z])/$1\./g;
			$output .= "$start_time - $end_time\n";

		}
		
		#Code to print out the cost of the class
		if($cls->{'cost'}){
			$output .= "\$".$cls->{'cost'};
		}
		if($cls->{'gst'}){
			$output .= " + GST\n\n";
		}
		
	}
	
	$rtf->paragraph(
	  \'\f0\fs20\b',  # Arial, 10pt 
	  "$title"
	);
	$rtf->paragraph(
	  \'\f0\fs20',  # Arial, 10pt
	  "$output \n\n"
	);
	
}

$rtf->close;

