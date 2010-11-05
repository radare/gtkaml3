using Vala;

/**
 * wrapper for Method and Signal.
 * Supports .name and .get_parameters
 */

public class Gtkaml.Callable {
	
	public Symbol member {get; private set;}
	
	public Callable (Symbol member) {
		assert (member is Vala.Signal || member is Method);
		this.member = member;
	}
	
	public Vala.List<Vala.Parameter> get_parameters ()
	{
		if (member is Method)
			return ((Method)member).get_parameters ();
		return ((Vala.Signal)member).get_parameters ();
	}
	
	public string name { get { return member.name; } }
	
	public Symbol? parent_symbol { get { return member.parent_symbol; } }
}
