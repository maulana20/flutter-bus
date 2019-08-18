import '../model/terminal.dart';

class TerminalLookup {
	TerminalLookup({this.terminals});
	final List<Terminal> terminals;
	
	List<Terminal> searchString(String string) {
		string = string.toLowerCase();
		
		final matching = terminals.where((terminal) { return terminal.terminal_name.toLowerCase() == string; }).toList();
		
		if (matching.length > 0)  return matching;
		
		return terminals.where((terminal) { return terminal.terminal_name.toLowerCase().contains(string); }).toList();
	}
}
