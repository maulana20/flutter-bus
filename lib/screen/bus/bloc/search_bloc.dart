import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

import '../../../model/terminal.dart';

class SearchBloc {
	final BehaviorSubject _searchSubject = BehaviorSubject<Search>(seedValue: Search());
	
	Stream<Search> get searchStream => _searchSubject.controller.stream;
	
	void updateWith({ Terminal departure, Terminal arrival, String date, int adult, int child }) {
		Search value = _searchSubject.value.copyWith(departure: departure, arrival: arrival, date: date, adult: adult, child: child);
		_searchSubject.add(value);
	}
	
	void dispose() {
		_searchSubject.close();
	}
}

class Search {
	final Terminal departure;
	final Terminal arrival;
	final String date;
	final int adult;
	final int child;
	
	Search({ this.departure, this.arrival, this.date, this.adult, this.child });
	Search copyWith({ Terminal departure, Terminal arrival, String date, int adult, int child }) {
		return Search(
			departure: departure ?? this.departure,
			arrival: arrival ?? this.arrival,
			date: date ?? this.date,
			adult: adult ?? this.adult,
			child: child ?? this.child,
		);
	}
}
