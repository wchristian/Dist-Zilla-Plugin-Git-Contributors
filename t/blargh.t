use Test::InDistDir;
use Dist::Zilla::Plugin::Git::Contributors;
use File::Temp qw/ tempdir /;
use Archive::Extract;
use Test::More;

my $dir = tempdir CLEANUP => 1;
Archive::Extract->new( archive => "t/blargh.zip" )->extract( to => $dir );
chdir $dir;

my $p = bless {}, "Dist::Zilla::Plugin::Git::Contributors";
$p->{$_} = 1 for qw( order_by include_authors include_releaser );
*Dist::Zilla::Plugin::Git::Contributors::log_debug = sub { };
my ( $first ) = @{ $p->_contributors };
is length $first, 13, "we got utf8 from git";
done_testing;
