using Vala;

/**
 * A Vala unresolved symbol that will be parsed as a namespace. 
 */
public class Gtkaml.MarkupNamespace : Vala.UnresolvedSymbol {

	/**
	 * weather at XML parsing time, there was a prefix on this tag or it was the implicit one
	 */
	public bool explicit_prefix {get; set;}
	
	public MarkupNamespace (Vala.UnresolvedSymbol? inner, string name, Vala.SourceReference? source_reference = null)
	{
		base (inner, name, source_reference);
	}
	
}
