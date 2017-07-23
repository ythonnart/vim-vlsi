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

    if (/^\s*entity\s+(\w+)\s+is/i) { $name=$1; $kind='e';
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\n";
        $curscope=$name; pushscope(\$scope,$curscope);
        $kscope=$kind2scope{$kind}; 

    } elsif (/^\s*generic\s*\(/i) { $kind='g';
    } elsif ($kscope eq 'entity' and $kind eq 'g' and /^\s*(\w+)\s*:/i) { $name=$1;
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::generics\n";

    } elsif (/^\s*port\s*\(/i) { $kind='p';
    } elsif ($kscope eq 'entity' and $kind eq 'p' and /^\s*(\w+)\s*:\s*(in|out)/i) { $name=$1;$sig=" (".lc($2).")";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::ports\tsignature:$sig\n";

    } elsif (/^\s*end\s+(entity\s+)?$curscope/i) { popscope(\$scope);

    } elsif (/^\s*architecture\s+(\w+)\s+of\s+(\w+)\s+is/i) { $name=$1; $kind='a';
        $curscope=$2; $kscope=$kind2scope{'e'}; pushscope(\$scope,$curscope);
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\n";
        $curscope=$name; pushscope(\$scope,$curscope);
        $kscope=$kind2scope{$kind}; 
        $scope_body=0;

    } elsif (/^\s*type\s*(\w+)\s*is/i) { $name=$1; $kind='t';
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::types\n";

    } elsif (/^\s*signal\s*(\w+)\s*:/i) { $name=$1; $kind='s';
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::signals\n";

    } elsif (/^\s*component\s*(\w+)/i) { $name=$1; $kind='c';
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::components\n";

    } elsif ($kscope eq 'architecture' and /^\s*begin\b/i) { $scope_body=1;

    } elsif ($kscope eq 'architecture' and $scope_body==1 and /^\s*(?:(\w+)\s*:\s*)?process\s*(\(.*\))?/i) { $name=$1?$1:"line$."; $kind='r';$sig=" $2";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::processes\tsignature:$sig\n";

    } elsif ($kscope eq 'architecture' and $scope_body==1 and /^\s*(\w+)\s*:\s*(\w+)/i) { $name=$1; $kind='i';$sig=" ($2)";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::instances\tsignature:$sig\n";

    } elsif (/^\s*end\s+(architecture\s+)?$curscope/i) { popscope(\$scope);

    }
}
