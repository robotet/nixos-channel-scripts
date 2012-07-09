#! /var/run/current-system/sw/bin/perl -w -I .

use strict;
use Nix::Manifest;
use ReadCache;
use File::Basename;


# Read the manifests.
my %narFiles;
my %patches;

foreach my $manifest (@ARGV) {
    print STDERR "loading $manifest\n";
    if (readManifest($manifest, \%narFiles, \%patches, 1) < 3) {
#        die "manifest `$manifest' is too old (i.e., for Nix <= 0.7)\n";
    }
}


# Find the live archives.
my %usedFiles;

foreach my $narFile (keys %narFiles) {
    foreach my $file (@{$narFiles{$narFile}}) {
        $file->{url} =~ /\/([^\/]+)$/;
        my $basename = $1;
        die unless defined $basename;
        #print STDERR "GOT $basename\n";
        $usedFiles{$basename} = 1;
        print STDERR "missing archive `$basename'\n"
            unless defined $readcache::archives{$basename};
    }
}

foreach my $patch (keys %patches) {
    foreach my $file (@{$patches{$patch}}) {
        $file->{url} =~ /\/([^\/]+)$/;
        my $basename = $1;
        die unless defined $basename;
        #print STDERR "GOT2 $basename\n";
        $usedFiles{$basename} = 1;
        die "missing archive `$basename'"
            unless defined $readcache::archives{$basename};
    }
}


# Print out the dead archives.
foreach my $archive (keys %readcache::archives) {
    next if $archive eq "." || $archive eq "..";
    if (!defined $usedFiles{$archive}) {
	my $file = $readcache::archives{$archive};
        print "$file\n";
	my $hashFile = dirname($file) . "/.hash." . basename($file);
	print "$hashFile\n" if -e $hashFile;
    }
}