import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'bus/bus_page.dart';
import 'bus/bloc/search_bloc.dart';

import '../model/terminal.dart';
import '../api/terminal_lookup.dart';

class BusScreen extends StatefulWidget {
	@override
	_BusScreenState createState() => _BusScreenState();
}

class _BusScreenState extends State<BusScreen> {
	List<Terminal> terminals = new List();
	
	Future getTerminal() async {
		final start = DateTime.now();
		
		final response = await TerminalDataReader.load('assets/data/terminal_data.json');
		
		terminals.clear();
		terminals.addAll(response);
		
		final elapsed = DateTime.now().difference(start);
		print('Loaded terminals data in $elapsed');
	}
	
	void initState() {
		super.initState();
		getTerminal();
	}
	
	@override
	Widget build(BuildContext context) {
		return StatefulProvider<SearchBloc>(
			valueBuilder: (context) => SearchBloc(),
			onDispose: (context, bloc) => bloc.dispose(),
			child: BusPage(terminalLookup: TerminalLookup(terminals: terminals)),
		);
	}
}

class TerminalDataReader {
	static Future<List<Terminal>> load(String path) async {
		final data = await rootBundle.loadString(path);
		
		return json.decode(data).map<Terminal>((json) => Terminal.fromJson(json)).toList();
	}
}
