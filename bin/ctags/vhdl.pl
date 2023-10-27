#!/usr/bin/env perl

# Script to generate Exuberant-ctags/Universal-ctags compatible tag file for VHDL

my $DEBUG = 0;
my $kind="";
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

sub cleanup {
    # cleanup argument string by keeping only the first non-blank field
    my $value = shift;
    $value=~ m/^\s*(\S+)/;
    return $1
}

@ARGV = grep {! /^-/} @ARGV;

my $curline = <>;
my $running = 1;
while($running){
    $_ = $curline;
    # skip comments
    $_ =~ s/\s*--.*//g;
    chomp;
    $file=$ARGV;
    $address=$_;
    $line=$.;
    if ($DEBUG) { print ";;;l:$line\t{$scope}\tkind:$kind\t'$_'\n";}
    if (/^\s*<s>/) {
        $_.=<> until (/<\/s>/ or eof);

    } elsif (/^\s*entity\s+($idregex)\s+is\b(.*)$/i) { $name=cleanup($1); $kind='e'; $sig="";
        # entity start
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line$sig\n";
        $curscope=$name; pushscope(\$scope,$curscope);
        $kscope=$kind2scope{$kind}; 
        #remember rest of line
        $curline = $2;
        if ($curline) {next;}
    } elsif (/^\s*generic\s*\((.*$)/i) { $kind='g';
        #remember rest of line
        $curline = $1; next;
    } elsif ($kscope eq 'entity' and $kind eq 'g' and /^\s*($idregex)\s*:[^)]+\)?;?(.*)$/i) { $name=cleanup($1); $sig="";
        #generics part, capture variable name
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::generics$sig\n";
        $curline = $2; next;

    } elsif ($kscope eq 'entity' and $kind eq 'g' and /^\s*\)\s*;\s*(.*)$/i) {
        #generics part that starts with ');' == end of generics
        $curline = $1; next;
    }elsif (/^\s*port\s*\((.*)$/i) { $kind='p';
        #remember rest of line
        $curline = $1;next;
    } elsif ($kscope eq 'entity' and $kind eq 'p' and /^\s*($idregex)\s*:\s*(inout|out|in)(.*)/i) { $name=cleanup($1);$sig="\tsignature: (".lc($2).")";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::ports$sig\n";
        $curline = $3; next;

    } elsif (
            /^\s*end\s+(entity\s+)?\Q$curscope/i
            or
            /^\s*end\s+entity\b/i
      ) { 
          # end entity;
          # end my_entity_name;
          popscope(\$scope);
    } elsif (/^\s*architecture\s+($idregex)\s+of\s+($idregex)\s+is/i) { $name=cleanup($1); $kind='a';$sig="";
        $curscope=$2; $kscope=$kind2scope{'e'}; pushscope(\$scope,$curscope);
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope$sig\n";
        $curscope=$name; pushscope(\$scope,$curscope);
        $kscope=$kind2scope{$kind}; 
        $scope_body=0;

    } elsif (/^\s*type\s*($idregex)\s*is/i) { $name=cleanup($1); $kind='t'; $sig="";
        my $fullscope="";
        if ($scope ne "") {$fullscope = "\t$kscope:$scope\::types";}
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line$fullscope$sig\n";

    } elsif (/^\s*signal\s*($idregex)\s*:/i) { $name=cleanup($1); $kind='s'; $sig="";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::signals$sig\n";

    } elsif (/^\s*component\s*($idregex)/i) { $name=cleanup($1); $kind='c'; $sig="";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::components$sig\n";

    } elsif ($kscope eq 'architecture' and /^\s*begin\b/i) { $scope_body=1;

    } elsif ($kscope eq 'architecture' and $scope_body==1 and /^\s*(?:($idregex)\s*:\s*(?:postponed\s*)?)?process\s*(\([^)]*\))?/i) { $name=cleanup($1)?cleanup($1):"line$."; $kind='r';$sig="\tsignature: $2";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::processes$sig\n";

    } elsif ($kscope eq 'architecture' and $scope_body==1 and /^\s*($idregex\s*:\s*)?(for|while|next|if|case|null|wait|return|exit|block|assert|report)\b/i) {
    
    } elsif ($kscope eq 'architecture' and $scope_body==1 and /^\s*($idregex)\s*:\s*($idregex)/i) { $name=cleanup($1); $kind='i';$sig=" ($2)";
        print "$name\t$file\t/^$address/;\"\tkind:$kind\tfile:\tline:$line\t$kscope:$scope\::instances\tsignature:$sig\n";

    } elsif (
            /^\s*end\s+(architecture\s+)?\Q$curscope/i 
            or
            /^\s*end\s+architecture\b/i) {
                #pop architecture scope
                popscope(\$scope); $scope_body=0;
                #pop entity scope
                popscope(\$scope);
    }
    else {
        # not recognized
        if($DEBUG) {
            print ";;;???\n";
        }
    }


    $curline = <>;
    if($curline eq "") { $running=0; break; }
}
