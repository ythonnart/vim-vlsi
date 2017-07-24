#!/usr/bin/env perl

# Script to generate Exuberant-ctags/Universal-ctags compatible tag file for VHDL

my $kind="";
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
        'e' => 'entity',
        'a' => 'architecture',
        'c' => 'component',
        'k' => 'package',
        'r' => 'process',
        'f' => 'function',
        'P' => 'procedure'
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

    } elsif (/^\s*entity\s+($idregex)\s+is/i) { $name=$1; $kind='e'; $sig="";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line$sig\n";
        $curscope=$name; pushscope(\$scope,$curscope);
        $kscope=$kind2scope{$kind}; 

    } elsif (/^\s*generic\s*\(/i) { $kind='g';
    } elsif ($kscope eq 'entity' and $kind eq 'g' and /^\s*($idregex)\s*:/i) { $name=$1; $sig="";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::generics$sig\n";

    } elsif (/^\s*port\s*\(/i) { $kind='p';
    } elsif ($kscope eq 'entity' and $kind eq 'p' and /^\s*($idregex)\s*:\s*(in|out|inout)/i) { $name=$1;$sig="\tsignature: (".lc($2).")";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::ports$sig\n";

    } elsif (/^\s*end\s+(entity\s+)?\Q$curscope/i) { popscope(\$scope);

    } elsif (/^\s*architecture\s+($idregex)\s+of\s+($idregex)\s+is/i) { $name=$1; $kind='a';$sig="";
        $curscope=$2; $kscope=$kind2scope{'e'}; pushscope(\$scope,$curscope);
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope$sig\n";
        $curscope=$name; pushscope(\$scope,$curscope);
        $kscope=$kind2scope{$kind}; 
        $scope_body=0;

    } elsif (/^\s*type\s*($idregex)\s*is/i) { $name=$1; $kind='t'; $sig="";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::types$sig\n";

    } elsif (/^\s*signal\s*($idregex)\s*:/i) { $name=$1; $kind='s'; $sig="";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::signals$sig\n";

    } elsif (/^\s*component\s*($idregex)/i) { $name=$1; $kind='c'; $sig="";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::components$sig\n";

    } elsif ($kscope eq 'architecture' and /^\s*begin\b/i) { $scope_body=1;

    } elsif ($kscope eq 'architecture' and $scope_body==1 and /^\s*(?:($idregex)\s*:\s*(?:postponed\s*)?)?process\s*(\([^)]*\))?/i) { $name=$1?$1:"line$."; $kind='r';$sig="\tsignature: $2";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::processes$sig\n";

    } elsif ($kscope eq 'architecture' and $scope_body==1 and /^\s*($idregex\s*:\s*)?(for|while|next|if|case|null|wait|return|exit|block|assert|report)\b/i) {
    
    } elsif ($kscope eq 'architecture' and $scope_body==1 and /^\s*($idregex)\s*:\s*($idregex)/i) { $name=$1; $kind='i';$sig=" ($2)";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::instances$sig\n";

    } elsif (/^\s*end\s+(architecture\s+)?\Q$curscope/i) { popscope(\$scope);

    }
}
