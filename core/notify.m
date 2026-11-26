# See the 'COPYRIGHT' file for more information.
subpackage notify;

# The configured list is global, including while disconnected. MONITOR state belongs to each connection.
alias notify (...) {
	if (functioncall()) {
		return $_notify_nicks;
	};
	if (!@) {
		xecho -b Notify list: $_notify_nicks;
		if (serverctl(GET -1 005 MONITOR) != []) {
			quote MONITOR S;
		};
		return;
	};
	fe ($sar(g/,/ /$*)) entry {
		@:prefix = left(1 $entry);
		@:nick = entry;
		if (prefix == [-] || prefix == [+]) {
			@:nick = rest(1 $entry);
		};
		if (entry == [-]) {
			@_notify_nicks = [];
		} elsif (@nick && prefix == [-]) {
			@_notify_nicks = remw($nick $_notify_nicks);
		} elsif (@nick && findw($nick $_notify_nicks) < 0) {
			push _notify_nicks $nick;
		};
	};
	if (!_amn_loading_saved_state) {
		_ntfy_sync_all;
	};
};

alias _ntfy_sync_all {
	fe ($serverctl(omatch *)) ref {
		if (serverctl(GET $ref CONNECTED) && serverctl(GET $ref 005 MONITOR) != []) {
			xeval -s $ref _ntfy_sync $ref;
		};
	};
};

alias _ntfy_send (op, ...) {
	@:nicks = *;
	while (@nicks) {
		@:batch = leftw(10 $nicks);
		@ nicks = restw(10 $nicks);
		quote MONITOR $op $sar(g/ /,/$batch);
	};
};

alias _ntfy_sync (ref, void) {
	@:previous = _notify_sent[$ref];
	@:removed = [];
	@:added = [];
	fe ($previous) nick {
		if (findw($nick $_notify_nicks) < 0) {
			push :removed $nick;
			@_notify_online[$ref] = remw($nick $_notify_online[$ref]);
		};
	};
	fe ($_notify_nicks) nick {
		if (findw($nick $previous) < 0) {
			push :added $nick;
		};
	};
	_ntfy_send - $removed;
	_ntfy_send + $added;
	@_notify_sent[$ref] = _notify_nicks;
};

on #-005 10 * {
	@:ref = serverctl(FROM_SERVER);
	if (!_amn_loading_saved_state && serverctl(GET $ref 005 MONITOR) != []) {
		_ntfy_sync $ref;
	};
};

on #-server_state 10 "% % CLOSED" {
	^assign -_notify_sent[$0];
	^assign -_notify_online[$0];
};

alias _ntfy_event (state, ...) {
	@:ref = serverctl(FROM_SERVER);
	fe ($sar(g/,/ /$*)) address {
		@:nick = before(! $address);
		if (!@nick) {
			@:nick = address;
		};
		if (findw($nick $_notify_nicks) >= 0) {
			xecho -v $G $state by $address on $strftime(%x at %X);
			@:online = findw($nick $_notify_online[$ref]) >= 0;
			if (state == [SignOn] && !online) {
				push _notify_online[$ref] $nick;
				hook amnesiac_notify $state $address;
			} elsif (state == [SignOff] && online) {
				@_notify_online[$ref] = remw($nick $_notify_online[$ref]);
				hook amnesiac_notify $state $address;
			};
		};
	};
};

on ^730 * { _ntfy_event SignOn $1-; };
on ^731 * { _ntfy_event SignOff $1-; };
