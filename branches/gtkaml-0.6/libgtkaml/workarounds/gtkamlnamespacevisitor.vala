using GLib;
using Vala;

class Gtkaml.NamespaceVisitor : CodeVisitor {
	private Vala.List<UsingDirective> using_directives = new ArrayList<UsingDirective> ();
	
	public Vala.List<UsingDirective> get_using_directives () {
		return using_directives;
	}
	
	public override void visit_namespace (Vala.Namespace ns) {
		ns.accept_children (this);
	}
	
	public override void visit_using_directive (UsingDirective ns_ref) {
		using_directives.add (ns_ref);
	}
}
	
	
