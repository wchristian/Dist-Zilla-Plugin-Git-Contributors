use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;

use lib 't/lib';
use GitSetup;

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => dist_ini(
                {
                    name     => 'DZT-Sample',
                    abstract => 'Sample DZ Dist',
                    version  => '0.001',
                    author   => 'Anne O\'Thor <author@example.com>',
                    license  => 'Perl_5',
                    copyright_holder => 'Anne O\'Thor',
                },
                [ GatherDir => ],
                [ MetaConfig => ],
                [ 'Git::Contributors' => { include_releaser => 0 } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

my $root = path($tzil->tempdir)->child('source');
my $git = git_wrapper($root);

my $releaser = 'Test User <test@example.com>';

my $changes = $root->child('Changes');
$changes->spew("Release history for my dist\n\n");
$git->add('Changes');
$git->commit({ message => 'first commit', author => $tzil->authors->[0] });

$changes->append("- a changelog entry\n");
$git->add('Changes');
$git->commit({ message => 'second commit', author => $releaser });

$changes->append("- a changelog entry\n");
$git->add('Changes');
$git->commit({ message => 'third commit', author => 'Anon Y. Moose <anon@null.com>' });

is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
) or diag 'saw log messages: ', explain $tzil->log_messages;

is(
    $tzil->plugin_named('Git::Contributors')->_releaser,
    $releaser,
    'properly determined the name+email of the current user',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        x_contributors => [
            'Anon Y. Moose <anon@null.com>',
        ],
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::Git::Contributors',
                    config => {
                        'Dist::Zilla::Plugin::Git::Contributors' => {
                            include_authors => 0,
                            include_releaser => 0,
                            order_by => 'name',
                        },
                    },
                    name => 'Git::Contributors',
                    version => ignore,
                },
            ),
        }),
    }),
    'releaser not included in contributor list (nor author, by default)',
)
or diag 'got distmeta: ', explain $tzil->distmeta;

done_testing;
