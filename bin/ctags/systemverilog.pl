#!/usr/bin/env perl

# Script to generate Exuberant-ctags/Universal-ctags compatible tag file for VHDL
my $DEBUG = 0;
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
my $datatype=qr(logic|wire|reg|\w+::\w+\S*);
my $scalar=qr(\d*'[bohd][0-9a-fA-F]+|\d+|\d+\.\d*);
my %kind2scope=(
        'm' => 'module',
        'I' => 'interface'
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

sub cleanup {
    # cleanup argument string by keeping only the first non-blank field
    my $value = shift;
    $value=~ m/^\s*(\S+)/;
    return $1
}

@ARGV = grep {! /^-/} @ARGV;
while(<>) {
    chomp;
    # skip comments
    $_ =~ s/\s*\/\/.*//g;
    $file=$ARGV;
    $address=$_;
    $address =~ s/\//\\\//g;
    $line=$.;
    if ($DEBUG) { print "; line:$line scope=$scope\n\t$_\n";}
    if (/^\s*<s>/) {
        $_.=<> until (/<\/s>/ or eof);

    } elsif (/^\s*module\s+($idregex)\s*/i) { $name=cleanup($1); $kind='m'; $sig="";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line$sig\n";
        $curscope=$name; pushscope(\$scope,$curscope);
        $kscope=$kind2scope{$kind}; 
    } elsif (/^\s*interface\s+($idregex)\s*/i) { $name=cleanup($1); $kind='I'; $sig="";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line$sig\n";
        $curscope=$name; pushscope(\$scope,$curscope);
        $kscope=$kind2scope{$kind}; 

    } elsif (/^\s*(localparam|parameter)\s+(?:$datatype\s+)?(?:\[[^\]]+\]\s+)?($idregex)\s*=\s*($scalar)?\s*[;,]?/i) { $name=cleanup($2); $kind='g'; $sig="";
        if ($3 != ""){$sig="\tsignature: ($3)";}
        if ($1 eq "localparam") {$sig = "\taccess:private$sig";}
        else {$sig ="\taccess:public$sig";}
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::generics$sig\n";

    } elsif (/^\s*(in|out|inout)(put)?\b/i) { $kind='p'; $subkind=lc($1);
        # eat everything until , or ; (end of port)
        $_.=<> until (/,|;|[)]/ or eof);
        # eat comments
        $_=~s/\/\*.*?\*\///sg;
        # remove port def
        $_=~s/\s*(in|out|inout)(put)?\s*(logic|wire)?\s*//gi;
        # remove ranges
        $_=~s/\[[^\]]+\]\s*//gi;
        # remove final )
        $_=~s/\s*[)]\s*//gi;

        chomp($_);
        #endmod
        $_=~s/\s*;.*//;
        for my $port (split(/\s*,\s*/s,$_)) {
            next if $port !~ /($idregex)/;
            $name=cleanup($port);$sig="\tsignature: ($subkind)";
            print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::ports$sig\n";
        }
    } elsif (/^\s*(\w+\.\w+)\b(.*)/i) {$kind='p'; $subkind=$1; $_=$2;
        # interface signals
        # eat everything until , (end of port)
        $_.=<> until (/,|;|[)]/ or eof);
        # eat comments
        $_=~s/\/\*.*?\*\///sg;
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
            $name=cleanup($port);$sig="\tsignature: ($subkind)";
            print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::ports$sig\n";
        }
    } elsif (/^\s*($datatype)\b/i) { $kind='s'; $subkind=lc($1);
        $_.=<> until (/;/ or eof);
        $_=~s/\/\*.*?\*\///sg;$_=~s/\/\/.*//mg;
        #$_=~s/^\s*(wire|reg|logic)\s*\[\s*$idregex\s*:\s*$idregex\s*\]\s*//i;
        $_=~s/\s*($datatype)\s*//i;
        $_=~s/\[[^\]]+\]\s*//gi;
        $_=~s/\s*;.*//;
        for my $signal (split(/\s*,\s*/s,$_)) {
            next if $signal eq "";
            $signal=~/($idregex)/;
            $name=cleanup($signal);$sig="\tsignature: ($subkind)";
            print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::signals$sig\n";
        }

    } elsif (/^\s*initial\b/i) {
        $_.=<> until (/begin|;/ or eof);
        if(/^\s*initial\s*(?:\s*begin\s*:\s*($idregex))?/i) { $name=cleanup($1)?cleanup($1):"line$."; $kind='r';$sig="\tsignature: (initial)";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::processes$sig\n";
        }

    } elsif (/^\s*always(_comb|_latch|_ff)?\b/i) {
        $_.=<> until (/begin|;/ or eof);
        if(/^\s*always(_comb|_latch|_ff)?\s+@\(.+\)(?:\s*begin\s*:\s*($idregex))?/i) { $name=cleanup($2)?cleanup($2):"line$."; $kind='r';$sig="\tsignature: (always)$1";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::processes$sig\n";
        }

    }elsif(/^\s*typedef\s+[^;]+?\s(\w+);/i){$kind='t'; $name=cleanup($1); $sig="";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\n";
    }elsif (/^\s*($idregex\s*:\s*)?(for|while|repeat|if|case|null|disable|assign|deassign)\b/i) {
        # skip tag: assign ...
    }elsif(/^\s*modport\s+($idregex)/i){$kind='P'; $name=cleanup($1); $sig="";
        # interface modports
        $_.=<> until (/;/ or eof);
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::modports$sig\n";
    } elsif (/^\s*($idregex)\s+($idregex)/i) { $name=cleanup($2); $kind='i';$sig="\tsignature: ($1)";
        # simple instances 'module module_instance_name'
        # eat everything until ; (end of instance)
        $_.=<> until (/;/ or eof);
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::instances$sig\n";
    } elsif(/^\s*($idregex)\s+#\((.*)/i) { $kind='i';$sig="\tsignature: ($1)"; $_=$2;
        # module with parameters instanciation 'modname u_inst #('
        # eat everything until ; (end of instance)
        $_.=<> until (/;/ or eof);
        # eat comments
        $_=~s/\/\*.*?\*\///sg; $_=~s/\/\/.*//mg;
        $_ =~ m/[)]\s*($idregex)\s*/si;
        $name=cleanup($1);
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::instances$sig\n";

    }elsif(/^\s*`include\s*["<]\s*(\S+?)\s*[">]/i){$kind='h'; $name=cleanup($1);
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\n";
    }elsif(/^\s*`define\s+(\w+)\s*($scalar)?/i){$kind='d'; $name=cleanup($1); $sig="";
        if ($2 != "") {$sig = "\tsignature: ($2)";}
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line$sig\n";
    }elsif (/^\s*(endmodule|endinterface)\b/i) { popscope(\$scope);
    }elsif(/^\s*(\/\/|$)/i){
        # pass comments and empty lines
        # FAIL for single unqualified ports
        #}elsif(/^\s*($idregex)\s*$/i){
        #    # single identifier: catchall for instances
        #    $sig="\tsignature: ($1)";
        #    $_.=<> until (/;/ or eof);
        #    $_=~s/\/\*.*?\*\///sg; $_=~s/\/\/.*//mg;
        #    $_ =~ m/[)]\s*($idregex)\s*/si;
        #    $name=cleanup($1);
        #    $kind='i';
        #    print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::instances$sig\n";
    }else {
        # unseen things
        if($DEBUG) {print ";line:$line\t$_\n";}
    }
}
