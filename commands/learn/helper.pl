#!/usr/bin/perl
use strict;
use warnings;
use File::Temp qw/tempfile/;

our $learn_dir = 'dat/learndb/';

sub cleanse_term
{
  my $term = lc(shift);

  $term =~ y/ /_/;
  $term =~ s/^_+//;
  $term =~ s/_+$//;

  $term =~ y/a-z0-9_!//cd;
  return $term;
}

sub num_entries
{
  my $term = cleanse_term(shift);

  opendir(my $dir, "$learn_dir$term") or 0;
  my @files = grep {$_ ne "." and $_ ne ".." and $_ ne "contrib"}
              readdir $dir;
  return scalar @files;
}

sub read_entry
{
  my $term = cleanse_term(shift);
  my $entry_num = shift;
  my $just_the_entry = shift || 0;

  my $file = "$learn_dir$term/$entry_num";
  return '' if not -r $file;
  my $contents = do {local @ARGV = $file; <>};
  return $contents if $just_the_entry;

  $term =~ y/_/ /;

  return sprintf '%s[%d/%d]: %s', $term, $entry_num, num_entries($term), $contents;
}

sub print_to_entry
{
  my $term = cleanse_term(shift);
  my $entry_num = shift;
  my $text = shift;

  my $file = "$learn_dir$term/$entry_num";
  open(my $handle, ">", $file) or die "Unable to open $file for writing: $!";
  print {$handle} $text;
}

sub entries_for
{
  my $term = cleanse_term(shift);
  my @entries;
  my $num = 0;
  my $entries = num_entries($term);

  foreach my $num (1..$entries)
  {
    $entries[$num] = read_entry($term, $num);
  }

  return \@entries;
}

sub add_entry
{
  my $term = cleanse_term(shift);
  my $text = shift;
  my $contrib = shift;
  my $largest = 0;

  if (not -e "$learn_dir$term")
  {
    mkdir("$learn_dir$term");
    $largest = 0;
  }
  else
  {
    opendir(my $dir, "$learn_dir$term") or return undef;
    foreach my $file (readdir $dir)
    {
      next if $file eq "." or $file eq "..";
      next if $file eq "contrib";
      $largest = $file if $file > $largest;
    }
  }


  ## Rachel is a terrible person.
  #if ($term == "bad_ideas")
  #{
  #  if ($largest == 665)
  #  {
  #    print_to_entry($term,$largest+1,'orb of hellchokos');
  #    return read_entry($term, $largest+1);
  #  }
  #}



  print_to_entry($term, $largest+1, $text);

  return read_entry($term, $largest+1);
}

sub del_entry
{
  my $term = cleanse_term(shift);
  my $entry_num = shift;
  my $moves = 0;

  my @files = (1..num_entries($term));

  #if ($term == "bad_ideas")
  #{
  #  return read_entry('raxvulpine', 2);
  #}

  return -1 if $entry_num > $files[-1];

  if ($entry_num == $files[-1])
  {
    if ($entry_num == 1)
    {
      system("rm -r '$learn_dir$term/'");
    }
    else
    {
      system("rm '$learn_dir$term/$entry_num'");
    }
    return 0;
  }

  foreach my $file (@files)
  {
    if ($file > $entry_num)
    {
      my $src = "$learn_dir$term/$file";
      my $dest = "$learn_dir$term/" . ($file-1);
      system("mv '$src' '$dest'");
      $moves++;
    }
  }

  return $moves;
}

sub replace_entry
{
  my $term = cleanse_term(shift);
  my $entry_num = shift;
  my $new_text = shift;

  opendir(my $dir, "$learn_dir$term") or return undef;
  foreach my $file (readdir $dir)
  {
    next if $file eq "." or $file eq "..";
    next if $file eq "contrib";
    if ($file == $entry_num)
    {
      print_to_entry($term, $entry_num, $new_text);
      return 1;
    }
  }

  return 0;
}

sub swap_entries
{
  my $term1 = cleanse_term(shift);
  my $entry_num1 = shift;
  my $term2 = cleanse_term(shift);
  my $entry_num2 = shift;

  my $file1 = "$learn_dir$term1/$entry_num1";
  my $file2 = "$learn_dir$term2/$entry_num2";
  my ($fh, $tempfile) = tempfile;
  close $fh;

  system("cp '$file1' '$tempfile'") and return;
  system("cp '$file2' '$file1'") and return;
  system("cp '$tempfile' '$file2'") and return;
  system("rm '$tempfile'");

  return 1;
}
