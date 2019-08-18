import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'bloc/search_bloc.dart';

import '../../model/terminal.dart';
import '../../model/schedule.dart';
import '../../api/terminal_lookup.dart';
import '../../api/versatiket_api.dart';

class BusPage extends StatefulWidget {
	BusPage({ this.terminalLookup });
	
	final TerminalLookup terminalLookup;
	
	@override
	_BusPageState createState() => _BusPageState(terminalLookup: terminalLookup);
}

class _BusPageState extends State<BusPage> {
	_BusPageState({ this.terminalLookup });
	
	final TerminalLookup terminalLookup;
	
	VersatiketApi _versaApi;
	List<Schedule> schedules;
	
	bool _isLoading = false;
	
	@override
	void initState() {
		super.initState();
		_versaApi = VersatiketApi();
	}
	
	Future<void> _alert(BuildContext context, String info) {
		return showDialog<void>(
			context: context,
			builder: (BuildContext context) {
				return AlertDialog(
					title: Text('Warning !'),
					content: Text(info),
					actions: <Widget>[
						FlatButton(
							child: Text('Ok'),
							onPressed: () {
							  Navigator.of(context).pop();
							},
						),
					],
				);
			},
		);
	}
	
	Future _process(Search search) async {
		if (search.departure == null) {
			_alert(context, 'tidak ada pilih untuk keberangkatan');
		} else if (search.arrival == null) {
			_alert(context, 'tidak ada pilih untuk tiba');
		} else if (search.date == null) {
			_alert(context, 'tanggal harus di isi');
		} else if (search.adult == null) {
			_alert(context, 'penumpang dewasa tidak boleh kosong');
		} else {
			setState(() { _isLoading = true; } );
			await _versaApi.start();
			
			await new Future.delayed(const Duration(seconds : 10));
			
			var res = await _versaApi.search(search);
			
			if (res['status'] == 'timeout') { 
				_alert(context, res['message']);
			} else if (res['status'] == 'failed') {
				_alert(context, res['content']['reason']);
			} else {
				if (res['content']['depart_schedule'] == null) {
					_alert(context, 'data kosong !');
				} else {
					print('${res['content']['depart_schedule']}');
					schedules = res['content']['depart_schedule'].map<Schedule>((json) => Schedule.fromJson(json)).toList();
					for (final data in schedules) {
						print(data.bus_name);
					}
				}
				
				await _versaApi.logout();
			}
			setState(() { _isLoading = false; } );
		}
	}
	
	@override
	Widget build(BuildContext context) {
		final searchBloc = Provider.of<SearchBloc>(context);
		
		return Scaffold(
			appBar: AppBar( title: Text('Flutter Bus'), ),
			body: StreamBuilder(
				stream: searchBloc.searchStream,
				initialData: Search(),
				builder: (context, snapshot) {
					return ListView(
						padding: EdgeInsets.zero,
						children: [
							Route(terminalLookup: terminalLookup, searchBloc: searchBloc),
							SizedBox(height: 15.0),
							BoxDecorationDate(searchBloc: searchBloc),
							SizedBox(height: 15.0),
							BoxDecorationPassenger(searchBloc: searchBloc),
							SizedBox(height: 30.0),
							BoxDecorationButton(snapshot.data),
						],
					);
				},
			),
		);
	}
	
	Widget BoxDecorationButton(Search search) {
		return InkWell(
			onTap: () { _isLoading ? null : _process(search); },
			child: Container(
				padding: EdgeInsets.only(left: 20.0, right: 20.0),
				child: Container(
					alignment: Alignment.center,
					constraints: BoxConstraints(minWidth: 400.0, minHeight: 40.0),
					decoration: BoxDecoration(
						color: Colors.blue[500],
						border: Border.all(color: Colors.grey[400], width: 1.0),
						borderRadius: BorderRadius.circular(10.0),
					),
					child: _isLoading ? SizedBox(child: CircularProgressIndicator( valueColor: AlwaysStoppedAnimation<Color>(Colors.white)), height: 10.0, width: 10.0 ) : Text('SEARCH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: Colors.white)),
				),
			),
		);
	}
}

class Route extends StatefulWidget {
	Route({ this.terminalLookup, this.searchBloc });
	
	final TerminalLookup terminalLookup;
	final SearchBloc searchBloc;
	
	@override
	_RouteState createState() => _RouteState(terminalLookup: terminalLookup, searchBloc: searchBloc);
}

class _RouteState extends State<Route> {
	_RouteState({ this.terminalLookup, this.searchBloc });
	
	final TerminalLookup terminalLookup;
	final SearchBloc searchBloc;
	
	Terminal departure;
	Terminal arrival;
	
	Future<Terminal> _showSearch(BuildContext context) async {
		return await showSearch<Terminal>(
			context: context,
			delegate: TerminalSearchDelegate( terminalLookup: terminalLookup )
		);
	}
	
	void _selectDepart(BuildContext context) async {
		var terminal = await _showSearch(context);
		setState(() => departure = terminal);
		
		print(departure);
		searchBloc.updateWith(departure: terminal);
	}
	
	void _selectArrival(BuildContext context) async {
		var terminal = await _showSearch(context);
		setState(() => arrival = terminal);
		
		print(arrival);
		searchBloc.updateWith(arrival: terminal);
	}
	
	@override
	Widget build(BuildContext context) {
		return Container(
			color: Colors.blue[500],
			padding: EdgeInsets.only(top: 40.0, bottom: 40.0),
			alignment: FractionalOffset.center,
			child: Row(
				mainAxisAlignment: MainAxisAlignment.spaceEvenly,
				// crossAxisAlignment: CrossAxisAlignment.center,
				children: [
					TerminalWidget(title: 'BERANGKAT', terminal: departure, onPressed: () => _selectDepart(context)),
					Icon(Icons.directions_bus, color: Colors.white, size: 35.0),
					TerminalWidget(title: 'TIBA', terminal: arrival, onPressed: () => _selectArrival(context)),
				],
			),
		);
	}
}

class TerminalWidget extends StatelessWidget {
	TerminalWidget({ this.title, this.terminal, this.onPressed });
	
	final String title;
	final Terminal terminal;
	final VoidCallback onPressed;
	
	@override
	Widget build(BuildContext context) {
		return InkWell(
			onTap: onPressed,
			child: Text(terminal != null ? terminal.terminal_name : title, style: TextStyle(fontSize: 14.0, color: Colors.white)),
		);
	}
}


class BoxDecorationDate extends StatefulWidget {
	BoxDecorationDate({ this.searchBloc });
	
	final SearchBloc searchBloc;
	
	@override
	_BoxDecorationDateState createState() => _BoxDecorationDateState(searchBloc: searchBloc);
}

class _BoxDecorationDateState extends State<BoxDecorationDate> {
	_BoxDecorationDateState({ this.searchBloc });
	
	final SearchBloc searchBloc;
	String date = "dd-mm-yyyy";
	// String date = DateFormat("yyyy-MM-dd").format(DateTime.now());
	
	Future _selectDate() async {
		DateTime picked = await showDatePicker(
			context: context,
			initialDate: new DateTime.now(),
			firstDate: new DateTime(2016),
			lastDate: new DateTime(2030)
		);
		if(picked != null) {
			setState(() {
				date = DateFormat('dd-MM-yyyy').format(picked);
				print('Selected date: ' + date);
				searchBloc.updateWith(date: date);
			});
		}
	}
	
	@override
	Widget build(BuildContext context) {
		return InkWell(
			onTap: () { _selectDate(); },
			child: Container(
				padding: EdgeInsets.only(left: 20.0, right: 20.0),
				child: Column(
					children: [
						Row(children: [Text('Tanggal Keberangkatan', style: TextStyle(fontSize: 12.0, color: Colors.grey[400]))]),
						SizedBox(height: 2.0),
						Container(
							alignment: Alignment.center,
							constraints: BoxConstraints(minWidth: 400.0, minHeight: 40.0),
							decoration: BoxDecoration(
								border: Border.all(color: Colors.grey[400], width: 1.0),
								borderRadius: BorderRadius.circular(10.0),
							),
							child: Text(date),
						),
					],
				),
			),
		);
	}
}

class BoxDecorationPassenger extends StatefulWidget {
	BoxDecorationPassenger({ this.searchBloc });
	
	final SearchBloc searchBloc;
	
	@override
	_BoxDecorationPassengerState createState() => _BoxDecorationPassengerState(searchBloc: searchBloc);
}

class _BoxDecorationPassengerState extends State<BoxDecorationPassenger> {
	_BoxDecorationPassengerState({ this.searchBloc });
	
	final SearchBloc searchBloc;
	int adult = 0;
	int child = 0;
	
	@override
	Widget build(BuildContext context) {
		return Container(
			padding: EdgeInsets.only(left: 20.0, right: 20.0),
			child: Column(
				children: [
					Row(children: [Text('Penumpang', style: TextStyle(fontSize: 12.0, color: Colors.grey[400]))]),
					SizedBox(height: 2.0),
					Container(
						alignment: Alignment.center,
						constraints: BoxConstraints(minWidth: 400.0, minHeight: 40.0),
						decoration: BoxDecoration(
							border: Border.all(color: Colors.grey[400], width: 1.0),
							borderRadius: BorderRadius.circular(10.0),
						),
						child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [passenger('adult', adult), SizedBox(width: 1.0), passenger('child', child)]),
					),
				],
			),
		);
	}
	
	Widget passenger(String type, int count) {
		return InkWell(
			onTap: () {
				Scaffold.of(context).showSnackBar(SnackBar(
					content: popupPassenger(type),
					duration: Duration(seconds: 30),
					action: SnackBarAction(
						label: 'tutup',
						onPressed: () {},
					),
				));
			},
			child: Column(children: [Text('${count}', style: TextStyle(fontSize: 18.0)), Text(type, style: TextStyle(fontSize: 12.0, color: Colors.grey[400]))]),
		);
	}
	
	Widget popupPassenger(String type) {
		return Row(
			mainAxisAlignment: MainAxisAlignment.spaceBetween,
			children: [
				Text('${type}'),
				SizedBox(width: 1.0),
				Row(
					children: [
						Container(
							decoration: BoxDecoration(
								color: Colors.purple,
								borderRadius: BorderRadius.circular(12.0),
							),
							child: IconButton(
								icon: new Icon(Icons.add),
								onPressed: () {
									if (type == 'adult') setState(() { if (adult < 4) { adult++; searchBloc.updateWith(adult: adult); } else { Container(); } });
									if (type == 'child') setState(() { if (child < 4) { child++; searchBloc.updateWith(child: child); } else { Container(); } });
								}
							),
						),
						SizedBox(width: 5.0),
						Container(
							decoration: BoxDecoration(
								color: Colors.purple,
								borderRadius: BorderRadius.circular(12.0),
							),
							child: IconButton(
								icon: new Icon(Icons.remove),
								onPressed: () {
									if (type == 'adult') setState(() { if (adult > 0) { adult--; searchBloc.updateWith(adult: adult); } else { Container(); } });
									if (type == 'child') setState(() { if (child > 0) { child--; searchBloc.updateWith(child: child); } else { Container(); } });
								}
							),
						),
					],
				),
			],
		);
	}
}

class TerminalSearchDelegate extends SearchDelegate<Terminal> {
	TerminalSearchDelegate({ @required this.terminalLookup });
	
	final TerminalLookup terminalLookup;
	
	@override
	Widget buildLeading(BuildContext context) {
		return IconButton(
			tooltip: 'Back',
			icon: AnimatedIcon( icon: AnimatedIcons.menu_arrow, progress: transitionAnimation, ),
			onPressed: () { close(context, null); },
		);
	}
	
	@override
	Widget buildSuggestions(BuildContext context) {
		return buildMatchingSuggestions(context);
	}
	
	@override
	Widget buildResults(BuildContext context) {
		return buildMatchingSuggestions(context);
	}
	
	Widget buildMatchingSuggestions(BuildContext context) {
		if (query.isEmpty) return Container();
		// if (query.length < 3) return Container();
		
		final searched = terminalLookup.searchString(query);
		
		if (searched.length == 0) return TerminalSearchPlaceholder(title: 'No results');
		
		return ListView.builder(
			itemCount: searched.length,
			itemBuilder: (context, index) {
				return TerminalSearchResultTile( terminal: searched[index], searchDelegate: this, );
			},
		);
	}
	
	@override
	List<Widget> buildActions(BuildContext context) {
		return query.isEmpty ? [] : <Widget>[
			IconButton(
				tooltip: 'Clear',
				icon: const Icon(Icons.clear),
				onPressed: () { query = ''; showSuggestions(context); },
			)
		];
	}
}

class TerminalSearchPlaceholder extends StatelessWidget {
	TerminalSearchPlaceholder({@required this.title});
	final String title;
	
	@override
	Widget build(BuildContext context) {
		final ThemeData theme = Theme.of(context);
		return Center(
			child: Text( title, style: theme.textTheme.headline, textAlign: TextAlign.center, ),
		);
	}
}

class TerminalSearchResultTile extends StatelessWidget {
	const TerminalSearchResultTile({ @required this.terminal, @required this.searchDelegate });
	
	final Terminal terminal;
	final SearchDelegate<Terminal> searchDelegate;
	
	@override
	Widget build(BuildContext context) {
		final ThemeData theme = Theme.of(context);
		return ListTile(
			dense: true,
			title: Text( '${terminal.terminal_name}', style: theme.textTheme.body2, textAlign: TextAlign.start, ),
			onTap: () => searchDelegate.close(context, terminal),
		);
	}
}
