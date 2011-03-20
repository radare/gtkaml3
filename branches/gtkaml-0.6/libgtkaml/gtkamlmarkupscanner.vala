using Vala;
using Xml;

/** 
 * Wrapper for Xml document
 */
public class Gtkaml.MarkupScanner {
	public string gtkaml_uri {get; protected set;}
	public Xml.Node* node;
	public SourceFile source_file {get; protected set;}
	Doc* whole_doc;

	public MarkupScanner (SourceFile source_file) throws ParseError {
		this.whole_doc = null;
		this.source_file = source_file;
		
		this.whole_doc = Xml.Parser.read_file (source_file.filename, null, ParserOption.NOWARNING);
		if (whole_doc == null) 
			throw new ParseError.SYNTAX("Error parsing %s".printf (source_file.filename));
		
		node = whole_doc->get_root_element ();
		
		parse_gtkaml_uri ();
	}

	~MarkupScanner () {
		if (whole_doc != null)
			delete whole_doc;
	}
	
	public SourceReference get_src () {
		return new SourceReference (source_file, (int)node->get_line_no (), 0,
			(int)node->get_line_no (), 0);
	}


	void parse_gtkaml_uri () throws ParseError {
		for (Ns* ns = this.node->ns_def; ns != null; ns = ns->next) {
			if (ns->href.has_prefix ("http://gtkaml.org")) {
				this.gtkaml_uri = ns->href;
				return;
			}
		}
		throw new ParseError.SYNTAX ("No gtkaml prefix found.");
	}


}
