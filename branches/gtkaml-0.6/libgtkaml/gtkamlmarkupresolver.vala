using GLib;
using Vala;

/**
 * Gtkaml SymbolResolver's  responsibilities:
 * * determine if an attribute is a field or a signal and use = or += appropiately
 * Literal attribute values:
 * * determine the type of the literal field attribute (boolean, string and enum)
 * * determine the method reference for the literal signal attribute
 * Expression attribute values:
 * * signals: use the result of lambda parsing add the signal parameters
 * * fields: use the expression of the lambda as field assignment
 */
public class Gtkaml.MarkupResolver : SymbolResolver {

	public MarkupHintsStore markup_hints;
	public ValaParser vala_parser;

	internal CodeContext context {get; set;}

	public void resolve (CodeContext context) {
		markup_hints = new MarkupHintsStore (context);
		vala_parser = new ValaParser (context);
		markup_hints.parse ();
		this.context = context;
		base.resolve (context);
	}

	public override void visit_class (Class cl) {
		if (cl is MarkupClass) {
			visit_markup_class (cl as MarkupClass);
		}
		base.visit_class (cl);
	}
	
	public void visit_markup_class (MarkupClass mcl) {
		try {
			resolve_markup_tag (mcl.markup_root);
			generate_markup_tag (mcl.markup_root);
		} catch (ParseError e) {
			Report.error (null, e.message);
		}
	}
	
	public Symbol? search_symbol (ObjectTypeSymbol type, string sym_name)
	{
		Symbol? sym = type.scope.lookup (sym_name);
		if (sym == null) {
			Vala.List<DataType> base_types;
			if (type is Class) {
				base_types = ((Class)type).get_base_types();
			} else {
				return null;
			} 
			foreach (var base_type in base_types){
				if (base_type is ClassType) {
					sym = search_symbol (((ClassType)base_type).class_symbol, sym_name);
				} else if (base_type is InterfaceType) {
					sym = search_symbol (((InterfaceType)base_type).interface_symbol, sym_name);
				} else if (base_type is ObjectType) {
					sym = search_symbol (((ObjectType)base_type).type_symbol, sym_name);
				}
				if (sym != null) break;
			}
		}
		return sym;
	}
	
	/**
	 * processes tag hierarchy. Removes unresolved ones after this step
	 */
	public bool resolve_markup_tag (MarkupTag markup_tag) throws ParseError {
		//resolve first
		MarkupTag? resolved_tag = markup_tag.resolve (this);
		
		if (resolved_tag != null) {
			Vala.List<MarkupChildTag> to_remove = new Vala.ArrayList<MarkupChildTag> ();

			//recurse
			foreach (var child_tag in resolved_tag.get_child_tags ()) {
				if (false == resolve_markup_tag (child_tag)) {
					to_remove.add (child_tag);
				}
			}
		
			foreach (var remove in to_remove)
				resolved_tag.remove_child_tag (remove);
				
			//attributes last
			resolved_tag.resolve_attributes (this);
		}		
		return resolved_tag != null;
	}

	private void generate_markup_tag (MarkupTag markup_tag) throws ParseError {
		markup_tag.generate (this);
		foreach (MarkupTag child_tag in markup_tag.get_child_tags ())
			generate_markup_tag (child_tag);
		markup_tag.generate_attributes (this);
	}
		
	public Vala.List<MarkupAttribute> get_default_parameters (string full_type_name, Callable m, SourceReference? source_reference = null) {
		var parameters = new Vala.ArrayList<MarkupAttribute> ();
		var hint = markup_hints.markup_hints.get (full_type_name);
		if (hint != null) {
			Vala.List <Pair<string, string?>> parameter_hints = hint.get_creation_method_parameters (m.name);
			if (parameter_hints == null) parameter_hints = hint.get_composition_method_parameters (m.name); //FIXME this if is disturbing
			#if DEBUGMARKUPHINTS
			stderr.printf ("Found %d parameters\n", parameter_hints.size);
			#endif
			if (parameter_hints != null && parameter_hints.size != 0) {
				assert (parameter_hints.size == m.get_parameters ().size);
				//actual merge. with two parralell foreaches
				int i = 0;
				foreach (var formal_parameter in m.get_parameters ()) {
					assert ( i < parameter_hints.size );
					var parameter = new MarkupAttribute.with_type ( parameter_hints.get (i).name, parameter_hints.get (i).value, formal_parameter.variable_type, source_reference );
					parameters.add (parameter);
					i++;
				}
				return parameters;
			}
		}
		foreach (var formal_parameter in m.get_parameters ()) {
			var parameter = new MarkupAttribute.with_type ( formal_parameter.name, null, formal_parameter.variable_type );
			parameters.add (parameter);
		}
		return parameters;
	}	

	public Vala.List<Callable> get_composition_method_candidates (TypeSymbol parent_tag_symbol) {
		Vala.List<Callable> candidates = new Vala.ArrayList<Callable> ();
		#if DEBUGMARKUPHINTS
		stderr.printf ("Searching for composition method candidates for %s\n", parent_tag_symbol.get_full_name ());
		#endif
		var hint = markup_hints.markup_hints.get (parent_tag_symbol.get_full_name ());
		if (hint != null) {
			Vala.List<string> names = hint.get_composition_method_names ();
			foreach (var name in names) {
				Symbol? m = search_method_or_signal (parent_tag_symbol, name);
				if (m == null) {
					Report.error (null, "Invalid composition method hint: %s does not belong to %s".printf (name, parent_tag_symbol.get_full_name ()) );
				} else {
					#if DEBUGMARKUPHINTS
					stderr.printf (" FOUND!\n");
					#endif
					candidates.add (new Callable(m));
				}
			}
		}
		if (parent_tag_symbol is Class) {
			Class parent_class = (Class)parent_tag_symbol;
			if (parent_class.base_class != null)
				foreach (var m in get_composition_method_candidates (parent_class.base_class))
					candidates.add (m);
			foreach (var base_type in parent_class.get_base_types ())
				foreach (var m in get_composition_method_candidates (base_type.data_type))
					candidates.add (m);
		} 
		return candidates;
	}
	
	/** returns method or signal */
	private Symbol? search_method_or_signal (TypeSymbol type, string name) {
		#if DEBUGMARKUPHINTS
		stderr.printf ("\rsearching %s in %s..", name, type.name);
		#endif
		if (type is Class) {
			Class class_type = (Class)type;
			foreach (var m in class_type.get_methods ())
				if (m.name == name) return m;
			foreach (var s in class_type.get_signals ())
				if (s.name == name) return s;
			if (class_type.base_class != null) {
				Symbol? m = search_method_or_signal (class_type.base_class, name);
				if (m != null) return m;
			}
			foreach (var base_type in class_type.get_base_types ()) {
				Symbol? m = search_method_or_signal (base_type.data_type, name);
				if (m != null) return m;
			}
		} else
		if (type is Interface) {
			Interface interface_type = type as Interface;
			foreach (var m in interface_type.get_methods ())
				if (m.name == name) return m;
			foreach (var s in interface_type.get_signals ())
				if (s.name == name) return s;
		} else
			assert_not_reached ();
		return null;
	}
	
}
