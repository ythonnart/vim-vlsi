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
my $rxidpref=qr((?:<[if]>(?:[^<]|<[^if]|<[if][^>])*<\/[if]>)*);
my $rxidsuff=qr((?:<[if]>(?:[^<]|<[^if]|<[if][^>])*<\/[if]>)*(?:\w+(?:<[if]>(?:[^<]|<[^if]|<[if][^>])*<\/[if]>)*)*);
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

    } elsif (/^\s*module\s+($rxidpref(\w+)$rxidsuff)\s+\(/i) { $name=$2; $kind='m'; $sig=($1 eq $2)?"":"\tsignature:: $1";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line$sig\n";
        $curscope=$name; pushscope(\$scope,$curscope);
        $kscope=$kind2scope{$kind}; 

    } elsif (/^\s*parameter\s+($rxidpref(\w+)$rxidsuff)\s*/i) { $name=$2; $kind='g'; $sig=($1 eq $2)?"":"\tsignature:: $1";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::generics$sig\n";

    } elsif (/^\s*(in|out|inout)(put)?\b/i) { $kind='p'; $subkind=lc($1);
        $_.=<> until /;/;
        $_=~s/\/\*.*?\*\///sg;$_=~s/\/\/.*//mg;
        $_=~s/^\s*(in|out|inout)(put)?\s*\[\s*$rxidsuff\s*:\s*$rxidsuff\s*\]\s*//i;
        $_=~s/\s*;.*//;
        for my $port (split(/\s*,\s*/s,$_)) {
            next if $port !~ /($rxidpref(\w+)$rxidsuff)/;
            $name=$port;$sig="\tsignature: ($subkind)".(($1 eq $2)?"":": $1");
            print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::ports$sig\n";
        }

    } elsif (/^\s*(wire|reg)\b/i) { $kind='p'; $subkind=lc($1);
        $_.=<> until /;/;
        $_=~s/\/\*.*?\*\///sg;$_=~s/\/\/.*//mg;
        $_=~s/^\s*(wire|reg)\s*\[\s*$rxidsuff\s*:\s*$rxidsuff\s*\]\s*//i;
        $_=~s/\s*;.*//;
        for my $signal (split(/\s*,\s*/s,$_)) {
            next if $signal eq "";
            $signal=~/($rxidpref(\w+)$rxidsuff)/;
            $name=$signal;$sig="\tsignature: ($subkind)".(($1 eq $2)?"":": $1");
            print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::signals$sig\n";
        }

    } elsif (/^\s*initial\b/i) {
        $_.=<> until /begin|;/;
        if(/^\s*initial\s*(?:\s*begin\s*:\s*($rxidpref(\w+)$rxidsuff))?/i) { $name=$2?$2:"line$."; $kind='r';$sig="\tsignature: initial".(($1 eq $2)?"":": $1");
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::processes$sig\n";
        }

    } elsif (/^\s*always\b/i) {
        $_.=<> until /begin|;/;
        if(/^\s*always\s*
            (_comb
            |_latch
            |_ff
            |@\s*\([^)]*\)
            )
            (?:\s*begin\s*:\s*($rxidpref(\w+)$rxidsuff))?
            /ix) { $name=$3?$3:"line$."; $kind='r';$sig="\tsignature: always$1".(($2 eq $3)?"":": $2");
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::processes$sig\n";
        }

    } elsif (/^(\s*$rxidsuff\s*:\s*)?(for|while|repeat|if|case|null|disable|assign|deassign)\b/i) {
    
    } elsif (/^\s*($rxidpref(\w+)$rxidsuff)\s+($rxidpref(\w+)$rxidsuff)/i) { $name=$4; $kind='i';$sig=" ($1)";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::instances$sig\n";

    } elsif (/^\s*endmodule\b/i) { popscope(\$scope);


    }
}
