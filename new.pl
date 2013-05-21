use strict;
use warnings;

my $string1 = 'Mon,Tues,###';
my $string2 = 'Mon,Tues,Wed,##';
my $string3 = 'Mon,Tues,Wed,Thurs,#';
my $string4 = 'Mon,Tues,##Thurs,Fri,';
my $string5 = '###Thurs,#Fri,';
my $string6 = 'Mon,Tues,Wed,Thurs,Fri,';
my $string7 = '#Tues,Wed,Thurs,Fri,';
my $string8 = '#Tues,Wed,Thurs,#';
my $string10 = 'Mon,#Wed,#Fri,';
my $string9 = 'Mon#';

foo($string1);

sub foo {
	
	if ($_[0] =~ m/\w+,+#+\w+/){
		$_[0] =~ s/#//g;
		if ($_[0] =~ m/^\w+,\w+,$/){
			$_[0] =~ s/(\w+),(\w+),/$1\&$2,/g;
		}
		print $_[0]."\n"; 
	}
	elsif ($_[0] =~ m/\w+,+#+$|^#+\w+,+/){
		$_[0] =~ s/#//g;
		$_[0] =~ s/^(\w+),(.*),(\w+,)/$1 - $3/g;
		if ($_[0] =~ m/^\w+,\w+,$/){
			$_[0] =~ s/(\w+),(\w+),/$1\&$2,/g;
		}
		print $_[0]."\n"; 
	}
	else{
		$_[0] =~ s/^(\w+),(.*),(\w+,)/$1 - $3/g;
		print $_[0]."\n";
	}
	print "\n\n\n"
}