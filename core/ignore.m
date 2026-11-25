#
# Based on EPIC6 script/ignore (hop).
#
#  THE MOST RAW SYNTAX:
#	/IGNORE <objects> <operations>
#
#  <objects> is a comma-separated or space-separated list of
#      <refnums> or wildcard <targets>.  Space-separated lists
#      must be surrounded by double quotes
#
#  <operations> are comma-separated or space-separated list of
#       levels, which may be prefixed with +, -, or neither,
#       or the operations TIMEOUT <seconds> or REASON <string>
#
# How this looks:
#  /ignore
#		List all ignores
#  /ignore <target>
#		Ignore the target at all levels
#  /ignore <refnum>
#		List a specific ignore by its refnum
#
#  /ignore <target> <level(s)>
#		Upsert an ignore to add or remove levels
#  /ignore <refnum> <level(s)>
#		Update an ignore to add or remove levels
#  Levels can be prefixed with + (add) or - (remove) or neither (add)
#  Levels can be comma-separated or space-separated
#
#  /ignore <target|refnum> TIMEOUT <seconds>
#  /ignore <target|refnum> REASON <reason>
#  In addition to levels, you can specify a timeout or a reason.
#
#  <target> is either a nick!user@host or a channel.
#  Channel names are identified by $ischannel().
#  A bare nickname uses the cached userhost when available.
#

#
# The ignore data structure:
#	target:		string (wildcard pattern)
#	levels:		string (space-separated list of levels)
#	reason:		string
#	timeout:	integer (time_t value)
#
# We have a lookup table:
#	_ignores_lookup[<encoded wildcard>] = <refnum>
#
# The ignore data structure is stored per refnum:
#	_ignores[<refnum>][<field>] = <value>
#
subpackage ignore;

alias ignore (targets dwords 1, ...) {
	if (!@targets) {
		ignore.show_all;
		return;
	};

	fe ($sar(g/,/ /$targets)) target {
		@:refnum = _ignore.find_target($target);
		@:operations = *;
		if (!isnumber($target)) {
			if (!@refnum) {
				@refnum = _ignore.upsert_target($target);
			};
			if (!@operations) {
				@operations = [ALL];
			};
		};
		if (@refnum && @operations) {
			_ignore.change $refnum $operations;
		};
		if (@refnum && !_amn_loading_saved_state) {
			_ignore.show $refnum;
		};
	};
};

alias _ignore.mask (target, void) {
	if (ischannel($target)) {
		return $target;
	};
	if (index(! $target) < 0 && index(@ $target) < 0) {
		# A bare dotted mask can name an IRC server.
		if (index(. $target) >= 0) {
			return $target;
		};
		@:host = userhost($target);
		if (@host && host != [<UNKNOWN>@<UNKNOWN>]) {
			return *!$host;
		};
		return $target!*@*;
	};
	if (index(! $target) < 0) {
		return *!$target;
	};
	if (index(@ $target) < 0) {
		return $target@*;
	};
	return $target;
};

alias _ignore.find_target (target, void) {
	if (isnumber($target)) {
		if (findw($target $_ignore.refs()) >= 0) {
			return $target;
		};
		return;
	};
	@:mask = _ignore.mask($target);
	_ignore.gc_ignores;
	return $_ignores_lookup[$xform(+ENC $tolower($mask))];
};

alias _ignore.upsert_target (target, void) {
	@:mask = _ignore.mask($target);
	@:key = xform(+ENC $tolower($mask));
	@:refnum = _ignores_lookup[$key];
	if (!@refnum) {
		@refnum = ++_ignore_next;
		@_ignores_lookup[$key] = refnum;
		@_ignores[$refnum][target] = mask;
	};
	return $refnum;
};

alias _ignore.delete (refnum, void) {
	@:key = xform(+ENC $tolower($_ignores[$refnum][target]));
	^assign -_ignores_lookup[$key];
	fe (target levels reason timeout) field {
		^assign -_ignores[$refnum][$field];
	};
};

alias _ignore.gc_ignores {
	foreach _ignores refnum {
		@:timeout = _ignores[$refnum][timeout];
		if ((timeout && timeout <= time()) || !@_ignores[$refnum][levels]) {
			_ignore.delete $refnum;
		};
	};
};

alias _ignore.refs {
	_ignore.gc_ignores;
	foreach _ignores refnum {
		push function_return $refnum;
	};
	return $numsort($function_return);
};

alias _ignore.change (refnum, ...) {
	@:operations = *;
	while (@operations) {
		@:operation = shift(operations);
		if (index(, $operation) >= 0) {
			@:operations = [$after(, $operation) $operations];
			@operation = before(, $operation);
		};
		switch ($operation) {
			() { continue; }
			(REASON) {
				@operations = _ignore.set_reason($refnum $operations);
			}
			(TIMEOUT) {
				@:seconds = shift(operations);
				if (index(, $seconds) >= 0) {
					@:operations = [$after(, $seconds) $operations];
					@seconds = before(, $seconds);
				};
				@_ignores[$refnum][timeout] = seconds > 0 ? time() + seconds : 0;
			}
			(*) { _ignore.set_level $refnum $operation; }
		};
	};
	_ignore.gc_ignores;
};

alias _ignore.set_reason (refnum, reason dwords 1, ...) {
	@_ignores[$refnum][reason] = reason;
	return $*;
};

alias _ignore.set_level (refnum, operation, void) {
	@:level = toupper($operation);
	@:mode = left(1 $level);
	if (left(5 $level) == [DONT-]) {
		@mode = [^];
		@level = rest(5 $level);
	} elsif (index(-+^!/ $mode) >= 0) {
		@level = rest(1 $level);
	} elsif (mode == chr(2) && right(1 $level) == chr(2)) {
		@mode = [+];
		@level = mid(1 ${@level - 2} $level);
	};
	if (!@level) {
		return;
	};
	if (level == [NONE] || (level == [ALL] && mode == [-])) {
		@_ignores[$refnum][levels] = [];
		return;
	};
	@:names = level;
	if (level == [ALL]) {
		@_ignores[$refnum][levels] = [];
		@names = [OTHER $levelctl(LEVELS)];
	};
	fe ($names) name {
		@:number = levelctl(LOOKUP $name);
		if (number >= 0) {
			@name = levelctl(LOOKUP $number);
		};
		@:levels = _ignores[$refnum][levels];
		fe (/ + ^) prefix {
			@levels = remw($prefix$name $levels);
		};
		switch ($mode) {
			(-) { }
			(^) (!) { push :levels ^$name; }
			(+) { push :levels +$name; }
			(*) { push :levels /$name; }
		};
		@_ignores[$refnum][levels] = levels;
	};
};

alias ignore.show_all {
	xecho -b Ignorance List:;
	fe ($_ignore.refs()) refnum {
		_ignore.show $refnum;
	};
};

alias _ignore.display_levels (refnum, void) {
	fe ($_ignores[$refnum][levels]) entry {
		switch ($left(1 $entry)) {
			(^) { push function_return DONT-$rest(1 $entry); }
			(+) { push function_return +$rest(1 $entry); }
			(/) { push function_return $rest(1 $entry); }
		};
	};
};

alias _ignore.show (refnum, void) {
	if (@_ignores[$refnum][target]) {
		xecho -b [$refnum] $_ignores[$refnum][target] $_ignore.display_levels($refnum);
	};
};

alias _ignore.select (value, level, ...) {
	@:patterns = [];
	@:refs = [];
	fe ($*) refnum {
		if (findw(/$level $_ignores[$refnum][levels]) >= 0 || findw(^$level $_ignores[$refnum][levels]) >= 0 || findw(+$level $_ignores[$refnum][levels]) >= 0) {
			push :patterns $_ignores[$refnum][target];
			push :refs $refnum;
		};
	};
	return $word(${rmatch($value $patterns) - 1} $refs);
};

on #^context -333 * (server, window, sender, target, level) {
	@:refs = _ignore.refs();
	if (!@refs) {
		return;
	};
	@:refnum = [];
	if (sender != [*]) {
		if (index(! $sender) < 0 && index(. $sender) < 0 && !ischannel($sender)) {
			@sender = [$sender!*@*];
		};
		@refnum = _ignore.select($sender $level $refs);
	};
	if (!@refnum && ischannel($target)) {
		@refnum = _ignore.select($target $level $refs);
	};
	if (@refnum && findw(/$level $_ignores[$refnum][levels]) >= 0) {
		shh;
	};
};

# AMN save files store absolute deadlines and encoded text.
alias _ignore.restore (mask, deadline, reason, ...) {
	if (deadline && deadline <= time()) {
		return;
	};
	@:refnum = _ignore.upsert_target($mask);
	@_ignores[$refnum][timeout] = deadline;
	@_ignores[$refnum][reason] = rest(1 $xform(-ENC $reason));
	@_ignores[$refnum][levels] = *;
};

alias _ignore.load (encoded_mask, deadline, reason, ...) {
	_ignore.restore $xform(-ENC $encoded_mask) $deadline $reason $*;
};

# Read saves written by earlier AMN versions.
alias _igrestore (mask, deadline, reason, ...) {
	_ignore.restore $mask $deadline $reason $*;
};

#hop'2k25
