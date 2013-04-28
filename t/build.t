use Test::Most		0.25;
use Test::Command	0.10;

use Path::Class;
use File::Temp qw< tempdir >;


my $dir = tempdir( CLEANUP => 1 );

my @filter_out =
(
	'\[DZ\].*',
	'\[(@BAREFOOT/)?ReadmeAnyFromPod\] Override README\.pod in root',
);


# pop back up to actual dist dir for this test
sub inside_build_dir { grep { $_ eq '.build' } dir()->absolute->components }
BAIL_OUT("can't understand my current directory structure") unless inside_build_dir();
chdir '..' while inside_build_dir();

# try to build again, but in a temp dir
#	*	keeps from building in a build dir, which does very wonky things
#	*	tempdir can be cleaned up automatically, so no need to do a dzil clean
#	**		(which is good, because clean doesn't take a --in param)
my $cmd = Test::Command->new( cmd => "dzil build --in $dir" );
my $stdout = $cmd->stdout_value;
my $stderr = $cmd->stderr_value;

# remove lines we don't care about
for ($stdout, $stderr)
{
	foreach my $pattern (@filter_out)
	{
		s/^$pattern\n//mg;
	}
}

is $stdout, '', 'no unexpected lines in build';
is $stderr, '', 'no error lines in build';


done_testing;
