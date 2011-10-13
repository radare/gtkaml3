using Vala;
using Gtkaml;

/**
 * common interface between resolver and parser: to provide a parser of Vala code
 */
public interface Gtkaml.CodeParserProvider : CodeVisitor {

	public abstract ValaParser code_parser {get;protected set;}
}

