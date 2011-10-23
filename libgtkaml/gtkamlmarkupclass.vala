using GLib;
using Vala;

using Gtkaml.Ast;
/**
 * Represents a Class as declared by a Gtkaml root node. 
 * This is mainly used to identify that after parsing, a Gtkaml markup resolver needs to be used on this specific class
 */
public class Gtkaml.MarkupClass : Class {

	public MarkupTag markup_root {get; set;}

	public MarkupClass (string tag_name, MarkupNamespace tag_namespace, string class_name, SourceReference? source_reference = null)
	{
		base (class_name, source_reference);
		this.markup_root = new MarkupRoot (this, tag_name, tag_namespace, source_reference);
	}
	
}

