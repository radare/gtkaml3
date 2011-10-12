using GLib;
using Vala;

/**
 * Any markup tag encountered in XML that is not the root, nor has g:public/g:private identifier.
 * Can later morph into a complex attribute or into a temp
 */
public class Gtkaml.Ast.MarkupUnresolvedTag : MarkupChildTag {

	public override string me { get { assert_not_reached(); } }
	
	public MarkupUnresolvedTag (MarkupTag parent_tag, string tag_name, MarkupNamespace tag_namespace, SourceReference? source_reference = null)
	{
		base (parent_tag, tag_name, tag_namespace, source_reference);
	}	
	
	public override void generate_public_ast (CodeParserProvider parser) throws ParseError {
		//No public AST for unkown stuff
	}
	
	public override MarkupTag? resolve (MarkupResolver resolver) throws ParseError {
		//try to silently resolve as a type
		resolve_silently (resolver);

		if (!tag_namespace.explicit_prefix && markup_attributes.size == 0)  { //candidate for attribute
			if (resolved_type.data_type == null) {
				//resolve failed => is an attribute
				switch (child_tags.size) {
					case 0:
						parent_tag.add_markup_attribute (new MarkupAttribute (tag_name, text, source_reference));
						return null;
					case 1:
						var complex_attribute = mutate_into_complex_attribute (child_tags[0], resolver);
						parent_tag.add_markup_attribute (complex_attribute);
						return null;
					default:
						throw new ParseError.SYNTAX ("Don't know how to handle `%s's children".printf (tag_name));
				}
			}
		}
		var markup_temp = new MarkupTemp (parent_tag, tag_name, tag_namespace, source_reference);
		markup_temp.resolve (resolver);
		parent_tag.replace_child_tag (this, markup_temp);
		return markup_temp;
	}
	
	public override void generate (MarkupResolver resolver) throws ParseError {
		assert_not_reached ();//unresolved tags are replaced with temporary variables or complex attributes at resolve () time
	}
	
	private MarkupComplexAttribute mutate_into_complex_attribute (MarkupTag child_tag, MarkupResolver resolver) throws ParseError
	{
		//child_tag.generate_public_ast (resolver);
		var resolved_child = child_tag.resolve (resolver) as MarkupChildTag;

		resolved_child.standalone = true;
		resolved_child.resolve_attributes (resolver);

		resolved_child.generate (resolver);
		
		return new MarkupComplexAttribute (tag_name, parent_tag, resolved_child, source_reference);
	}		
	
	private void resolve_silently (MarkupResolver resolver) {
		if (! (data_type is UnresolvedType))
			return;

		//this prevents reporting another error
		((UnresolvedType)data_type).unresolved_symbol.error = true;

		resolver.visit_data_type (data_type);

		((UnresolvedType)data_type).unresolved_symbol.error = false;
	}
}
