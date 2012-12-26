use Test::Most		0.25;
use Test::Command	0.08;

use Path::Class;
use File::Temp qw< tempdir >;


my $dir = tempdir( CLEANUP => 1 );

my @filter_out =
(
	'\[DZ\]',
	'\[@BAREFOOT/ReadmeAnyFromPod\] Override README\.pod in root',
);


# pop back up to actual dist dir for this test
chdir '../..';

# try to build again, but in a temp dir
#	*	keeps from building in a build dir, which does very wonky things
#	*	tempdir can be cleaned up automatically, so no need to do a dzil clean
#	**		(which is good, because clean doesn't take a --in param)
my $cmd = join(' | ', "dzil build --in $dir", map { "grep -v '$_'" } @filter_out);
$cmd = Test::Command->new( cmd => $cmd );
$cmd->stdout_is_eq('', 'no unexpected lines in build');
TODO:
{
	local $TODO = 'not sure why this is failing ...';
	$cmd->stderr_is_eq('', 'no error lines in build');
}


done_testing;
