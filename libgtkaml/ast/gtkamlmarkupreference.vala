using GLib;
using Vala;

/**
 * Represents a tag with g:existing and therefore no creation method
 */
public class Gtkaml.Ast.MarkupReference : MarkupChildTag {

	protected string existing_name { get; private set; }

	public MarkupReference (MarkupTag parent_tag, string tag_name, MarkupNamespace tag_namespace, string existing_name, SourceReference? source_reference = null)
	{
		base (parent_tag, tag_name, tag_namespace, source_reference);
		this.existing_name = existing_name;
	}

	public override string me { get { return existing_name; }}

	public override void generate_public_ast (CodeParserProvider parser) throws ParseError {
		//No public AST that ain't there already for references
	}
	
	public override MarkupTag? resolve (MarkupResolver resolver) throws ParseError {
		resolver.visit_data_type (data_type);
		return this;
	}

	public override void resolve_attributes (MarkupResolver resolver) throws ParseError {
		//removed: resolve_creation_method (resolver);
		resolve_composition_method (resolver);
	}
	
	public override void generate (MarkupResolver resolver) throws ParseError {
		//removed: generate construct_..() for references
		base.generate (resolver);
	}
}
