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
	
	public override void generate_public_ast (MarkupParser parser) throws ParseError {
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
						parent_tag.add_markup_attribute (new MarkupComplexAttribute (tag_name, parent_tag, child_tags[0], source_reference));
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
	
	private void resolve_silently (MarkupResolver resolver) {
		if (! (data_type is UnresolvedType))
			return;

		//this prevents reporting another error
		((UnresolvedType)data_type).unresolved_symbol.error = true;

		resolver.visit_data_type (data_type);

		((UnresolvedType)data_type).unresolved_symbol.error = false;
	}
}
