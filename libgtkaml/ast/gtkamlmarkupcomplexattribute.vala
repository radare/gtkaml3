using GLib;
using Vala;

/**
 * An attribute whose value is represented as another MarkupTag
 */
public class Gtkaml.Ast.MarkupComplexAttribute : MarkupAttribute {

	public MarkupComplexAttribute (string attribute_name, MarkupTag parent_tag, SourceReference? source_reference = null) {
		base (attribute_name, parent_tag.me, source_reference);
		assert_not_reached ();
	}

	public override Expression get_expression (MarkupResolver resolver, MarkupTag markup_tag) throws ParseError {
		assert_not_reached ();
	}

	public override Statement get_assignment (MarkupResolver resolver, MarkupTag markup_tag) throws ParseError {
		assert_not_reached ();
	}

	public override void resolve (MarkupResolver resolver, MarkupTag markup_tag) {
		assert_not_reached ();
	}
}
