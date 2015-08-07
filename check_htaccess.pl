#!/usr/bin/perl

use Getopt::Std;
getopts('h:');

#Workaround for links not working correctly as NRPE user
$output = `export HOME=/tmp; links $opt_h | grep Auth`;
$auth = "Authorization Required";

if(index($output, $auth) != -1){
        print "OK: htaccess active for $opt_h";
        exit (0);
}else{
        print "CRITICAL: htaccess not active for $opt_h";
        exit (2);
}
