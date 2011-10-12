using GLib;
using Vala;

/**
 * An attribute whose value is represented as another MarkupTag
 */
public class Gtkaml.Ast.MarkupComplexAttribute : MarkupAttribute {

	public MarkupTag value_tag;

	public MarkupComplexAttribute (string attribute_name, MarkupTag parent_tag, MarkupTag value_tag, SourceReference? source_reference = null) {
		base (attribute_name, parent_tag.me, source_reference);
		this.value_tag = value_tag;
	}

	public override Expression? get_expression (MarkupResolver resolver, MarkupTag markup_tag) throws ParseError {
		resolve (resolver, markup_tag);
		
		if (@signal != null) {
			Report.error (source_reference, "Signals cannot be defined as complex attributes");
			return null;
		} else {
			return new MemberAccess.simple (value_tag.me, source_reference);
		}
	}
}
