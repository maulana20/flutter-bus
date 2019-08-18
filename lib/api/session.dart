import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class Session {
	final JsonDecoder _decoder = new JsonDecoder();
	Map<String, String> headers = {};
	
	Future<Map> get(String url) async {
		http.Response response = await http.get(url, headers: headers);
		print('Response ' + url.split('/')[4] + (url.split('/').length > 5 ? '-' + url.split('/')[5] : '') + ' : ' + response.body);
		
		updateCookie(response, url);
		
		if (response.statusCode == 200) {
			return _decoder.convert(response.body);
		} else {
			throw Exception('Connection error !');
		}
	}
	
	Future<Map> post(String url, {Map<String, String> body}) async {
		http.Response response = await http.post(url, body: body, headers: headers);
		print('Response ' + url.split('/')[4] + (url.split('/').length > 5 ? '-' + url.split('/')[5] : '') + ' : ' + response.body);
		
		updateCookie(response, url);
		
		if (response.statusCode == 200) {
			return _decoder.convert(response.body);
		} else {
			throw Exception('Connection error !');
		}
	}
	
	Future updateCookie(http.Response response, String url) async {
		var cookie = response.headers['set-cookie'];
		
		cookie = cookie.substring(cookie.indexOf('ATRISSESSION'));
		cookie = cookie.substring(0, cookie.indexOf(';')) + ';';
		
		if (url.split('/').length == 5) {
			if (url.split('/')[4] == 'admin') await _write(cookie);
		}
		
		var _cookie = await _read();
		print(_cookie);
		
		headers['cookie'] = _cookie;
	}
	
	Future<String> _read() async {
		final directory = await getApplicationDocumentsDirectory();
		final file = File('${directory.path}/session.txt');
		return await file.readAsString();
	}
	
	Future _write(String text) async {
		final directory = await getApplicationDocumentsDirectory();
		final file = File('${directory.path}/session.txt');
		await file.writeAsString(text);
	}
}
