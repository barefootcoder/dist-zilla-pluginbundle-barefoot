use Test::Most		0.25;

use JSON::MaybeXS;
use Dist::Zilla::App;
use Path::Tiny qw< path cwd tempdir >;


our $tdist = tempdir( CLEANUP => 1 );


# go to our temp dir for this test
my $old = cwd;
END { chdir $old }				# go back to original dir so cleanup of temp dir can happen
chdir $tdist;


# create a skeletal distribution

my $tname = 'Test-Module';
my $tversion = '0.01';

path('dist.ini')->spew( <<END );
name				= $tname
author				= Buddy Burden <barefoot\@cpan.org>
license				= Artistic_2_0
copyright_holder	= Buddy Burden

version = $tversion
[\@BAREFOOT]
fake_release = 1
repository_link = none
END

path('Changes')->spew( <<'END' );
Revision history for Test-Module

{{$NEXT}}
END

create_lib_file( 'Test::Module' => <<'END' );
# PODCLASSNAME
class Test::Module with Some::Role
{
# ABSTRACT: Just a module for testing
# VERSION
}
END

my $t = path( 't' );
$t->mkpath;
$t->path('require.t')->spew( <<'END' );
use Test::Most 0.25;

require_ok( 'Test::Module' );

done_testing;
END


# now build our test dist so we can have some files to test

run_dzil_command("build");
chdir "$tname-$tversion" or die("failed to run dzil");

my $meta = decode_json(path('META.json')->slurp);

is $meta->{version}, $tversion, 'version is correct in meta';
cmp_deeply [ sort keys %{ $meta->{provides} } ], [ qw< Test::Module > ], '`provides` in meta is correct';



done_testing;


sub run_dzil_command
{
	local @ARGV = @_;
	Dist::Zilla::App->run;
}


sub create_lib_file
{
	my ($module, $content) = @_;
	my @dirs = split('::', $module);
	$module = pop @dirs;
	$module .= '.pm';

	my $lib = path( 'lib', @dirs );
	$lib->mkpath;
	$lib->path($module)->spew( $content );
}
