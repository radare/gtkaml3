using GLib;
using Vala;
using Xml;
using Gtkaml.Ast;

/**
 * Gtkaml Parser
 */
public class Gtkaml.MarkupParser : CodeVisitor {

	private CodeContext context;
	
	public ValaParser code_parser {get; private set;}

	Vala.List<string> identifier_attributes;
	Vala.List<string> classname_attributes;
	Vala.List<string> parsetime_attributes;

	
	public MarkupParser () 
	{
		base ();	
		init_attribute_lists ();
	}

	public void parse (CodeContext context) {
		this.context = context;
		this.code_parser = new ValaParser (context); //TODO move this per class or per source file
		context.accept (this);
	}
	
	public override void visit_source_file (SourceFile source_file) {
		if (source_file.filename.has_suffix (".gtkaml")) {
			parse_file (source_file);
		}
	}

	public void parse_file (SourceFile source_file) {
		try {
			MarkupScanner scanner = new MarkupScanner(source_file);
			
			parse_using_directives (scanner);

			parse_markup_class (scanner);
		} catch (ParseError e) {
			Report.error (null, e.message);
		}
	}

	void parse_markup_class (MarkupScanner scanner) throws ParseError {
		
		MarkupNamespace base_ns = parse_namespace (scanner);
		string class_name = parse_identifier (scanner.node->get_ns_prop ("name", scanner.gtkaml_uri));
		string base_name = parse_identifier (scanner.node->name);

		MarkupClass markup_class = new MarkupClass (base_name, base_ns, class_name, scanner.get_src ());

		//TODO: set markupClass access to internal or public
		markup_class.access = SymbolAccessibility.PUBLIC;

		//TODO: create another NS in lieu of target_namespace
		Namespace target_namespace = context.root;
		
		target_namespace.add_class (markup_class);
		//scanner.source_file.add_node (markup_class);

		markup_class.markup_root.text = parse_text (scanner);
		parse_attributes (scanner, markup_class.markup_root);
		parse_markup_subtags (scanner, markup_class.markup_root);
		
		markup_class.markup_root.generate_public_ast (this); 
		
	}
	
	string parse_identifier (string identifier) throws ParseError {
		return identifier;
	}

	void parse_using_directives (MarkupScanner scanner) throws ParseError {
		for (Ns* ns = scanner.node->ns_def; ns != null; ns = ns->next) {
			if (ns->href != scanner.gtkaml_uri) 
				parse_using_directive (scanner, ns->href);
		}
	}
	
	void parse_using_directive (MarkupScanner scanner, string ns) throws ParseError {
		var ns_sym = new UnresolvedSymbol (null, parse_identifier(ns), scanner.get_src ());
		var ns_ref = new UsingDirective (ns_sym, ns_sym.source_reference);
		scanner.source_file.add_using_directive (ns_ref);
		context.root.add_using_directive (ns_ref);
	}

	MarkupNamespace parse_namespace (MarkupScanner scanner) throws ParseError {
		MarkupNamespace ns = new MarkupNamespace (null, scanner.node->ns->href);
		ns.explicit_prefix = (scanner.node->ns->prefix != null);
		return ns;
	}
	
	void parse_attributes (MarkupScanner scanner, MarkupTag markup_tag) throws ParseError {
		for (Attr* attr = scanner.node->properties; attr != null; attr = attr->next) {
			if (attr->ns == null) {
				parse_attribute (markup_tag, attr->name, attr->children->content);
			} else {
				if (attr->ns->href == scanner.gtkaml_uri) {
					if (!parsetime_attributes.contains (attr->name)) {
						//TODO add them there
						Report.warning (scanner.get_src (), "Attribute %s:%s ingored".printf (attr->ns->prefix, attr->name));
					}
				} else {
					throw new ParseError.SYNTAX ("Attribute prefix not expected: %s".printf (attr->ns->href));
				} 
			}
		}
	}
	
	void parse_attribute (MarkupTag markup_tag, string name, string value) throws ParseError {
		string undername = name.replace ("-", "_");
		MarkupAttribute attribute = new MarkupAttribute (undername, value, markup_tag.source_reference);
		markup_tag.add_markup_attribute (attribute);
	}
	
	string parse_text (MarkupScanner scanner) throws ParseError {
		string text = "";
		for (Xml.Node* node = scanner.node->children; node != null; node = node->next)
		{
			if (node->type != ElementType.CDATA_SECTION_NODE && node->type != ElementType.TEXT_NODE) continue;//TODO break?
			text += node->content + "\n";
		}
		return text.chomp ();
	}
	
	void parse_markup_subtags (MarkupScanner scanner, MarkupTag parent_tag) throws ParseError {
		for (Xml.Node* node = scanner.node->children; node != null; node = node->next)
		{
			if (node->type != ElementType.ELEMENT_NODE) continue;
			
			scanner.node = node;
			if (scanner.node->ns->href == scanner.gtkaml_uri)
				parse_gtkaml_tag (scanner, parent_tag);
			else
				parse_markup_subtag(scanner, parent_tag);
		}
	}
	
	void parse_markup_subtag (MarkupScanner scanner, MarkupTag parent_tag) throws ParseError {
		MarkupChildTag markup_tag = null;
		SymbolAccessibility accessibility = SymbolAccessibility.PUBLIC;

		string identifier = parse_markup_subtag_identifier (scanner, ref accessibility);

		if (identifier != null) {
			markup_tag = new MarkupMember (parent_tag, scanner.node->name, parse_namespace (scanner), identifier, accessibility, scanner.get_src ());			
		} else {
			if (scanner.node->properties != null) { //has attributes
				markup_tag = new MarkupTemp (parent_tag, scanner.node->name, parse_namespace (scanner), scanner.get_src ());
			} else { 
				markup_tag = new MarkupUnresolvedTag (parent_tag, scanner.node->name, parse_namespace (scanner), scanner.get_src ());
			}
		}
		
		parent_tag.add_child_tag (markup_tag);
		parse_attributes (scanner, markup_tag);
		markup_tag.generate_public_ast (this);
		
		parse_markup_subtags (scanner, markup_tag);
	}
	
	string parse_markup_subtag_identifier (MarkupScanner scanner, ref SymbolAccessibility accessibility) throws ParseError
	{
		string identifier = null;
		
		foreach (var identifier_attribute in identifier_attributes) {
			if (scanner.node->get_ns_prop (identifier_attribute, scanner.gtkaml_uri) != null) {
				if (identifier != null) 
					throw new ParseError.SYNTAX ("Cannot specify more than one of: private, protected, internal, public");
				identifier = parse_identifier (scanner.node->get_ns_prop (identifier_attribute, scanner.gtkaml_uri));
				accessibility = (SymbolAccessibility)identifier_attributes.index_of (identifier_attribute);
			} 
		}		
		return identifier;
	}		

	void parse_gtkaml_tag (MarkupScanner scanner, MarkupTag parent_tag) {
		//TODO gtkaml:construct, preconstruct etc
		warning ("Igonring gtkaml tag %s".printf (scanner.node->name)); //TODO
	}
	
	void init_attribute_lists () {
		identifier_attributes = new ArrayList<string> (GLib.str_equal);
		identifier_attributes.add ("private");
		identifier_attributes.add ("internal");
		identifier_attributes.add ("protected");
		identifier_attributes.add ("public");
		
		classname_attributes = new ArrayList<string> (GLib.str_equal);
		classname_attributes.add ("public");
		classname_attributes.add ("internal");
		classname_attributes.add ("name");

		parsetime_attributes = new ArrayList<string> (GLib.str_equal);
		foreach (var a in identifier_attributes)
			parsetime_attributes.add (a);
		foreach (var a in classname_attributes)
			parsetime_attributes.add (a);
	}
		
}

