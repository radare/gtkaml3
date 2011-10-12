using GLib;
using Vala;

/**
 * Represents an attribute of a MarkupTag
 */
public class Gtkaml.Ast.MarkupAttribute {
	public DataType target_type { get; set; }
	public string attribute_name {get { return _attribute_name; }}
	public string? attribute_value {get; private set;}
	

	protected SourceReference? source_reference;
	protected string _attribute_name;
	protected Vala.Signal? @signal = null;

	public MarkupAttribute (string attribute_name, string? attribute_value, SourceReference? source_reference = null) {
		this._attribute_name = attribute_name;
		this.attribute_value = attribute_value;
		this.source_reference = source_reference;
	}

	public MarkupAttribute.with_type (string attribute_name, string? attribute_value, DataType target_type, SourceReference? source_reference = null) {
		this._attribute_name = attribute_name;
		this.attribute_value = attribute_value;
		this.target_type = target_type;
		this.source_reference = source_reference;
	}
	
	public virtual Expression? get_expression (MarkupResolver resolver, MarkupTag markup_tag) throws ParseError {
		resolve (resolver, markup_tag);
		
		string stripped_value = attribute_value.strip ();
		if (stripped_value.has_prefix ("{")) {
			if (stripped_value.has_suffix ("}")) {
				string code_source = stripped_value.substring (1, stripped_value.length - 2);
				if (@signal != null) {
					var stmts = resolver.code_parser.parse_statements (markup_tag.markup_class, markup_tag.me, attribute_name, code_source);
					var lambda = new LambdaExpression.with_statement_body(stmts, source_reference);

					lambda.add_parameter (new Vala.Parameter ("target", markup_tag.data_type, markup_tag.source_reference));
					foreach (var parameter in @signal.get_parameters ()) {
						lambda.add_parameter (parameter);
					}
		
					return lambda;
				} else {
					return resolver.code_parser.parse_expression (markup_tag.markup_class, markup_tag.me, attribute_name, code_source);
				}
			} else {
				Report.error (source_reference, "Unmatched closing brace in %'s value.".printf (attribute_name));
			}
		} else {
			if (@signal != null) {
				return resolver.code_parser.parse_expression (markup_tag.markup_class, markup_tag.me, attribute_name, stripped_value);
			} else {
				return generate_literal (stripped_value);
			}
		}
		return null;
	}

	public virtual Statement? get_assignment (MarkupResolver resolver, MarkupTag markup_tag) throws ParseError {
		resolve (resolver, markup_tag);

		Expression assignment;
		Expression? right_hand = get_expression (resolver, markup_tag);
		
		if (right_hand == null)
			return null;

		var parent_access = new MemberAccess.simple (markup_tag.me, source_reference);
		var attribute_access = new MemberAccess (parent_access, attribute_name, source_reference);
		
		if (@signal != null) {
			var connect_call = new MethodCall ( new MemberAccess (attribute_access, "connect", source_reference), source_reference);
			connect_call.add_argument (right_hand);
			assignment = connect_call;
			//assignment = new Assignment (attribute_access, get_expression (resolver, markup_tag), AssignmentOperator.ADD, source_reference);
		} else {
			assignment = new Assignment (attribute_access, right_hand, AssignmentOperator.SIMPLE, source_reference);
		}
		return new ExpressionStatement (assignment);
	}
	
	public virtual void resolve (MarkupResolver resolver, MarkupTag markup_tag) throws ParseError {

		assert (markup_tag.resolved_type is ObjectType);
		var cl = ((ObjectType)markup_tag.resolved_type).type_symbol;
		
		Symbol? resolved_attribute = resolver.search_symbol (cl, attribute_name);
		
		if (resolved_attribute is Property) {
			target_type = ((Property)resolved_attribute).property_type.copy ();
		} else if (resolved_attribute is Field) {
			target_type = ((Field)resolved_attribute).variable_type.copy ();
		} else if (resolved_attribute is Vala.Signal) {
			@signal = (Vala.Signal)resolved_attribute;
		} else {
			//TODO: it's a parameter for add/create .. maybe
		}
	}
	
	protected Expression? generate_literal (string stripped_value) {
		assert (target_type != null);
		var type_name = target_type.data_type.get_full_name ();
		if (type_name == "string") {
			return new StringLiteral ("\"" + attribute_value.replace ("\"", "\\\"") + "\"", source_reference);
		} else if (type_name == "bool") {
			//TODO: full boolean check 
			return new BooleanLiteral (attribute_value == "true", source_reference);
		} else if (type_name == "int" || type_name == "uint") {
			return new IntegerLiteral (attribute_value, source_reference);
		} else if (type_name == "double" || type_name == "float") {
			return new RealLiteral (attribute_value, source_reference);
		} else if (target_type is ReferenceType && stripped_value == "null") {
			return new NullLiteral (source_reference);
		} else {
			//TODO enum here too
			Report.error (source_reference, "Error: attribute literal of '%s' type found\n".printf (target_type.data_type.get_full_name ()));
			return null;
		} 
	}
	
}

