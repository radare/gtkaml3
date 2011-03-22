using GLib;
using Vala;

/**
 * Represents an attribute of a MarkupTag
 */
public class Gtkaml.MarkupAttribute {
	public string attribute_name {get { return _attribute_name; }}
	public DataType target_type { get; set; }

	private SourceReference? source_reference;
	private string _attribute_name;
	private Vala.Signal? _signal = null;

	public string? attribute_value {get; private set;}
	
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
	
	public virtual Expression get_expression (MarkupResolver resolver, MarkupTag markup_tag) throws ParseError {
		resolve (resolver, markup_tag);
		
		string stripped_value = attribute_value.strip ();
		if (stripped_value.has_prefix ("{")) {
			if (stripped_value.has_suffix ("}")) {
				string code_source = stripped_value.substring (1, stripped_value.length - 2);
				if (_signal != null) {
					var stmts = resolver.vala_parser.parse_statements (markup_tag.markup_class, markup_tag.me, attribute_name, code_source);
					var lambda = new LambdaExpression.with_statement_body(stmts, source_reference);

					lambda.add_parameter ("target");
					foreach (var parameter in _signal.get_parameters ()) {
						lambda.add_parameter (parameter.name);
					}
					
					return lambda;
				} else {
					return resolver.vala_parser.parse_expression (markup_tag.markup_class, markup_tag.me, attribute_name, code_source);
				}
			} else {
				Report.error (source_reference, "Unmatched closing brace in %'s value.".printf (attribute_name));
			}
		} else {
			if (_signal != null) {
				Expression symbol_access = null;
				foreach (var symbol in stripped_value.split ("."))
					symbol_access = new MemberAccess (symbol_access, symbol, source_reference);
				return symbol_access;
			} else {
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
					Report.error (source_reference, "Error: attribute literal of '%s' type found\n".printf (target_type.data_type.get_full_name ()));
				} 
				//TODO enum here too
			}
		}
		assert_not_reached ();//TODO remove this?
	}

	public virtual Statement get_assignment (MarkupResolver resolver, MarkupTag markup_tag) throws ParseError {
		resolve (resolver, markup_tag);

		var parent_access = new MemberAccess.simple (markup_tag.me, source_reference);
		var attribute_access = new MemberAccess (parent_access, attribute_name, source_reference);
		Expression assignment;
		if (_signal != null) {
			var connect_call = new MethodCall ( new MemberAccess (attribute_access, "connect", source_reference), source_reference);
			connect_call.add_argument (get_expression (resolver, markup_tag));
			assignment = connect_call;
			//assignment = new Assignment (attribute_access, get_expression (resolver, markup_tag), AssignmentOperator.ADD, source_reference);
		} else {
			assignment = new Assignment (attribute_access, get_expression (resolver, markup_tag), AssignmentOperator.SIMPLE, source_reference);
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
			_signal = (Vala.Signal)resolved_attribute;
		} else {
			//TODO: it's a parameter for add/create .. maybe
		}
	}

}

