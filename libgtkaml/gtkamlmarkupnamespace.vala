using Vala;

public class Gtkaml.MarkupNamespace : Vala.UnresolvedSymbol {

	public bool explicit_prefix {get; set;}
	
	public MarkupNamespace (Vala.UnresolvedSymbol? inner, string name, Vala.SourceReference? source_reference = null)
	{
		base (inner, name, source_reference);
	}
	
}
