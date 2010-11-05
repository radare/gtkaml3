using GLib;
using Vala;

/**
 * Represents a Class as declared by a Gtkaml root node
 */
public class Gtkaml.MarkupClass : Class {

	public MarkupTag markup_root {get; set;}

	public MarkupClass (string tag_name, MarkupNamespace tag_namespace, string class_name, SourceReference? source_reference = null)
	{
		base (class_name, source_reference);
		this.markup_root = new MarkupRoot (this, tag_name, tag_namespace, source_reference);
		//TODO: this class in a namespace too
	}
	
}

