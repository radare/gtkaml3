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

	Vala.List<string> identifier_gtkamlattributes;
	Vala.List<string> classname_gtkamlattributes;
	Vala.List<string> parsed_gtkamlattributes;

	
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
		SymbolAccessibility access = SymbolAccessibility.PUBLIC;
		string class_name = null;
		
		foreach (var classname_attribute in classname_gtkamlattributes) {
			if (scanner.node->get_ns_prop (classname_attribute, scanner.gtkaml_uri) != null)
			{
				if (class_name != null) throw new ParseError.SYNTAX	("Cannot specify more than one of: internal, public, name");
				class_name = parse_identifier (scanner.node->get_ns_prop (classname_attribute, scanner.gtkaml_uri));
				switch (classname_gtkamlattributes.index_of (classname_attribute)) {
					case 0: access = SymbolAccessibility.PUBLIC;break;
					case 1: access = SymbolAccessibility.INTERNAL;break;
					case 2: access = SymbolAccessibility.PUBLIC;break;
				}
			}
		}

		string base_name = parse_identifier (scanner.node->name);

		MarkupClass markup_class = new MarkupClass (base_name, base_ns, class_name, scanner.get_src ());

		markup_class.access = access;

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
					if (!parsed_gtkamlattributes.contains (attr->name)) {
						switch (attr->name) {
							case "construct":
								parse_construct (markup_tag, attr->children->content);
								break;
							case "preconstruct":
								parse_preconstruct (markup_tag, attr->children->content);
								break;
							default:
								Report.warning (scanner.get_src (), "Attribute %s:%s ignored".printf (attr->ns->prefix, attr->name));
								break;
						}
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
			if (node->type != ElementType.CDATA_SECTION_NODE && node->type != ElementType.TEXT_NODE) 
				continue;//TODO break?
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
		string reference = parse_markup_subtag_reference (scanner);

		if (identifier != null) {
			if (reference != null)
				throw new ParseError.SYNTAX ("Cannot specify both an existing identifier and a new one");
			markup_tag = new MarkupMember (parent_tag, scanner.node->name, parse_namespace (scanner), identifier, accessibility, scanner.get_src ());
		} else if (reference != null) {
			markup_tag = new MarkupReference (parent_tag, scanner.node->name, parse_namespace (scanner), reference, scanner.get_src ());
		} else {
			if (scanner.node->properties != null) { //has attributes
				markup_tag = new MarkupTemp (parent_tag, scanner.node->name, parse_namespace (scanner), scanner.get_src ());
			} else { 
				markup_tag = new MarkupUnresolvedTag (parent_tag, scanner.node->name, parse_namespace (scanner), scanner.get_src ());
			}
		}
		
		markup_tag.standalone = parse_markup_subtag_is_standalone (scanner);
		
		parent_tag.add_child_tag (markup_tag);
		parse_attributes (scanner, markup_tag);
		markup_tag.generate_public_ast (this);
		
		parse_markup_subtags (scanner, markup_tag);
	}
	
	string? parse_markup_subtag_identifier (MarkupScanner scanner, ref SymbolAccessibility accessibility) throws ParseError {
		
		string identifier = null;
		
		foreach (var identifier_attribute in identifier_gtkamlattributes) {
			if (scanner.node->get_ns_prop (identifier_attribute, scanner.gtkaml_uri) != null) {
				if (identifier != null) 
					throw new ParseError.SYNTAX ("Cannot specify more than one of: private, protected, internal, public");
				identifier = parse_identifier (scanner.node->get_ns_prop (identifier_attribute, scanner.gtkaml_uri));
				accessibility = (SymbolAccessibility)identifier_gtkamlattributes.index_of (identifier_attribute);
			} 
		}		
		return identifier;
	}		

	bool parse_markup_subtag_is_standalone (MarkupScanner scanner) throws ParseError {
		string standalone = scanner.node->get_ns_prop ("standalone", scanner.gtkaml_uri);
		if (standalone == null || standalone == "false") {
			return false;
		} else {
			if (standalone == "true")
				return true;
			else 
				throw new ParseError.SYNTAX ("Invalid value for standalone : '%s'".printf (standalone));
		}
	}		

	string? parse_markup_subtag_reference (MarkupScanner scanner) throws ParseError {
		string reference = scanner.node->get_ns_prop ("existing", scanner.gtkaml_uri);
		if (reference != null) {
			return parse_identifier (reference);
		} else {
			return null;
		}
	}		

	void parse_gtkaml_tag (MarkupScanner scanner, MarkupTag parent_tag) throws ParseError {
		switch (scanner.node->name) {
			case "construct":
				parse_construct (parent_tag, parse_text (scanner));
				break;
			case "preconstruct":
				parse_preconstruct (parent_tag, parse_text (scanner));
				break;
			default:
				Report.warning (parent_tag.source_reference, "Ignoring gtkaml tag %s".printf (scanner.node->name));
				break;
		}
	}
	
	void parse_construct (MarkupTag markup_tag, string construct_body) throws ParseError {
		if (markup_tag.construct_text != null) {
			throw new ParseError.SYNTAX ("Duplicate `construct' definition on %s".printf (markup_tag.me));
		} else {
			markup_tag.construct_text = construct_body;
		}
	}

	void parse_preconstruct (MarkupTag markup_tag, string preconstruct_body) throws ParseError {
		if (markup_tag.preconstruct_text != null) {
			throw new ParseError.SYNTAX ("Duplicate `preconstruct' definition on %s".printf (markup_tag.me));
		} else {
			markup_tag.preconstruct_text = preconstruct_body;
		}
	}
	
	void init_attribute_lists () {
		identifier_gtkamlattributes = new ArrayList<string> (GLib.str_equal);
		identifier_gtkamlattributes.add ("private");
		identifier_gtkamlattributes.add ("internal");
		identifier_gtkamlattributes.add ("protected");
		identifier_gtkamlattributes.add ("public");
		
		classname_gtkamlattributes = new ArrayList<string> (GLib.str_equal);
		classname_gtkamlattributes.add ("name");
		classname_gtkamlattributes.add ("internal");
		classname_gtkamlattributes.add ("public");

		parsed_gtkamlattributes = new ArrayList<string> (GLib.str_equal);

		foreach (var a in identifier_gtkamlattributes)
			parsed_gtkamlattributes.add (a);

		foreach (var a in classname_gtkamlattributes)
			parsed_gtkamlattributes.add (a);

		parsed_gtkamlattributes.add ("existing");
		parsed_gtkamlattributes.add ("standalone");

	}
		
}

