#!/usr/bin/env perl

use strict;
use warnings;
no warnings qw( experimental::smartmatch );
use feature qw(switch);
use IO::File;
use Getopt::Long;

my ($gwas, $bfile);

GetOptions(
    "gwas=s"  => \$gwas,
    "bfile=s" => \$bfile
) || die "ERROR: Undefined command line argument! Exiting"."\n";

my $usage  = "\n\nUSAGE: perl $0"." ";
$usage    .= "--gwas <trait.assoc>"." ";
$usage    .= "--bfile <plink>"."\n\n";

if(!$gwas || !$bfile)
{
    print $usage;
    exit;
}

sub check_sanity
{
    my ($colName, $colNum) = @_;

    if($colNum == -1)
    {
        print "ERROR: Mandatory column: $colName not found in header! Exiting"."\n";
        exit;
    }
    else
    {
        return;
    }
}

my $snps       = {};
my $lineNumber = 0;
my $snpColumn  = -1;
my $chrColumn  = -1;
my $bpColumn   = -1;
my $a1Column   = -1;
my $a2Column   = -1;
my $statColumn = -1;
my $pvalColumn = -1;

my $bim = IO::File->new("${bfile}.bim") || die "ERROR: Cannot open BIM file: ${bfile}.bim!!";

while(my $line = $bim->getline)
{
    chomp($line);
    my @bimContents = split(/\s+/, $line);
    my $chromosome  = $bimContents[0];
    my $snp_id      = $bimContents[1];
    my $position    = $bimContents[3];
    my $allele1     = $bimContents[4];
    my $allele2     = $bimContents[5];
    my $key         = $chromosome."_";
    $key           .= $position."_";
    $key           .= $allele1."_";
    $key           .= $allele2;
    $snps->{$key}   = $snp_id;
}

my $fh = IO::File->new("$gwas") || die "ERROR: Cannot open file: ${gwas}!!";

while(my $line = $fh->getline)
{
    chomp($line);
    $lineNumber++;
    my @lineContents = split(/\s+/, $line);

    if($lineNumber == 1)
    {
        for my $index(0..$#lineContents)
        {
            given($lineContents[$index])
            {
                when ("snp")  { $snpColumn = $index;  }
                when ("chr")  { $chrColumn = $index;  }
                when ("bp")   { $bpColumn  = $index;  }
                when ("A1")   { $a1Column  = $index;  }
                when ("A2")   { $a2Column  = $index;  }
                when ("OR")   { $statColumn = $index; }
                when ("Beta") { $statColumn = $index; }
                when ("P")    { $pvalColumn = $index; }
                default { print "INFO: Skipping column: $lineContents[$index]"."\n"; }
            }
        }

        check_sanity("snp", $snpColumn);
        check_sanity("chr", $chrColumn);
        check_sanity("bp", $bpColumn);
        check_sanity("A1", $a1Column);
        check_sanity("A2", $a2Column);
        check_sanity("OR/Beta", $statColumn);
        check_sanity("P", $pvalColumn);

        print "snp"." ";
        print "chr"." ";
        print "bp"." ";
        print "A1"." ";
        print "A2"." ";
        print "stat"." ";
        print "P"."\n";
    }
    else
    {
        my $snp_id     = $lineContents[$snpColumn];
        my $chr        = $lineContents[$chrColumn];
        my $bp         = $lineContents[$bpColumn];
        my $a1         = $lineContents[$a1Column];
        my $a2         = $lineContents[$a2Column];
        my $stat       = $lineContents[$statColumn];
        my $p          = $lineContents[$pvalColumn];
        my $key1       = $chr."_";
        $key1         .= $bp."_";
        $key1         .= $a1."_";
        $key1         .= $a2;
        my $key2       = $chr."_";
        $key2         .= $bp."_";
        $key2         .= $a2."_";
        $key2         .= $a1;
        my $snp_id_bim = "";

        if(exists $snps->{$key1})    { $snp_id_bim = $snps->{$key1}; }
        elsif(exists $snps->{$key2}) { $snp_id_bim = $snps->{$key2}; }
        else { print "INFO: Skipping $key1 NOT IN TARGET"; next;}

        print $snp_id_bim." ";
        print $chr." ";
        print $bp." ";
        print $a1." ";
        print $a2." ";
        print $stat." ";
        print $p."\n";
    }
}

$fh->close;
