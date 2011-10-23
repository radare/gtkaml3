/* gtkamlcodecontext.vala
 *
 * Copyright (C) 2011 Vlad Grecescu
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with main.c; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor Boston, MA 02110-1301,  USA
 *
 * Author:
 *        Vlad Grecescu (b100dian@gmail.com)
 */
using Vala;

/**
 * Hides .check () from Vala.CodeContext with our implementation
 */
public class Gtkaml.CodeContext : Vala.CodeContext {

	public MarkupResolver markup_resolver { get; private set; }
	public new SymbolResolver resolver { get { return markup_resolver; } } //TODO warning this just hides the SymbolResolver
	
	public CodeContext () {
		base ();
		markup_resolver = new MarkupResolver ();
	}

	public new void check () { //TODO warning this just hides the check () method
		markup_resolver.resolve (this);

		if (report.get_errors () > 0) {
			return;
		}

		analyzer.analyze (this);

		if (report.get_errors () > 0) {
			return;
		}

		flow_analyzer.analyze (this);
	}
	
	public string get_markuphints_path (string pkg) {
		var vapi_hint = get_file_path (pkg + ".markuphints", null, "gtkaml/markuphints", vapi_directories);
		return vapi_hint;
	}
	
	//TODO this just duplicates vala code
	string? get_file_path (string basename, string? versioned_data_dir, string? data_dir, string[] directories) {
		string filename = null;

		if (directories != null) {
			foreach (string dir in directories) {
				filename = Path.build_path ("/", dir, basename);
				if (FileUtils.test (filename, FileTest.EXISTS)) {
					return filename;
				}
			}
		}

		if (versioned_data_dir != null) {
			foreach (string dir in Environment.get_system_data_dirs ()) {
				filename = Path.build_path ("/", dir, versioned_data_dir, basename);
				if (FileUtils.test (filename, FileTest.EXISTS)) {
					return filename;
				}
			}
		}

		if (data_dir != null) {
			foreach (string dir in Environment.get_system_data_dirs ()) {
				filename = Path.build_path ("/", dir, data_dir, basename);
				if (FileUtils.test (filename, FileTest.EXISTS)) {
					return filename;
				}
			}
		}

		return null;
	}

}
