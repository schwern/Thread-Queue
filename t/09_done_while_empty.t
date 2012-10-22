# Test that threads will unblock if done() is called after the queue is
# empty and threads are blocking.

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
plan tests => @items + ($num_threads * 2);

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

$q->enqueue(@items);

# Make sure there's nothing in the queue and threads are blocking.
sleep 1 while $q->pending;
sleep 1;

# Signal no more work is coming to the blocked threads, they
# should unblock.
$q->done;
note "Done sent";

for my $thread (@threads) {
    $thread->join;
    pass($thread->tid." joined");
}
