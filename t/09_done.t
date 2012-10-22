use strict;
use warnings;

use Config;

BEGIN {
    if (! $Config{'useithreads'}) {
        print("1..0 # SKIP Perl not compiled with 'useithreads'\n");
        exit(0);
    }
}

use threads;
use Thread::Queue;

use Test::More;

my @items = 1..20;
my $num_threads = 3;
plan tests => @items + $num_threads;

my $q = Thread::Queue->new();

my @threads;
for my $i (1..$num_threads) {
    push @threads, threads->create( sub {
        # Thread will loop until no more work is coming
        while (defined( my $item = $q->dequeue )) {
            pass("'$item' read from queue");
            select(undef, undef, undef, rand(1));
        }
        pass("Thread $i exiting");
    });
}

# Send work to the thread
$q->enqueue(@items);

# Signal no more work is coming
$q->done;
note "Done sent";

# Join up with the thread when it finishes
$_->join() for @threads;
