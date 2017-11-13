use strict;
use warnings;
use Test::More;
use Role::Tiny ();
use Scalar::Util qw(weaken isweak);

use lib 't/lib';
use Unrandom;

{
  package Mojo::Collection::ForTesting;
  sub new {
    my $class = shift;
    return bless [@_], ref $class || $class;
  }
}

sub c { Role::Tiny->apply_roles_to_object(Mojo::Collection::ForTesting->new(@_), 'Mojo::Collection::Role::UtilsBy') }

### Tests adapted from List::UtilsBy

## sort_by
is_deeply( c()->sort_by(sub { }), [], 'empty list' );

is_deeply( c("a")->sort_by(sub { $_ }), [ "a" ], 'unit list' );

is_deeply( c("a")->sort_by(sub { my $ret = $_; undef $_; $ret }), [ "a" ], 'localises $_' );

is_deeply( c("a", "b")->sort_by(sub { $_ }), [ "a", "b" ], 'identity function no-op' );
is_deeply( c("b", "a")->sort_by(sub { $_ }), [ "a", "b" ], 'identity function on $_' );

is_deeply( c("b", "a")->sort_by(sub { $_[0] }), [ "a", "b" ], 'identity function on $_[0]' );

# list reverse on a single element is a no-op; scalar reverse will swap the
# characters. This test also ensures the correct context is seen by the function
is_deeply( c("az", "by")->sort_by(sub { reverse $_ }), [ "by", "az" ], 'reverse function' );

is_deeply( c("b", "a")->rev_sort_by(sub { $_ }), [ "b", "a" ], 'reverse sort identity function on $_' );

## nsort_by
is_deeply( c()->nsort_by(sub { }), [], 'empty list' );

is_deeply( c(1)->nsort_by(sub { $_ }), [ 1 ], 'unit list' );

is_deeply( c(10)->nsort_by(sub { my $ret = $_; undef $_; $ret }), [ 10 ], 'localises $_' );

is_deeply( c(20, 25)->nsort_by(sub { $_ }), [ 20, 25 ], 'identity function no-op' );
is_deeply( c(25, 20)->nsort_by(sub { $_ }), [ 20, 25 ], 'identity function on $_' );

is_deeply( c(30, 35)->nsort_by(sub { $_[0] }), [ 30, 35 ], 'identity function on $_[0]' );

is_deeply( c("a", "bbb", "cc")->nsort_by(sub { length $_ }), [ "a", "cc", "bbb" ], 'length function' );

# List context would yield the matches and fail, scalar context would yield
# the count and be correct
is_deeply( c("apple", "hello", "armageddon")->nsort_by(sub { () = m/(a)/g }), [ "hello", "apple", "armageddon" ], 'scalar context' );

is_deeply( c("a", "bbb", "cc")->rev_nsort_by(sub { length $_ }), [ "bbb", "cc", "a" ], 'reverse sort length function' );

## max_by
is_deeply( c()->max_by(sub {}), undef, 'empty list yields empty' );

is_deeply( c(10)->max_by(sub { $_ }), 10, 'unit list yields value' );

is_deeply( c(10, 20)->max_by(sub { $_ }), 20, 'identity function on $_' );
is_deeply( c(10, 20)->max_by(sub { $_[0] }), 20, 'identity function on $_[0]' );

is_deeply( c("a", "ccc", "bb")->max_by(sub { length $_ }), "ccc", 'length function' );

is_deeply( c("a", "ccc", "bb", "ddd")->max_by(sub { length $_ }), "ccc", 'ties yield first' );

## min_by
is_deeply( c()->min_by(sub {}), undef, 'empty list yields empty' );

is_deeply( c(10)->min_by(sub { $_ }), 10, 'unit list yields value' );

is_deeply( c(10, 20)->min_by(sub { $_ }), 10, 'identity function on $_' );
is_deeply( c(10, 20)->min_by(sub { $_[0] }), 10, 'identity function on $_[0]' );

is_deeply( c("a", "ccc", "bb")->min_by(sub { length $_ }), "a", 'length function' );

is_deeply( c("a", "ccc", "bb", "e")->min_by(sub { length $_ }), "a", 'ties yield first' );

## uniq_by
is_deeply( c()->uniq_by(sub { }), [], 'empty list' );

is_deeply( c("a")->uniq_by(sub { $_ }), [ "a" ], 'unit list' );

is_deeply( c("a")->uniq_by(sub { my $ret = $_; undef $_; $ret }), [ "a" ], 'localises $_' );

is_deeply( c("a", "b")->uniq_by(sub { $_ }), [ "a", "b" ], 'identity function no-op' );
is_deeply( c("b", "a")->uniq_by(sub { $_ }), [ "b", "a" ], 'identity function on $_' );

is_deeply( c("b", "a")->uniq_by(sub { $_[0] }), [ "b", "a" ], 'identity function on $_[0]' );

is_deeply( c("a", "b", "cc", "dd", "eee")->uniq_by(sub { length $_ }), [ "a", "cc", "eee" ], 'length function' );

## extract_by
{
  # We'll need a real collection to work on
  my $numbers = c( 1 .. 10 );

  is_deeply( $numbers->extract_by(sub { 0 }), [], 'extract false returns none' );
  is_deeply( $numbers, [ 1 .. 10 ],               'extract false leaves collection unchanged' );

  is_deeply( $numbers->extract_by(sub { $_ % 3 == 0 }), [ 3, 6, 9 ], 'extract div3 returns values' );
  is_deeply( $numbers, [ 1, 2, 4, 5, 7, 8, 10 ],                     'extract div3 removes from array' );

  is_deeply( $numbers->extract_by(sub { $_[0] < 5 }), [ 1, 2, 4 ], 'extract $_[0] < 4 returns values' );
  is_deeply( $numbers, [ 5, 7, 8, 10 ],                            'extract $_[0] < 4 removes from array' );

  is_deeply( $numbers->extract_by(sub { 1 }), [ 5, 7, 8, 10 ], 'extract true returns all' );
  is_deeply( $numbers, [],                                     'extract true leaves nothing' );
}

{
  my $words = c( qw( here are some words ) );

  is( $words->extract_first_by(sub { length == 4 }), "here", 'extract first finds an element' );
  is_deeply( $words, [qw( are some words )], 'extract first leaves other matching elements' );

  is_deeply( $words->extract_first_by(sub { length == 6 }), undef, 'extract first returns undef on no match' );
}

{
  my @refs = map { {} } 1 .. 3;

  my $weakrefs = c( @refs );
  weaken $_ for @$weakrefs;

  is_deeply( $weakrefs->extract_by(sub { !defined $_ }), [], 'extract undef refs returns nothing yet' );
  is( scalar @$weakrefs, 3,                                  'extract undef refs leaves array unchanged' );
  ok( isweak $weakrefs->[0], "extract_by doesn't break weakrefs" );

  undef $refs[0];

  is_deeply( $weakrefs->extract_by(sub { !defined $_ }), [ undef ], 'extract undef refs yields an undef' );
  is( scalar @$weakrefs, 2,                                         'extract undef refs removes from array' );
  ok( isweak $weakrefs->[0], "extract_by still doesn't break weakrefs" );
}

## weighted_shuffle_by
is_deeply( c()->weighted_shuffle_by(sub { }), [], 'empty list' );

is_deeply( c("a")->weighted_shuffle_by(sub { 1 }), [ "a" ], 'unit list' );

my $vals = c("a", "b", "c")->weighted_shuffle_by(sub { 1 });
is_deeply( [ sort @$vals ], [ "a", "b", "c" ], 'set of return values' );

my %got;
unrandomly {
  my $order = join "",
              @{ c( qw( a b c ) )->weighted_shuffle_by(sub { { a => 1, b => 2, c => 3 }->{$_} }) };
  $got{$order}++;
};

my %expect = (
  'abc' => 1 * 2,
  'acb' => 1 * 3,
  'bac' => 2 * 1,
  'bca' => 2 * 3,
  'cab' => 3 * 1,
  'cba' => 3 * 2,
);

is_deeply( \%got, \%expect, 'Got correct distribution of ordering counts' );

## bundle_by
is_deeply( c(1, 2, 3)->bundle_by(sub { $_[0] }, 1), [ 1, 2, 3 ], 'bundle_by 1' );

is_deeply( c(1, 2, 3, 4)->bundle_by(sub { $_[0] }, 2), [ 1, 3 ], 'bundle_by 2 first' );
is_deeply( c(1, 2, 3, 4)->bundle_by(sub { @_ }, 2), [ 1, 2, 3, 4 ], 'bundle_by 2 all' );
is_deeply( c(1, 2, 3, 4)->bundle_by(sub { c(@_) }, 2), [ [ 1, 2 ], [ 3, 4 ] ], 'bundle_by 2 [all]' );

is_deeply( { @{ c(qw( a b c d ))->bundle_by(sub { uc $_[1] => $_[0] }, 2) } }, { B => "a", D => "c" }, 'bundle_by 2 constructing hash' );

is_deeply( c(1, 2, 3)->bundle_by(sub { [ @_ ] }, 2), [ [ 1, 2 ], [ 3 ] ], 'bundle_by 2 yields short final bundle' );

done_testing;
