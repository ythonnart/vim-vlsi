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
my $idregex=qr((?:\w+(?:<[if]>(?:[^<]|<[^\/])*<\/[if]>)*|(?:<[if]>(?:[^<]|<[^\/])*<\/[if]>)+)(?:\w+(?:<[if]>(?:[^<]|<[^/])*<\/[if]>)*)*);
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

    } elsif (/^\s*module\s+($idregex)\s+#?\(/i) { $name=$1; $kind='m'; $sig="";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line$sig\n";
        $curscope=$name; pushscope(\$scope,$curscope);
        $kscope=$kind2scope{$kind}; 

    } elsif (/^\s*parameter\s+($idregex)\s*/i) { $name=$1; $kind='g'; $sig="";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::generics$sig\n";

    } elsif (/^\s*(in|out|inout)(put)?\b/i) { $kind='p'; $subkind=lc($1);
        # eat everything until , (end of port)
        $_.=<> until /,|[)]/;
        # eat comments
        $_=~s/\/\*.*?\*\///sg; $_=~s/\/\/.*//mg;
        # remove port def
        $_=~s/\s*(in|out|inout)(put)?\s*(logic)?\s*//gi;
        # remove ranges
        $_=~s/\[[^\]]+\]\s*//gi;
        # remove final )
        $_=~s/\s*[)]\s*//gi;

        chomp($_);
        #endmod
        $_=~s/\s*;.*//;
        for my $port (split(/\s*,\s*/s,$_)) {
            next if $port !~ /($idregex)/;
            $name=$port;$sig="\tsignature: ($subkind)";
            print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::ports$sig\n";
        }
    } elsif (/^\s*(\w+\.\w+)\b(.*)/i) {$kind='p'; $subkind=$1; $_=$2;
        # interface signals
        # eat everything until , (end of port)
        $_.=<> until /,|[)]/;
        # eat comments
        $_=~s/\/\*.*?\*\///sg; $_=~s/\/\/.*//mg;
        # remove ranges
        $_=~s/\[[^\]]+\]\s*//gi;
        # remove final )
        $_=~s/\s*[)]\s*//gi;
        # remove everything after ;
        $_=~s/\s*;.*//;
        chomp($_);

        for my $port (split(/\s*,\s*/s,$_)) {
            next if $port !~ /($idregex)/;
            $port=~ s/^\s+|\s+$//g; # trim whitespaces at begining and end
            $name=$port;$sig="\tsignature: ($subkind)";
            print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::ports$sig\n";
        }


    } elsif (/^\s*(wire|reg|logic)\b/i) { $kind='s'; $subkind=lc($1);
        $_.=<> until /;/;
        $_=~s/\/\*.*?\*\///sg;$_=~s/\/\/.*//mg;
        #$_=~s/^\s*(wire|reg|logic)\s*\[\s*$idregex\s*:\s*$idregex\s*\]\s*//i;
        $_=~s/\s*(wire|reg|logic)\s*//i;
        $_=~s/\[[^\]]+\]\s*//i;
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

    } elsif (/^\s*($idregex\s*:\s*)?(for|while|repeat|if|case|null|disable|assign|deassign)\b/i) {
        # skip tag: assign ...
    } elsif (/^\s*($idregex)\s+($idregex)/i) { $name=$2; $kind='i';$sig=" ($1)";
        # simple instances 'module module_instance_name'
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::instances$sig\n";

    } elsif(/^\s*($idregex)\s+#\((.*)/i) { $kind='i';$sig=" ($1)"; $_=$2;
        # module with parameters instanciation
        # eat everything until ; (end of instance)
        $_.=<> until /;/;
        # eat comments
        $_=~s/\/\*.*?\*\///sg; $_=~s/\/\/.*//mg;
        $_ =~ m/[)]\s*($idregex)\s*/si;
        $name=$1;
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::instances$sig\n";

    }elsif (/^\s*endmodule\b/i) { popscope(\$scope);


    }
    elsif(/^\s*`include\s*["<]\s*(\S+?)\s*[">]/i){$kind='h'; $name=$1;
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\n";
    }
    elsif(/^\s*`define\s+(\w+)\s*(\w+)?/i){$kind='d'; $name=$1; $sig="";
        if ($2 != "") {$sig = "\t ($2)";}
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line$sig\n";
    }
}
