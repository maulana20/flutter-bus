import 'dart:convert';

import 'package:flutter/material.dart';

import 'screen/bus_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			title: 'Flutter Bus',
			theme: ThemeData(
				primarySwatch: Colors.blue,
			),
			home: BusScreen(),
		);
	}
}
