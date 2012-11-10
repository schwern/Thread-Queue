# Test that threads will keep going after done() is called if there's more
# in the queue.

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
use threads::shared;
use Thread::Queue;

use Test::More;

my @items = 1..10000;
my $num_threads = 2000;
plan tests => (@items * 2) + ($num_threads * 2) + 1;

my $q = Thread::Queue->new();

# using this because $seen{$thing}++ is not atomic and a lock might
# invalidate the test.  I think push @seen is atomic.
my @seen : shared;
my @threads;
for my $i (1..$num_threads) {
    push @threads, threads->create( sub {
        # Thread will loop until no more work is coming
        while (defined( my $item = $q->dequeue )) {
            push @seen, $item;
            pass("'$item' read from queue");
            select(undef, undef, undef, rand(1));
        }
        pass("Thread $i exiting");
    });
}

note "First queue";
$q->enqueue(@items);

note "Waiting for queue to empty";
# Wait for the queue to be exhausted and all threads blocked.
sleep 1 while $q->pending;
sleep 1;

note "Second queue";
# Add more items.
$q->enqueue(@items);

# Unblock everybody at once.
note "Done";
$q->done;
note "Done sent";

for my $thread (@threads) {
    $thread->join;
    pass($thread->tid." joined");
}

is_deeply [sort @seen], [sort @items, @items], "all items processed";
