using GLib;
using Vala;
using Xml;

public class Gtkaml.MarkupParser : CodeVisitor {

	private Vala.CodeContext context;
	public ValaParser vala_parser;

	public void parse (Vala.CodeContext context) {
		this.context = context;
		this.vala_parser = new ValaParser ();
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
			} else
			if (attr->ns->href != scanner.gtkaml_uri) {
				throw new ParseError.SYNTAX ("Attribute prefix not expected: %s".printf (attr->ns->href));
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
		string identifier = null;
		
		if (scanner.node->get_ns_prop ("public", scanner.gtkaml_uri) != null) {
			identifier = parse_identifier (scanner.node->get_ns_prop ("public", scanner.gtkaml_uri));
			markup_tag = new MarkupMember (parent_tag, scanner.node->name, parse_namespace (scanner), identifier, SymbolAccessibility.PUBLIC, scanner.get_src ());
		}  
		
		if (scanner.node->get_ns_prop ("private", scanner.gtkaml_uri) != null) {
			if (identifier != null) 
				throw new ParseError.SYNTAX ("Cannot specify both private and public");
			identifier = parse_identifier (scanner.node->get_ns_prop ("private", scanner.gtkaml_uri));
			markup_tag = new MarkupMember (parent_tag, scanner.node->name, parse_namespace (scanner), identifier, SymbolAccessibility.PRIVATE, scanner.get_src ());
		} 
		
		if (markup_tag == null) {
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

	void parse_gtkaml_tag (MarkupScanner scanner, MarkupTag parent_tag) {
		message ("found gtkaml tag %s".printf (scanner.node->name)); //TODO
	}
	

}

