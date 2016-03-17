use DE_EPAGES::Core::API::Error qw ( ExistsError GetError );
use DE_EPAGES::Core::API::Warning qw ( Warning );
use DE_EPAGES::Core::API::Script qw ( RunScript );
use DE_EPAGES::Object::API::Factory qw ( LoadObjectByGUID );
use DE_EPAGES::Database::API::Connection qw ( RunOnStore );
use DE_EPAGES::WebInterface::API::MessageCenter qw ( SynchronizeCache );
use DateTime::Format::ISO8601;
use List::Util qw ( min max );
use Getopt::Long;

use strict;



sub Main {

    local $| = 1;

    my $Password;
    my $StoreName;
    my $Help;
    my $OrdersFile;
    my $StartDateStr;
    my $EndDateStr;

    GetOptions(
        'help'          => \$Help,
        'passwd=s'      => \$Password,
        'storename=s'   => \$StoreName,
        'ordersfile=s'  => \$OrdersFile,
        'startdate=s'   => \$StartDateStr,
        'enddate=s'     => \$EndDateStr,
    );

    usage() if $Help;

    unless($StoreName) {
        print STDERR "Missing parameter -storename\n\n";
        usage();
    }
    unless($StartDateStr) {
        print STDERR "Missing parameter -startdate\n\n";
        usage();
    }
    unless($EndDateStr) {
        print STDERR "Missing parameter -enddate\n\n";
        usage();
    }

    my $time1 = time;


    my $aOrderGUIDS = [];
    if (open(my $fh, '<:encoding(UTF-8)', $OrdersFile)) {
        while (my $OrderGUID = <$fh>) {
            chomp $OrderGUID;
            push(@$aOrderGUIDS, $OrderGUID);
        }
    } else {
        print STDERR "Could not open file '$OrdersFile' !\n\n";
    }

    RunOnStore(
        Store => $StoreName,
        DBPassword => $Password,
        Sub => sub  {
            for my $OrderGUID (@$aOrderGUIDS) {

                my $StartDate = DateTime::Format::ISO8601->parse_datetime( $StartDateStr );
                my $EndDate = DateTime::Format::ISO8601->parse_datetime( $EndDateStr );

                my $Order = LoadObjectByGUID($OrderGUID);
                my $RandomDateTime = _createRandomDateTimeBetween($StartDate, $EndDate);

                $Order->set({
                    'CreationDate' => $RandomDateTime
                });

                print "Changed CreationDate of order $OrderGUID to $RandomDateTime\n";
            }
        },
    );
    my $time2 = time;
    printf "need %.3f seconds\n", $time2-$time1;

    eval { SynchronizeCache(); };
    Warning( GetError() ) if ExistsError();
}



sub _createDateTime {
    my ($Year, $Month, $Day) = @_;
    my $DateTime = DateTime->new(
        year       => $Year,
        month      => $Month,
        day        => $Day
    );
    return $DateTime;
}



sub _createRandomDateTimeBetween {
    my ($DateTime1, $DateTime2) = @_;

    my $Timestamp1 = $DateTime1->epoch();
    my $Timestamp2 = $DateTime2->epoch();
    my $TimestampStart = min($Timestamp1, $Timestamp2);
    my $TimestampEnd = max($Timestamp1, $Timestamp2);

    my $RandomTimestamp = $TimestampStart + rand() * ($TimestampEnd - $TimestampStart);

    my $RandomDateTime = DateTime->from_epoch(epoch => $RandomTimestamp);
    return $RandomDateTime;
}



sub usage {
    print <<END_USAGE;
Usage:
    perl $0 [options] [flags] attribute=value ...

options:
    -passwd     database user password (optional)
    -storename  name of store (required)
    -ordersfile name of that contains the order GUIDs (required)
    -startdate  starting date for the CreationDate range e.q. 2016-03-14 (required)
    -enddate    ending date for the CreationDate range (required)
flags:
    -help       show the command line options

Example:
    perl $0 -storename Store -ordersfile orderguids -startdate 2010-01-01 -enddate 2016-03-14
END_USAGE
    exit 2;
}



RunScript(
    'Sub' => \&Main
);
