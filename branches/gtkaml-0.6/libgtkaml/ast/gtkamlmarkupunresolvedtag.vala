using GLib;
using Vala;

/**
 * Any markup tag encountered in XML that is not the root, nor has g:public/g:private identifier.
 * Can later morph into a complex attribute or into a temp
 */
public class Gtkaml.MarkupUnresolvedTag : MarkupChildTag {

	public override string me { get { assert_not_reached(); } }
	
	public MarkupUnresolvedTag (MarkupTag parent_tag, string tag_name, MarkupNamespace tag_namespace, SourceReference? source_reference = null)
	{
		base (parent_tag, tag_name, tag_namespace, source_reference);
	}	
	
	public override void generate_public_ast (MarkupParser parser) throws ParseError {
		//No public AST for unkown stuff
	}
	
	public override MarkupTag? resolve (MarkupResolver resolver) throws ParseError {
		if (!tag_namespace.explicit_prefix && markup_attributes.size == 0)  { //candidate for attribute
			ObjectTypeSymbol parent_object = parent_tag.resolved_type.data_type as ObjectTypeSymbol;
			if (parent_object != null) {
				foreach (Property p in parent_object.get_properties ()) {
					if (p.name == tag_name) {
						//TODO: transform this into attribute
						return null; //remove 'this' from parent
					}
				}
			} else stderr.printf ("Teapa %s\n", parent_tag.resolved_type.data_type.to_string ());
			//TODO: search through fields too?
		}
		
		var markup_temp = new MarkupTemp (parent_tag, tag_name, tag_namespace, source_reference);
		parent_tag.replace_child_tag (this, markup_temp);
		return markup_temp.resolve (resolver);
	}
	
	public override void generate (MarkupResolver resolver) throws ParseError {
		assert_not_reached ();//unresolved tags are replaced with temporary variables or complex attributes at resolve () time
	}
}
