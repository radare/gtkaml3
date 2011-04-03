using GLib;
using Vala;

/**
 * Markup tag that has no g:private or g:public gtkaml attribute, therefore is local to the construct method
 */
public class Gtkaml.Ast.MarkupTemp : MarkupChildTag {
	private string temp_name;
	
	public override string me { get { return temp_name; } }
	
	public MarkupTemp (MarkupTag parent_tag, string tag_name, MarkupNamespace tag_namespace, SourceReference? source_reference = null)
	{
		base (parent_tag, tag_name, tag_namespace, source_reference);
		//FIXME: get_temp_name is weird
		temp_name = ("_" + tag_name + markup_class.get_temp_name ()).replace (".", "_");
	}
	
	public override void generate_public_ast (MarkupParser parser) throws ParseError {
		//nothing public about local temps
	}

	public override MarkupTag? resolve (MarkupResolver resolver) throws ParseError {
		return base.resolve (resolver);
	}
	
	public override void generate (MarkupResolver resolver) throws ParseError {
		generate_construct_local (resolver);
		generate_add (resolver);
	}
	
	private void generate_construct_local(MarkupResolver resolver) throws ParseError {		
		var initializer = get_initializer (resolver);
		var local_variable = new LocalVariable (null, me,  initializer, source_reference);
		var local_declaration = new DeclarationStatement (local_variable, source_reference);
		
		markup_class.constructor.body.add_statement (local_declaration);
	}
}
