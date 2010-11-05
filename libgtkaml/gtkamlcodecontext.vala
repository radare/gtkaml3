using Vala;

public class Gtkaml.CodeContext : Vala.CodeContext {

	public MarkupResolver markup_resolver { get; private set; }
	public SymbolResolver resolver { get { return markup_resolver; } }
	
	public CodeContext () {
		base ();
		markup_resolver = new MarkupResolver ();
	}

	public new void check () {
		markup_resolver.resolve (this);

		if (report.get_errors () > 0) {
			return;
		}

		analyzer.analyze (this);

		if (report.get_errors () > 0) {
			return;
		}

		flow_analyzer.analyze (this);
	}
}
