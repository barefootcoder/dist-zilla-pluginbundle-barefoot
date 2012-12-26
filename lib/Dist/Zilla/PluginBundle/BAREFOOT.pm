use 5.012;
use MooseX::Declare;
use Method::Signatures::Modifiers;

class Dist::Zilla::PluginBundle::BAREFOOT with Dist::Zilla::Role::PluginBundle::Easy
{
	use autodie										2.00				;
	use List::MoreUtils											'uniq'	;
	use MooseX::Has::Sugar												;
	use MooseX::Types::Moose									':all'	;

	# Dependencies
	use Dist::Zilla									4.3			  ;		# authordeps

	use Dist::Zilla::PluginBundle::Git							();
	#use Dist::Zilla::PluginBundle::Filter						();

	use Dist::Zilla::Plugin::PodWeaver							();
	use Dist::Zilla::Plugin::GithubMeta				0.10		();
	use Dist::Zilla::Plugin::Bugtracker				1.102670	();
	use Dist::Zilla::Plugin::MetaNoIndex						();
	use Dist::Zilla::Plugin::MinimumPerl						();
	use Dist::Zilla::Plugin::OurPkgVersion			0.001008	();
	use Dist::Zilla::Plugin::ReadmeFromPod						();
	use Dist::Zilla::Plugin::Test::Version						();
	use Dist::Zilla::Plugin::CheckExtraTests					();
	use Dist::Zilla::Plugin::InsertCopyright		0.001		();
	use Dist::Zilla::Plugin::Git::NextVersion					();
	use Dist::Zilla::Plugin::ReadmeAnyFromPod		0.120051	();
	use Dist::Zilla::Plugin::Test::PodSpelling		2.001002	();
	use Dist::Zilla::Plugin::CopyFilesFromBuild					();
	use Dist::Zilla::Plugin::CheckPrereqsIndexed	0.002		();
	#use Dist::Zilla::Plugin::MetaProvides::Package	1.14		();		# hides DB/main/private packages
	use Dist::Zilla::Plugin::CheckChangesHasContent				();


	# VERSION

	my @dirty_files = qw< dist.ini Changes README.pod >;


	sub mvp_multivalue_args { qw/stopwords/ }

	has stopwords		=>	( ro, isa => ArrayRef, lazy, default => method { $self->payload->{'stopwords'} // [] } );
	has fake_release	=>	( ro, isa => Bool, lazy, default => method { $self->payload->{'fake_release'} } );
	has no_spellcheck	=>	( ro, isa => Bool, default => 0 );
	has auto_prereq		=>	( ro, isa => Bool, lazy, default => method { $self->payload->{'auto_prereq'} // 1 } );
	has tag_format		=>	( ro, isa => Str, lazy, default => method { $self->payload->{'tag_format'} // 'v%v' } );
	has version_regexp	=>	( ro, isa => Str, lazy, default => method { $self->payload->{'version_regexp'} // '^v(.+)$' } );
	has weaver_config	=>	( ro, isa => Str, lazy, default => method { $self->payload->{'weaver_config'} // '@BAREFOOT' } );
	has git_remote		=>	( ro, isa => Str, lazy, default => method { $self->payload->{'git_remote'} // 'origin' } );
	has legal_addendum	=>	( ro, isa => Str, lazy, default => method { $self->payload->{'legal_addendum'} // '' } );


	method configure
	{
		my @push_to = uniq 'origin', $self->git_remote;

		$self->add_plugins (

			# version number
			[ 'Git::NextVersion'		=>	{ first_version => '0.01', version_regexp => $self->version_regexp } ],

			# gather and prune
			[ GatherDir					=>	{ exclude_filename => [qw< README.pod >] }],		# core
			PruneCruft					=>														# core
			ManifestSkip				=>														# core

			# file munging
			OurPkgVersion				=>
			InsertCopyright				=>
			[ PodWeaver					=>	{ config_plugin => $self->weaver_config } ],

			# generated distribution files
			ReadmeFromPod				=>
			License						=>														# core
			[ ReadmeAnyFromPod			=>	{	# generate in root for github, etc.
												type		=> 'pod',
												filename	=> 'README.pod',
												location	=> 'root',
											}
			],

			# generated xt/ tests
		( $self->no_spellcheck
		?	()
		:	[ 'Test::PodSpelling'		=>	{ stopwords => $self->stopwords } ]
		),
			MetaTests					=>														# core
			PodSyntaxTests				=>														# core
			PodCoverageTests			=>														# core
			'Test::Version'				=>

			# metadata
			MinimumPerl					=>
		( $self->auto_prereq
		?	[ AutoPrereqs				=>	{ skip => "^t::lib" } ]
		:	()
		),
			[ GithubMeta				=>	{ remote => $self->git_remote } ],
			[ MetaNoIndex				=>	{
												directory	=> [qw< t xt examples corpus >],
												package		=> [qw< DB >]
											}
			],
			#[ 'MetaProvides::Package'	=>	{ meta_noindex => 1 } ],							# AFTER MetaNoIndex
			[ Bugtracker				=>	{ web => "http://github.com/me/%l/issues" } ],
			MetaYAML					=>														# core
			MetaJSON					=>														# core

			# build system
			ExecDir						=>														# core
			ShareDir					=>														# core
			MakeMaker					=>														# core

			# copy files from build back to root for inclusion in VCS
			[ CopyFilesFromBuild		=>	{
												move => 'README.pod',
											}
			],

			# manifest -- must come after all generated files
			Manifest					=>														# core

			# before release
			[ 'Git::Check'				=>	{
												allow_dirty	=> [@dirty_files]
											}
			],
			CheckPrereqsIndexed			=>
			CheckChangesHasContent		=>
			CheckExtraTests				=>
			TestRelease					=>														# core
			ConfirmRelease				=>														# core

			# release
		( $self->fake_release
		?	'FakeRelease'
		:	'UploadToCPAN'																		# core
		),

			# after release
			# Note -- NextRelease is here to get the ordering right with
			# git actions.  It is *also* a file munger that acts earlier

			# commit dirty Changes, dist.ini, README.pod
			[ 'Git::Commit'				=>
											{
												allow_dirty	=> [@dirty_files],
												commit_msg	=> "packaging for CPAN: %v",
											}
			],
			[ 'Git::Tag'				=>	{
												tag_format	=> $self->tag_format,
												tag_message	=> 'version %v for CPAN',
											}
			],

			# bumps Changes
			NextRelease					=>														# core (also munges files)

			[ 'Git::Push'				=>	{ push_to => [@push_to] } ],

		);

	}

}

1;

# ABSTRACT: Dist::Zilla configuration the way BAREFOOT does it
# COPYRIGHT

__END__


=for stopwords

=for Pod::Coverage configure mvp_multivalue_args

=begin wikidoc

= SYNOPSIS

  # in dist.ini
  [@BAREFOOT]

= DESCRIPTION

This is a [Dist::Zilla] PluginBundle.  It is roughly equivalent to the following dist.ini:

	; version provider
	[Git::NextVersion]					; get version from last release tag
	first_version = 0.01
	version_regexp = ^v(.+)$

	; choose files to include
	[GatherDir]							; everything under top dir
	exclude_filename = README.pod		; skip this generated file
	exclude_filename = META.json		; skip this generated file

	[PruneCruft]						; default stuff to skip
	[ManifestSkip]						; if -f MANIFEST.SKIP, skip those, too

	; file modifications
	[OurPkgVersion]						; add $VERSION = ... to all files
	[InsertCopyright					; add copyright at "# COPYRIGHT"
	[PodWeaver]							; generate Pod
	config_plugin = @BAREFOOT			; allows Pod::WikiDoc and a few other bits and bobs

	; generated files
	[License]							; boilerplate license
	[ReadmeFromPod]						; from Pod (runs after PodWeaver)
	[ReadmeAnyFromPod]					; create README.pod in repo directory
	type = pod
	filename = README.pod
	location = root

	; xt tests
	[Test::PodSpelling]					; xt/author/pod-spell.t
	[MetaTests]							; xt/release/meta-yaml.t
	[PodSyntaxTests]					; xt/release/pod-syntax.t
	[PodCoverageTests]					; xt/release/pod-coverage.t
	[Test::Version]						; xt/release/test-version.t

	; metadata
	[AutoPrereqs]						; find prereqs from code
	skip = ^t::lib

	[MinimumPerl]						; determine minimum perl version
	[GithubMeta]
	remote = origin

	[MetaNoIndex]						; sets 'no_index' in META
	directory = t
	directory = xt
	directory = examples
	directory = corpus
	package = DB						; just in case

	[Bugtracker]
	web = http://github.com/me/%l/issues

	; can't get this one to work right ATM
	; [MetaProvides::Package]			; add 'provides' to META files
	; meta_noindex = 1					; respect prior no_index directives

	[MetaYAML]							; generate META.yml (v1.4)
	[MetaJSON]							; generate META.json (v2)

	; build system
	[ExecDir]							; include 'bin/*' as executables
	[ShareDir]							; include 'share/' for File::ShareDir
	[MakeMaker]							; create Makefile.PL

	; manifest (after all generated files)
	[Manifest]							; create MANIFEST

	; move README.pod back to repo dir
	[CopyFilesFromBuild]
	move = README.pod

	; before release
	[Git::Check]						; ensure all files checked in
	allow_dirty = dist.ini
	allow_dirty = Changes
	allow_dirty = README.pod
	allow_dirty = META.json

	[CheckPrereqsIndexed]				; ensure prereqs are on CPAN
	[CheckChangesHasContent]			; ensure Changes has been updated
	[CheckExtraTests]					; ensure xt/ tests pass
	[TestRelease]						; ensure t/ tests pass
	[ConfirmRelease]					; prompt before uploading

	; releaser
	[UploadToCPAN]						; uploads to CPAN

	; after release
	[Git::Commit / Commit_Dirty_Files]	; commit Changes (as released)

	[Git::Tag]							; tag repo with custom tag
	tag_format = v%v					; this one is overridable
	tag_message = version %v for CPAN	; this one isn't

	; NextRelease acts *during* pre-release to write $VERSION and
	; timestamp to Changes and  *after* release to add a new {{$NEXT}}
	; section, so to act at the right time after release, it must actually
	; come after Commit_Dirty_Files but before Commit_Changes in the
	; dist.ini.  It will still act during pre-release as usual
	[NextRelease]

	[Git::Commit / Commit_Changes]		; commit Changes (for new dev)

	[Git::Push]							; push repo to remote
	push_to = origin

= USAGE

To use this PluginBundle, just add it to your dist.ini.  You can provide the following options:

* {auto_prereq} -- This indicates whether AutoPrereq should be used or not.  Default is 1.
* {tag_format} -- Given to {Git::Tag}.  Default is 'v%v'.
* {version_regexp} -- Given to {Git::NextVersion}.  Default is '^v(.+)$'.
* {git_remote} -- Given to {Git::Push} _in addition to_ origin; given to GithubMeta _instead of_
origin.
* {fake_release} -- Swaps FakeRelease for UploadToCPAN. Mostly useful for testing a dist.ini without
risking a real release.
* {weaver_config} -- Specifies a Pod::Weaver bundle.  Defaults to @BAREFOOT.
* {stopwords} -- Add stopword for Test::PodSpelling (can be repeated).
* {no_spellcheck} -- Omit Test::PodSpelling tests.

= INSTALLATION

If you want to make sure you have all the necessary prereqs, try this (from the dir you checked out
the distro into):

	perl -lne 'print $1 if /Dependencies/../VERSION/ and /use\s+(\S+)/' lib/*/*/PluginBundle/BAREFOOT.pm | cpanm -n

= SEE ALSO

* [Dist::Zilla]
* [Dist::Zilla::Plugin::PodWeaver]

=end wikidoc

=cut
