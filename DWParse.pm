package Text::DWParse;

use POSIX qw(strftime);
use vars qw($VERSION);
$VERSION = "0.01";

use IO::File;
use Carp;
use strict;

#=============================================================================
# the constructor
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    $self->{TEXT}='';
    my $sFile=shift;
    my $sFH=new IO::File();
    unless($sFH->open('<'.$sFile)) {
	croak("Text::DWParse: Failed to open file $sFile !");
    }
    $self->{TEXT} = join('',<$sFH>);
    $sFH->close;
    bless ($self,$class);
    return $self;
} # of new

#=============================================================================

sub Parse_Template {
    my $self=shift;
    my $part;
    # Break template into parts ...
    $self->{PARTS}{'_main'}{'_text'} = $self->{TEXT};
    while ($self->{PARTS}{'_main'}{'_text'} =~ s/<!--\s*TemplateBeginRepeat\s*name=\"(.*?)\"\s*-->(.*?)<!--\s*TemplateEndRepeat\s*-->/<!-- TemplateRepeat name=\"$1\" -->/iso) {
	$self->{PARTS}{$1}[0]{'_text'} = $2;
    }

    # Process template parts - get parts-hashes filled 
    foreach $part (keys %{$self->{PARTS}}) {
        if ($part eq '_main') {
    	    while($self->{PARTS}{$part}{'_text'} =~ /<!--\s*TemplateBeginEditable\s*name=\"(.*?)\"\s*-->(.*?)<!--\s*TemplateEndEditable\s*-->/isog) {
		$self->{PARTS}{$part}{$1}=$2;
	    }
        } else {
    	    while($self->{PARTS}{$part}[0]{'_text'} =~ /<!--\s*TemplateBeginEditable\s*name=\"(.*?)\"\s*-->(.*?)<!--\s*TemplateEndEditable\s*-->/isog) {
		$self->{PARTS}{$part}[0]{$1}=$2;
	    }
	}
    }
    return $self;
} # of Parse_Template

#=============================================================================

sub Fill_Template {
    # Now begin reassemble everything in place back
    my $self = shift;
    my ($part,$keyname,$i);

    # Get values into parts
    foreach $part (keys %{$self->{PARTS}}) {
	if ($part eq '_main') {
	    foreach $keyname (keys %{$self->{PARTS}{$part}}) {
		next if $keyname eq '_text';
		$self->{PARTS}{$part}{'_text'} =~ s/<!--\s*TemplateBeginEditable\s*name=\"$keyname\"\s*-->.*?<!--\s*TemplateEndEditable\s*-->/$self->{PARTS}{$part}{$keyname}/isg;
	    }
	} else {
	    #subscript adressing
	    for ($i=1;$i<=$#{$self->{PARTS}{$part}};$i++) {
		$self->{PARTS}{$part}[$i]{'_text'} = $self->{PARTS}{$part}[0]{'_text'};
		foreach $keyname (keys %{$self->{PARTS}{$part}[$i]}) {
		    next if $keyname eq '_text';
		    $self->{PARTS}{$part}[$i]{'_text'} =~ s/<!--\s*TemplateBeginEditable\s*name=\"$keyname\"\s*-->.*?<!--\s*TemplateEndEditable\s*-->/$self->{PARTS}{$part}[$i]{$keyname}/isg;
		}
	    }
	    # Assemble all repeat-parts back in place !
	    $self->{PARTS}{$part}[0]{'_text'} = '';
	    for ($i=1;$i<=$#{$self->{PARTS}{$part}};$i++) {
		    $self->{PARTS}{$part}[0]{'_text'} .= $self->{PARTS}{$part}[$i]{'_text'};
	    }
	}
    }

    # And now get parts into place in original text
    foreach $part (keys %{$self->{PARTS}}) {
	next if $part eq '_main'; 
	$self->{PARTS}{'_main'}{'_text'} =~ s/<!-- TemplateRepeat name=\"$part\" -->/$self->{PARTS}{$part}[0]{'_text'}/isg;
    }
    
    return $self->{PARTS}{'_main'}{'_text'};
    
} # of Fill_Template

#=============================================================================

sub Add_Value {
    my $self = shift;
    my ($key, $value) = @_;
    $self->{PARTS}{'_main'}{$key} = $value;
    return $self;
} # of Add_Value

#=============================================================================

sub Add_Line {
    my $self = shift;
    my ($region, %valuehash, $valueref, $key, $i);
    $region = shift;
    $valueref = shift;
    %valuehash = %{$valueref};
    $i = $#{$self->{PARTS}{$region}} + 1;
    foreach $key (keys %valuehash) {
	$self->{PARTS}{$region}[$i]{$key} = $valuehash{$key};
    }
    return $self;
} # of Add_Line

#=============================================================================

1;

__END__

=head1 NAME

Text::DWParse - Module for processing Dreamweaver MX templates

=head1 SYNOPSIS

  use Text::DWParse;
  my $Template = new Text::DWParse('/some/where/file.dwt');
  $Template -> Parse_Template;
  
  # Set a value into editable region
  $Template -> Add_Value('region_name',$value);

  # Set values into repeating regions
  $Template -> Add_Line('rep_region_name',{'region_1' => 'value_1',
					   'region_2' => 'value_2',
					    .... });
  $Template -> Add_Line('rep_region_name',ref %value_hash);

  # Fill .DWT with params and print it to STDOUT
  print $Template -> Fill_Template;

=head1 DESCRIPTION

This module is intended to provide a quick and handy method of using
Dreamweaver MX templates in perl scripts.

It processes the initial template, finds editable regions and then allows
for them to be filled with data. If no data for the named region is supplied -
it is left with original data (which was in DWT). If a repeating region
was defined in template, but no Add_Line occured - repeating region is 
deleted from parsed output.

=head1 TODO

 - add more template stuff
 - add some sanity checks 
 - add something - just ask ! ;-)

=head1 AUTHOR

Dmitriy Litovchin, cyber@btg.ru

=head1 COPYRIGHT

Copyright (c) 2003 Dmitriy Litovchin. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=head1 SEE ALSO

HTML::DWT, Text::Template, perl(1)

=cut
