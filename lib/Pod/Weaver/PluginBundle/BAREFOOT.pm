use 5.012;
use MooseX::Declare;
use Method::Signatures::Modifiers;

# PODCLASSNAME
# PODNAME: Pod::Weaver::PluginBundle::BAREFOOT
class Pod::Weaver::PluginBundle::BAREFOOT
{
	use autodie										2.00				;
	use MooseX::Has::Sugar												;
	use MooseX::Types::Moose									':all'	;

	# Dependencies
	use Pod::Weaver 3.101635; # fixed ABSTRACT scanning
	use Pod::Weaver::Config::Assembler;

	use Pod::Weaver::Plugin::WikiDoc ();
	use Pod::Elemental::Transformer::List 0.101620 ();
	use Pod::Weaver::Section::Support 1.001 ();


	# VERSION


	my $bugtracker_content = <<'END';
		This module is on GitHub.  Feel free to fork and submit patches.  Please note that I develop
		via TDD (Test-Driven Development), so a patch that includes a failing test is much more
		likely to get accepted (or least likely to get accepted more quickly).

		If you just want to report a problem or suggest a feature, that's okay too.  You can create
		an issue on GitHub here: {WEB}.
END


	method _exp { Pod::Weaver::Config::Assembler->expand_package($self) }

	method mvp_bundle_config ($class: ...)
	{
		# get payload (configurable parameters) from the dzil plugin bundle
		my $payload = Dist::Zilla::PluginBundle::BAREFOOT->weaver_payload;

		# now set default values for them
		$payload->{'repository_link'}	//= 'both';

		my @plugins;
		push @plugins, (
			[ '@BAREFOOT/WikiDoc',     _exp('-WikiDoc'),	{} ],

			[ '@BAREFOOT/CorePrep',    _exp('@CorePrep'),	{} ],
			[ '@BAREFOOT/Name',        _exp('Name'),		{} ],
			[ '@BAREFOOT/Version',     _exp('Version'),		{
																format => "This document describes version %v of %m.",
															}
			],

			[ '@BAREFOOT/Synopsis',    _exp('Generic'),		{ header      => 'SYNOPSIS'    } ],
			[ '@BAREFOOT/Description', _exp('Generic'),		{ header      => 'DESCRIPTION' } ],
			[ '@BAREFOOT/Overview',    _exp('Generic'),		{ header      => 'OVERVIEW'    } ],
		);

		for my $plugin (
			[ 'Attributes', 			_exp('Collect'),	{ command => 'attr'   } ],
			[ 'Methods',    			_exp('Collect'),	{ command => 'method' } ],
			[ 'Functions',  			_exp('Collect'),	{ command => 'func'   } ],
		){
			$plugin->[2]->{'header'} = uc $plugin->[0];
			push @plugins, $plugin;
		}

		push @plugins, (
			[ '@BAREFOOT/Leftovers', _exp('Leftovers'),		{} ],
			[ '@BAREFOOT/Support',   _exp('Support'),		{
																perldoc				=> 1,
																websites			=> 'none',
																bugs				=> 'metadata',
																bugs_content		=> $bugtracker_content,
																repository_link		=> $payload->{'repository_link'},
																repository_content	=> 'none',
															}
			],
			[ '@BAREFOOT/Authors',   _exp('Authors'),		{} ],
			[ '@BAREFOOT/Legal',     _exp('Legal'),			{} ],
			[ '@BAREFOOT/List',      _exp('-Transformer'),	{ transformer => 'List' } ],
		);

		return @plugins;
	}

}

# ABSTRACT: BAREFOOT's default Pod::Weaver config
# COPYRIGHT

1;

=for Pod::Coverage mvp_bundle_config

=begin wikidoc

= DESCRIPTION

This is a [Pod::Weaver] PluginBundle.  It is roughly equivalent to the
following weaver.ini:

  [-WikiDoc]

  [@CorePrep]

  [Name]
  [Version]

  [Generic / SYNOPSIS]
  [Generic / DESCRIPTION]
  [Generic / OVERVIEW]

  [Collect / ATTRIBUTES]
  command = attr

  [Collect / METHODS]
  command = method

  [Collect / FUNCTIONS]
  command = func

  [Leftovers]
  [Support]
  perldoc = 1
  websites = none
  bugs = metadata
  bugs_content = ... stuff (web only, email omitted) ...
  repository_link = both
  repository_content = none

  [Authors]
  [Legal]

  [-Transformer]
  transfomer = List

= USAGE

This PluginBundle is used automatically with the C<@BAREFOOT> [Dist::Zilla]
plugin bundle.

= SEE ALSO

* [Pod::Weaver]
* [Pod::Weaver::Plugin::WikiDoc]
* [Pod::Elemental::Transformer::List]
* [Dist::Zilla::Plugin::PodWeaver]

=end wikidoc

=cut
