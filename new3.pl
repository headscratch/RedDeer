my @woo;
$woo[0] = 5;
$woo[3] = 6;

foreach my $w (@woo){
	if ($w){
	print $w."**\n";
	}
}