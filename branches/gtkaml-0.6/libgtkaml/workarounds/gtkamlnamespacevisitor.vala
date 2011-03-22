using GLib;
using Vala;

///
/// Workaround just to enumerate using directives

public class Gtkaml.NamespaceVisitor : CodeVisitor {
	private List<UsingDirective> using_directives = new ArrayList<UsingDirective> ();
	
	public List<UsingDirective> get_using_directives () {
		return using_directives;
	}
	
	public override void visit_namespace (Vala.Namespace ns) {
		ns.accept_children (this);
	}
	
	public override void visit_using_directive (UsingDirective ns_ref) {
		using_directives.add (ns_ref);
	}
}
	
	
