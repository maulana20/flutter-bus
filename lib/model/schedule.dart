class Schedule extends Object {
	String bus_name;
	String bus_provider;
	
	Schedule({ this.bus_name, this.bus_provider });
	
	factory Schedule.fromJson(Map<String, dynamic> json) {
		return Schedule(
			bus_name: json['bus_name'],
			bus_provider: json['bus_provider'],
		);
	}
}
