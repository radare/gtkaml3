using GLib;
using Vala;

/*
 * MarkupChildTag is a MarkupTag that has itself a parent: 
 * parent_tag, and g:existing, g:standalone, g:construct, g:private etc.
 */
public abstract class Gtkaml.Ast.MarkupChildTag : MarkupTag {

	public weak MarkupTag parent_tag {get;set;}

	/**
	 * Attributes explicitly found as composition parameters + default ones.
	 * All in the original order.
	 */
	public Vala.List<MarkupAttribute> composition_parameters = new Vala.ArrayList<MarkupAttribute> ();

	/**
	 * resolved composition method
	 */
	public Callable composition_method;

	public MarkupChildTag (MarkupTag parent_tag, string tag_name, MarkupNamespace tag_namespace, SourceReference? source_reference) {
		base (parent_tag.markup_class, tag_name, tag_namespace, source_reference);
		this.parent_tag = parent_tag;
	}

	public override void resolve_attributes (MarkupResolver resolver) throws ParseError {
		resolve_creation_method (resolver);
		resolve_composition_method (resolver);
	}

	void resolve_composition_method (MarkupResolver resolver) {
		var candidates = resolver.get_composition_method_candidates (this.parent_tag.resolved_type.data_type as TypeSymbol);
		
		//trim the list down to the explicit one, present with value = "true"
		foreach (var candidate in candidates) {
			var explicit = get_attribute (candidate.name);
			if (explicit is MarkupAttribute && ((MarkupAttribute)explicit).attribute_value == "true") {
				remove_attribute (explicit);
				candidates = new Vala.ArrayList<Callable> ();
				candidates.add (candidate);
				break;//before foreach complains
			}
		}
		
		
		if (candidates.size == 0) {
			Report.error (source_reference, "No composition methods found for adding %s to a %s".printf (full_name, parent_tag.full_name));
			return;
		}
		//go through each method, updating max&max_match_method if it matches and min&min_match_method otherwise
		//so that we know the best match method, if found, otherwise the minimum number of arguments to specify

		int min = 100; Callable min_match_method = candidates.get (0);
		int max = -1; Callable max_match_method = candidates.get (0);
		MarkupAttribute max_self = new MarkupAttribute ("not-intialized-warning-was-true",null);
		Vala.List<MarkupAttribute> matched_method_parameters = new Vala.ArrayList<MarkupAttribute> ();
		
		var i = 0;
		
		do {
			var current_candidate = candidates.get (i);
			
			MarkupAttribute self;
			if (current_candidate.get_parameters ().size == 0) {
				Report.warning (null, "%s composition method has no parameters".printf (current_candidate.name));
				continue;
			}

			var parameters = resolver.get_default_parameters (current_candidate.parent_symbol.get_full_name (), current_candidate, source_reference);
			int matches = 0;

			self = new MarkupAttribute (parameters.get(0).attribute_name, "{"+me+"}", source_reference);
			add_markup_attribute (self);

			foreach (var parameter in parameters) {
				if ( (null != get_attribute (parameter.attribute_name)) || parameter.attribute_value != null) {
					matches ++;
				}
			}

			#if DEBUGMARKUPHINTS
			stderr.printf ("comparing %s %d parameters with %d matches\n", current_candidate.name, parameters.size, matches);
			#endif
			
			if (matches < parameters.size) {  //does not match
				if (parameters.size < min) {
					min = parameters.size;
					min_match_method = current_candidate;
				}
			} else {
				assert (matches == parameters.size);
				if (parameters.size > max) {
					max = parameters.size;
					max_self = self;
					max_match_method = current_candidate;
					matched_method_parameters = parameters;
				}
			}

			i++;
			
			remove_attribute (self);
		} while ( i < candidates.size );

		if (max_match_method.get_parameters ().size == max) { 
			this.composition_method = max_match_method;
			add_markup_attribute (max_self);
			//save the CreationMethodParameters:
			foreach (var parameter in matched_method_parameters) {
				MarkupAttribute explicit_attribute = null;
				if (null != (explicit_attribute = get_attribute (parameter.attribute_name))) {
					//for the explicit ones, copy the data type from the default attribute
					explicit_attribute.target_type = parameter.target_type;
					this.composition_parameters.add (explicit_attribute);
					remove_attribute (explicit_attribute);
				} else {
					//for the default ones, include the default attribute
					this.composition_parameters.add (parameter);
				}
			}
		} else {
			var required = "";
			var parameters = min_match_method.get_parameters ();
			i = 0;
			for (; i < parameters.size - 1; i++ ) {
				required += "'" + parameters[i].name + "',";
			}
			required += "'" + parameters[i].name + "'";
			Report.error (source_reference, "at least %s required for composing %s into %s using %s () .".printf (required, full_name, parent_tag.full_name, min_match_method.name));
		}
	}

	/**
	 * returns the list of possible creation methods, containing a single element if explicitly requested
	 */
	internal override Vala.List<CreationMethod> get_creation_method_candidates () {
		var candidates = base.get_creation_method_candidates ();
		
		//for subtags: one of the creation method's name is present with the value "true"
		foreach (var candidate in candidates) {
			var explicit = get_attribute (candidate.name);
			if (explicit is MarkupAttribute && ((MarkupAttribute)explicit).attribute_value == "true") {
				remove_attribute (explicit);
				candidates = new Vala.ArrayList<CreationMethod> ();
				candidates.add (candidate);
				break;//before foreach complains
			}
		}

		return candidates;
	}

	protected ObjectCreationExpression get_initializer (MarkupResolver resolver) throws ParseError 
	{
		var creation_method_access = get_class_expression ();
		creation_method_access = new MemberAccess (creation_method_access, creation_method.name, source_reference);
		creation_method_access.creation_member = true;
		
		var initializer = new ObjectCreationExpression (creation_method_access, source_reference);
		
		//TODO: determine the initialize to call from MarkupHintsStore
		foreach (var parameter in creation_parameters) {
			initializer.add_argument (parameter.get_expression (resolver, this));
		}
		
		DataType variable_type = resolved_type.copy ();
		variable_type.value_owned = true;
		variable_type.nullable = false;
		variable_type.is_dynamic = false;

		return initializer;
	}

	protected void generate_add (MarkupResolver resolver) throws ParseError 
	{
		var parent_member = new MemberAccess.simple (parent_tag.me, parent_tag.source_reference);
		var method_call = new MethodCall (new MemberAccess (parent_member, composition_method.name, source_reference));
		
		foreach (MarkupAttribute attr in composition_parameters) {
			method_call.add_argument (attr.get_expression (resolver, this));
		}
		
		markup_class.constructor.body.add_statement (new ExpressionStatement (method_call, source_reference));
	}

}
