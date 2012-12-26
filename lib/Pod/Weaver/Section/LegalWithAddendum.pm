use 5.012;
use MooseX::Declare;
use Method::Signatures::Modifiers;

class Pod::Weaver::Section::LegalWithAddendum extends Pod::Weaver::Section::Legal
{

	# VERSION


	has addendum => ( is => 'ro', isa => 'Str', predicate => '_has_addendum' );

	override weave_section ($document, $input)
	{
		super();
		my $legal = $document->children->[-1];
		$legal->children->[0] .= "\n\n" . $self->addendum if $self->_has_addendum;
	}
}


1;


# ABSTRACT: Dist::Zilla configuration the way BAREFOOT does it
# COPYRIGHT
