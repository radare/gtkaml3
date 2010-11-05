using Vala;
using Xml;

/** 
 * Wrapper for Xml document
 */
public class Gtkaml.MarkupScanner {
	public string gtkaml_uri;
	Doc* whole_doc;
	public Xml.Node* node;
	public SourceFile source_file;

	public MarkupScanner (SourceFile source_file) throws ParseError {
		this.whole_doc = null;
		this.source_file = source_file;
		
		this.whole_doc = Xml.Parser.read_file (source_file.filename, null, ParserOption.NOWARNING);
		if (whole_doc == null) 
			throw new ParseError.SYNTAX("Error parsing %s".printf (source_file.filename));
		node = whole_doc->get_root_element ();
	}

	~MarkupScanner () {
		if (whole_doc != null)
			delete whole_doc;
	}
	
	public SourceReference get_src () {
		return new SourceReference (source_file, (int)node->get_line_no (), 0,
			(int)node->get_line_no (), 0);
	}


}
