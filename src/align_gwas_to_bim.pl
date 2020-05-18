#!/usr/bin/env perl

use strict;
use warnings;
use IO::File;
use Getopt::Long;
use JSON::PP;

my ($gwas, $bfile, $out_prefix);

GetOptions(
    "gwas=s"  => \$gwas,
    "bfile=s" => \$bfile,
    "out=s"   => \$out_prefix
) || die "ERROR: Undefined command line argument! Exiting"."\n";

my $usage  = "\n\nUSAGE: perl $0"." ";
$usage    .= "--gwas <trait.assoc>"." ";
$usage    .= "--bfile <plink>"."\n\n";

if(!$gwas || !$bfile || !$out_prefix)
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
my $colMap     = {};
my $lineNumber = 0;
my $snpColumn  = -1;
my $chrColumn  = -1;
my $bpColumn   = -1;
my $a1Column   = -1;
my $a2Column   = -1;
my $statColumn = -1;
my $pvalColumn = -1;
my $stat       = "";

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

my $fh   = IO::File->new("$gwas") || die "ERROR: Cannot open file: ${gwas}!!";
my $out  = IO::File->new("> ${out_prefix}.assoc") || die "ERROR: Cannot create output file: ${out_prefix}.assoc!!";

while(my $line = $fh->getline)
{
    chomp($line);
    $lineNumber++;
    my @lineContents = split(/\s+/, $line);

    if($lineNumber == 1)
    {
        for my $index(0..$#lineContents)
        {
            if ($lineContents[$index]    =~ /snp/i)  { $snpColumn  = $index; }
            elsif ($lineContents[$index] =~ /chr/i)  { $chrColumn  = $index; }
            elsif ($lineContents[$index] =~ /pos/i)  { $bpColumn   = $index; }
            elsif ($lineContents[$index] =~ /A1/i)   { $a1Column   = $index; }
            elsif ($lineContents[$index] =~ /A2/i)   { $a2Column   = $index; }
            elsif ($lineContents[$index] =~ /or/i)   { $statColumn = $index; $stat = "or";}
            elsif ($lineContents[$index] =~ /b/i)    { $statColumn = $index; $stat = "beta";}
            elsif ($lineContents[$index] =~ /P/i)    { $pvalColumn = $index; }
            else { print "INFO: Skipping non-mandatory column: $lineContents[$index]"."\n"; }
        }

        check_sanity("snp", $snpColumn);
        check_sanity("chr", $chrColumn);
        check_sanity("bp", $bpColumn);
        check_sanity("A1", $a1Column);
        check_sanity("A2", $a2Column);
        check_sanity("beta/or", $statColumn);
        check_sanity("P", $pvalColumn);

        my $json = JSON::PP->new->utf8;
        $json    = $json->pretty([1]);
        my $cols = IO::File->new("> ${out_prefix}.json") || die "ERROR: Cannot create output file: ${out_prefix}.json!!";

        $colMap->{"snp"}     = $lineContents[$snpColumn];
        $colMap->{"chr"}     = $lineContents[$chrColumn];
        $colMap->{"bp"}      = $lineContents[$bpColumn];
        $colMap->{"A1"}      = $lineContents[$a1Column];
        $colMap->{"A2"}      = $lineContents[$a2Column];
        $colMap->{"stat"}    = $stat;
        $colMap->{"P"}       = $lineContents[$pvalColumn];

        print $cols $json->encode($colMap);
        $cols->close;

        print $out $lineContents[$snpColumn]." ";
        print $out $lineContents[$chrColumn]." ";
        print $out $lineContents[$bpColumn]." ";
        print $out $lineContents[$a1Column]." ";
        print $out $lineContents[$a2Column]." ";
        print $out $stat." ";
        print $out $lineContents[$pvalColumn]."\n";
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
        else { next;}

        print $out $snp_id_bim." ";
        print $out $chr." ";
        print $out $bp." ";
        print $out $a1." ";
        print $out $a2." ";
        print $out $stat." ";
        print $out $p."\n";
    }
}

$fh->close;
$out->close;
