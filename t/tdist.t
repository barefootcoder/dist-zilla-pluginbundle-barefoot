use Test::Most		0.25;
use Test::Command	0.10;

use Path::Tiny qw< path cwd tempdir >;


our $tdist = tempdir( CLEANUP => 1 );


# go to our temp dir for this test
my $old = cwd;
END { chdir $old }				# go back to original dir so cleanup of temp dir can happen
chdir $tdist;


# create a skeletal distribution

#[@Filter]
#-bundle = @BAREFOOT
#-remove = GitHubMeta
path('dist.ini')->spew( <<'END' );
name				= Test-Module
author				= Buddy Burden <barefoot@cpan.org>
license				= Artistic_2_0
copyright_holder	= Buddy Burden

version = 0.01
[@BAREFOOT]
fake_release = 1
repository_link = none
END

path('weaver.inix')->spew( <<'END' );
END

my $lib = path( 'lib', 'Test' );
$lib->mkpath;
$lib->path('Module.pm')->spew( <<'END' );
package Test::Module;

# ABSTRACT: Just a module for testing
# VERSION

1;
END

my $t = path( 't' );
$t->mkpath;
$t->path('require.t')->spew( <<'END' );
use Test::Most 0.25;

require_ok( 'Test::Module' );

done_testing;
END


# now build our test dist so we can have some files to test

demand_successful_command("dzil build");
pass;


done_testing;


sub demand_successful_command
{
	my ($command) = @_;

	# get rid of stdout, but keep stderr
	# it might aid in debugging
	is system("$command >/dev/null"), 0, "command succeeded [$command]"
			or done_testing, exit;
}
