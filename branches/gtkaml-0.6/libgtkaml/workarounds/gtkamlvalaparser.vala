using GLib;
using Vala;

public class Gtkaml.ValaParser {
	private Vala.List<SourceFile> temp_source_files = new Vala.ArrayList<SourceFile> ();

	public Class parse_members (string class_name, string members_source) throws ParseError  {
		var temp_source = "public class Temp { %s }".printf (members_source);
		
		var temp_ns = parse (temp_source, class_name + "-members");
		if (temp_ns is Namespace && temp_ns.get_classes ().size == 1) {
			return temp_ns.get_classes ().get (0);
		} else {
			throw new ParseError.SYNTAX ("There was an error parsing the code section.");
		}
	}
	
	public Expression parse_expression (string class_name, string target, string target_member, string expression_source) throws ParseError {
		var temp_source = "VoidFunc voidFunc = ()=> %s;".printf (expression_source);
		
		var temp_ns = parse (temp_source, class_name + "_" + target + "_" + target_member + "_expression");
		if (temp_ns is Namespace && temp_ns.get_fields ().size == 1 && temp_ns.get_fields ().get (0).initializer is LambdaExpression) {
			var temp_lambda = (LambdaExpression)temp_ns.get_fields ().get (0).initializer;
			return temp_lambda.expression_body;
		} else {
			throw new ParseError.SYNTAX ("There was an error parsing the code section.");
		}
	}
	
	public Block parse_statements (string class_name, string target, string target_member, string statements_source) throws ParseError {
		var temp_source = "VoidFunc voidFunc = ()=> {%s};".printf (statements_source);
		
		var temp_ns = parse (temp_source, class_name + "_" + target + "_" + target_member + "_expression");
		if (temp_ns is Namespace && temp_ns.get_fields ().size == 1 && temp_ns.get_fields ().get (0).initializer is LambdaExpression) {
			var temp_lambda = (LambdaExpression)temp_ns.get_fields ().get (0).initializer;
			return temp_lambda.statement_body;
		} else {
			throw new ParseError.SYNTAX ("There was an error parsing the code section.");
		}
	}

	/**
	 * parses a vala source string temporary stored in .gtkaml/what.vala
	 * returns the root namespace
	 */
	private Namespace parse(string source, string temp_filename) throws ParseError {
		var ctx = new CodeContext ();
		var filename = ".gtkaml/" + temp_filename + ".vala";
		
		try {
			DirUtils.create_with_parents (".gtkaml", 488 /*0750*/);
			FileUtils.set_contents (filename, source);
			var temp_source_file = new SourceFile (ctx, SourceFileType.SOURCE, filename, source);
			temp_source_files.add (temp_source_file);
			ctx.add_source_file (temp_source_file);
		
			var parser = new Vala.Parser ();
			parser.parse (ctx);
			return ctx.root;
		} catch {
			throw new ParseError.FAILED ("There was an error writing temporary '%s'".printf (filename));
		}
	}


}
