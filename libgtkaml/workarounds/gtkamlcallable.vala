/* gtkamlcallable.vala
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
 * wrapper for Method and Signal.
 * Supports .name and .get_parameters
 */

public class Gtkaml.Callable {
	
	public Symbol member {get; private set;}
	
	public Callable (Symbol member) {
		assert (member is Vala.Signal || member is Method);
		this.member = member;
	}
	
	public Vala.List<Vala.Parameter> get_parameters ()
	{
		if (member is Method)
			return ((Method)member).get_parameters ();
		return ((Vala.Signal)member).get_parameters ();
	}
	
	public string name { get { return member.name; } }
	
	public Symbol? parent_symbol { get { return member.parent_symbol; } }
}
