#!/usr/bin/perl

use Writer;
use strict;
use warnings;
use FindBin;
use CSV;

my $file_to_convert; 
my $handle;
my $header;
my $headers;

if (exists($ARGV[0])){
	$file_to_convert = $ARGV[0];
	}	
else{
	$file_to_convert = 'cal_report.csv';
}

open $handle, '<', $file_to_convert  or die "Can't open $file_to_convert. Please rename the csv to 'cal_report.csv' or enter the file name when running the script. : $!";
chomp(my @lines = <$handle>);
close $handle or die "Can't close $file_to_convert.: $!";

$header = shift(@lines);
$header =~ s/(,)(?=(?:[^"]|"[^"]*")*$)/###############################/mg;


@$headers = split('###############################',$header);

#print $header;
#print join(' moo ', @$headers);

FOO: {
foreach my $line (@lines){
	$line =~ s/(,)(?=(?:[^"]|"[^"]*")*$)/###############################/mg;
	my @line_arr = split(',',$line);
	print "\n\n\n" . join(' moo ', @line_arr);
	last FOO;
}
 }
my $rtf = RTF::Writer->new_to_file("greetings.rtf");
$rtf->prolog( 'title' => "Greetings, hyoomon", 'fonts' => [ "Courier New", "Georgia"] );
$rtf->number_pages;
$rtf->paragraph(
  \'\f1\fs20\b',  # 20pt, bold, italic
  "Hi there!"
);
$rtf->close;