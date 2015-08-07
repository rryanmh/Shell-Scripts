#!/usr/bin/perl 
use XML::RSS;
use POSIX qw( strftime );

my $db = "otrs";
my $host = "localhost";
my $user = "";
my $password = "";

my $path = "/opt/otrs/var/httpd/htdocs"
my $otrs = "http://link.to.otrs/"

my $dbh = DBI->connect("dbi:mysql:$db:$host", $user, $password) or die DBI->errstr;

my $getAllStaff = "SELECT id,name FROM queue ORDER BY id";

my $getNewTicketsPerQueue = "SELECT id,tn,title,customer_id,create_time,change_time FROM ticket WHERE queue_id = ? AND ticket.ticket_state_id NOT IN (2,3,9,10) ORDER BY create_time ASC";

my $getAllStaffQuery = $dbh->prepare($getAllStaff) or die "Can't prepare $getAllStaff: $dbh->errstr\n";

$getAllStaffQuery->execute or die "Can't execute $getAllStaff: $getAllStaffQuery->errstr";

while (my @results = $getAllStaffQuery->fetchrow_array){
        $queue_id = $results[0];
        $queue_name = $results[1];

        my $getNewTicketsPerQueueQuery = $dbh->prepare($getNewTicketsPerQueue) or die "Can't prepare $getNewTicketsPerQueue: $dbh->errstr";
        $getNewTicketsPerQueueQuery->bind_param(1, $queue_id);

        $getNewTicketsPerQueueQuery->execute or die "Cannot Execute: $getNewTicketsPerQueueQuery->errstr";
        my $rss = new XML::RSS (version => '2.0');

        $rss->channel(title => "$queue_name", link => "$otrs/index.pl?Action=AgentTicketQueue;QueueID=$queue_id;View=Small", description => "Ticket updates", ttl => "1");

        while (my @tickets = $getNewTicketsPerQueueQuery->fetchrow_array){
                $ticket_id = $tickets[0];
                $ticket_number = $tickets[1];
                $ticket_title = $tickets[2];
                $ticket_customer = $tickets[3];
                $ticket_timestamp = $tickets[4];

                #Format timestamp from MySQL to match timestamp required by RSS 2.0
                $ticket_timestamp =~ /^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/;
                $rssTS = strftime('%a, %d %b %Y %T %Z', $6, $5, $4, $3, $2 - 1, $1 - 1900, -1, -1, 0);



                $link = "$otrs/index.pl?Action=AgentTicketZoom;TicketID=$ticket_id";
                $description = "Created by $ticket_customer on $rssTS";
                $rss->add_item (title=>"$ticket_title", link=>"$link", description=>"$description", pubDate=>$rssTS);

                }

        $rss->save("$path/$queue_name.xml");

}
