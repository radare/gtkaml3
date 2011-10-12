using Vala;
using Gtkaml;

/**
 * common interface between resolver and parser: to be able to parse Vala code
 */
public interface Gtkaml.CodeParserProvider : CodeVisitor {

	public abstract ValaParser code_parser {get;protected set;}
}

