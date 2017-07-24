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

    if (/^\s*entity\s+((?:<[^>]*>)?(\w+)(?:\S*))\s+is/i) { $name=$2; $kind='e'; $sig=($1 eq $2)?"":"\tsignature:: $1";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line$sig\n";
        $curscope=$name; pushscope(\$scope,$curscope);
        $kscope=$kind2scope{$kind}; 

    } elsif (/^\s*generic\s*\(/i) { $kind='g';
    } elsif ($kscope eq 'entity' and $kind eq 'g' and /^\s*((?:<[^>]*>)?(\w+)(?:\S*))\s*:/i) { $name=$2; $sig=($1 eq $2)?"":"\tsignature:: $1";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::generics$sig\n";

    } elsif (/^\s*port\s*\(/i) { $kind='p';
    } elsif ($kscope eq 'entity' and $kind eq 'p' and /^\s*((?:<[^>]*>)?(\w+)(?:\S*))\s*:\s*(in|out|inout)/i) { $name=$2;$sig="\tsignature: (".lc($3).")".(($1 eq $2)?"":": $1");
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::ports$sig\n";

    } elsif (/^\s*end\s+(entity\s+)?$curscope/i) { popscope(\$scope);

    } elsif (/^\s*architecture\s+((?:<[^>]*>)?(\w+)(?:\S*))\s+of\s+((?:<[^>]*>)?(\w+)(?:\S*))\s+is/i) { $name=$2; $kind='a';$sig=($1 eq $2)?"":"\tsignature:: $1";
        $curscope=$4; $kscope=$kind2scope{'e'}; pushscope(\$scope,$curscope);
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope$sig\n";
        $curscope=$name; pushscope(\$scope,$curscope);
        $kscope=$kind2scope{$kind}; 
        $scope_body=0;

    } elsif (/^\s*type\s*((?:<[^>]*>)?(\w+)(?:\S*))\s*is/i) { $name=$2; $kind='t'; $sig=($1 eq $2)?"":"\tsignature:: $1";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::types$sig\n";

    } elsif (/^\s*signal\s*((?:<[^>]*>)?(\w+)(?:\S*))\s*:/i) { $name=$2; $kind='s'; $sig=($1 eq $2)?"":"\tsignature:: $1";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::signals$sig\n";

    } elsif (/^\s*component\s*((?:<[^>]*>)?(\w+)(?:\S*))/i) { $name=$2; $kind='c'; $sig=($1 eq $2)?"":"\tsignature:: $1";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::components$sig\n";

    } elsif ($kscope eq 'architecture' and /^\s*begin\b/i) { $scope_body=1;

    } elsif ($kscope eq 'architecture' and $scope_body==1 and /^\s*(?:((?:<[^>]*>)?(\w+)(?:\S*))\s*:\s*(?:postponed\s*)?)?process\s*(\(.*\))?/i) { $name=$2?$2:"line$."; $kind='r';$sig="\tsignature: $3".(($1 eq $2)?"":": $1");
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::processes$sig\n";

    } elsif ($kscope eq 'architecture' and $scope_body==1 and /^\s*(?:((?:<[^>]*>)?(\w+)(?:\S*))\s*:\s*)?(for|while|next|if|case|null|wait|return|exit|block|assert|report)\s*(\(.*\))?/i) {
    
    } elsif ($kscope eq 'architecture' and $scope_body==1 and /^\s*((?:<[^>]*>)?(\w+)(?:\S*))\s*:\s*((?:<[^>]*>)?(\w+)(?:\S*))/i) { $name=$2; $kind='i';$sig=" ($3)".(($1 eq $2)?"":": $1");
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::instances$sig\n";

    } elsif (/^\s*end\s+(architecture\s+)?$curscope/i) { popscope(\$scope);

    }
}
