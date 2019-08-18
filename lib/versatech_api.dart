import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

import 'model/terminal.dart';

void main() async {
	final JsonDecoder _decoder = new JsonDecoder();
	
	List<Terminal> _terminals = new List();
	
	Future<Terminal> terminal() async {
		final response = await rootBundle.loadString('assets/data/terminal_data.json');
		
		var terminal = json.decode(response).map<Terminal>((json) => Terminal.fromJson(json)).toList();
		
		_terminals.clear();
		_terminals.addAll(terminal);
	}
	
	await terminal();
	for (final data in _terminals) {
		print(data.terminal_name);
	} 
}
