#!/usr/bin/perl

use Writer;
use strict;
use warnings;
use FindBin;
print "hi NAME\n";

my $rtf = RTF::Writer->new_to_file("greetings.rtf");
$rtf->prolog( 'title' => "Greetings, hyoomon", 'fonts' => [ "Courier New", "Georgia"] );
$rtf->number_pages;
$rtf->paragraph(
  \'\f1\fs20\b',  # 20pt, bold, italic
  "Hi there!"
);
$rtf->close;