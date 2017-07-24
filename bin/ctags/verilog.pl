#!/usr/bin/env perl

# Script to generate Exuberant-ctags/Universal-ctags compatible tag file for VHDL

my $kind="";
my $subkind="";
my $name="";
my $file="";
my $address="";
my $line="";
my $scope="";
my $curscope="";
my $kscope="";
my $scope_body=0;
my $idregex=qr((?:\w+(?:<[if]>(?:[^<]|<[^if]|<[if][^>])*<\/[if]>)*|(?:<[if]>(?:[^<]|<[^if]|<[if][^>])*<\/[if]>)+)(?:\w+(?:<[if]>(?:[^<]|<[^if]|<[if][^>])*<\/[if]>)*)*);
my %kind2scope=(
        'm' => 'module',
        );

sub pushscope {
    my $scope_ref=shift;
    my $name=shift;
    $$scope_ref.="::" if $$scope_ref ne "";
    $$scope_ref.=$name;
}
sub popscope {
    my $scope_ref=shift;
    $$scope_ref=~s/(::)?[^:]*$//;
}

@ARGV = grep {! /^-/} @ARGV;
while(<>) {
    chomp;
    $file=$ARGV;
    $address=$_;
    $line=$.;
    if (/^\s*<s>/) {
        $_.=<> until /<\/s>/;

    } elsif (/^\s*module\s+($idregex)\s+\(/i) { $name=$1; $kind='m'; $sig="";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line$sig\n";
        $curscope=$name; pushscope(\$scope,$curscope);
        $kscope=$kind2scope{$kind}; 

    } elsif (/^\s*parameter\s+($idregex)\s*/i) { $name=$1; $kind='g'; $sig="";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::generics$sig\n";

    } elsif (/^\s*(in|out|inout)(put)?\b/i) { $kind='p'; $subkind=lc($1);
        $_.=<> until /;/;
        $_=~s/\/\*.*?\*\///sg;$_=~s/\/\/.*//mg;
        $_=~s/^\s*(in|out|inout)(put)?\s*\[\s*$idregex\s*:\s*$idregex\s*\]\s*//i;
        $_=~s/\s*;.*//;
        for my $port (split(/\s*,\s*/s,$_)) {
            next if $port !~ /($idregex)/;
            $name=$port;$sig="\tsignature: ($subkind)";
            print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::ports$sig\n";
        }

    } elsif (/^\s*(wire|reg)\b/i) { $kind='s'; $subkind=lc($1);
        $_.=<> until /;/;
        $_=~s/\/\*.*?\*\///sg;$_=~s/\/\/.*//mg;
        $_=~s/^\s*(wire|reg)\s*\[\s*$idregex\s*:\s*$idregex\s*\]\s*//i;
        $_=~s/\s*;.*//;
        for my $signal (split(/\s*,\s*/s,$_)) {
            next if $signal eq "";
            $signal=~/($idregex)/;
            $name=$signal;$sig="\tsignature: ($subkind)";
            print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::signals$sig\n";
        }

    } elsif (/^\s*initial\b/i) {
        $_.=<> until /begin|;/;
        if(/^\s*initial\s*(?:\s*begin\s*:\s*($idregex))?/i) { $name=$1?$1:"line$."; $kind='r';$sig="\tsignature: initial";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::processes$sig\n";
        }

    } elsif (/^\s*always\b/i) {
        $_.=<> until /begin|;/;
        if(/^\s*always\s*(|_comb|_latch|_ff|@\s*\([^)]*\))(?:\s*begin\s*:\s*($idregex))?/i) { $name=$2?$2:"line$."; $kind='r';$sig="\tsignature: always$1";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::processes$sig\n";
        }

    } elsif (/^(\s*$idregex\s*:\s*)?(for|while|repeat|if|case|null|disable|assign|deassign)\b/i) {
    
    } elsif (/^\s*($idregex)\s+($idregex)/i) { $name=$2; $kind='i';$sig=" ($1)";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::instances$sig\n";

    } elsif (/^\s*endmodule\b/i) { popscope(\$scope);


    }
}
