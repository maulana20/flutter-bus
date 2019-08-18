import 'package:flutter/foundation.dart';

class Terminal extends Object {
	int terminal_id;
	String terminal_name;
	
	Terminal({this.terminal_id, this.terminal_name});
	
	factory Terminal.fromJson(Map<String, dynamic> json) {
		return Terminal(
			terminal_id: json['terminal_id'],
			terminal_name: json['terminal_name'],
		);
	}
}
