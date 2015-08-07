#!/usr/bin/perl 

use DBI;

my $db = "maia";
my $host = "localhost";
my $user = "";
my $password = "";
my $localfile = '/etc/spamassassin/local.cf';
my $query = "SELECT maia_users.user_name, sublist.subject, sublist.wb FROM sublist LEFT JOIN maia_users ON sublist.rid = maia_users.id;";

#Open SpamAssassin local.cf
open(my $lcf, '>>', $localfile) or die "Could not open file '$localfile' $!";

#Connect to maia database
$dbh = DBI->connect("dbi:mysql:$db:$host", $user, $password) or die "Can't connect to Database $db on $host, using $user and $password\n";

#Prepare and execute query now, or die if the query fails
my $sql_query = $dbh->prepare($query) or die "Can't prepare $query: $dbh->errstr\n";
$sql_query->execute or die "Can't execute: $query->errstr";

#Loop over query results, for each line, add it the local.cf if it isn't already there
while (my @results = $sql_query->fetchrow_array){
        $recipient = $results[0];
        $subject = $results[1];
        $wb = $results[2];

        $subject_fmted = $subject;
        $recipient_fmted = $recipient;

        $subject_fmted =~ s/\s+//g;
        $recipient_fmted =~ s/\@//g;
        $recipient_fmted =~ s/-//g;
        $recipient_fmted =~ s/\.//g;

        #Grep localfile for the subject/recipient we're looking for
        $exit = system("grep -q -i \"$subject\" $localfile | grep -q -i \"$recipient\"");

        #If subject is on the whitelist/blacklist and not in the file, add it 
        if($wb eq "b" && $? ne 0){
                say $lcf " ";
                say $lcf "header __BLACKLIST_TEST_1_$recipient_fmted\_$subject_fmted Subject =~ '$subject'";
                say $lcf "header __BLACKLIST_TEST_2_$recipient_fmted\_$subject_fmted To =~ '$recipient'";
                say $lcf "meta BLACKLIST_TEST_RESULT_$recipient_fmted\_$subject_fmted ( __BLACKLIST_TEST_1_$recipient_fmted\_$subject_fmted && __BLACKLIST_TEST_2_$recipient_fmted\_$subject_fmted)";
                say $lcf "score BLACKLIST_TEST_RESULT_$recipient_fmted\_$subject_fmted 63.5";
                say $lcf " ";

        }elsif($wb eq "w" && $? ne 0){
                say $lcf " ";
                say $lcf "header __WHITELIST_TEST_1_$recipient_fmted\_$subject_fmted Subject =~ '$subject'";
                say $lcf "header __WHITELIST_TEST_2_$recipient_fmted\_$subject_fmted To =~ '$recipient'";
                say $lcf "meta WHITELIST_TEST_RESULT_$recipient_fmted\_$subject_fmted ( __WHITELIST_TEST_1_$recipient_fmted\_$subject_fmted && __WHITELIST_TEST_2_$recipient_fmted\_$subject_fmted)";
                say $lcf "score WHITELIST_TEST_RESULT_$recipient_fmted\_$subject_fmted -63.5";
                say $lcf " ";
        }
}

#Close file 
close $fh;
