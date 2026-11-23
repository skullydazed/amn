# See the 'COPYRIGHT' file for more information.
if (word(2 $loadinfo()) != [pf]) {
	load -pf $word(1 $loadinfo());
	return;
};

subpackage ignore;

alias _igmask (mask, void) {
	if (ischannel($mask) || match(*.* $mask) && !match(*@* $mask) && !match(*!* $mask)) {
		return $mask;
	};
	if (!match(*!* $mask)) {
		if (match(*@* $mask)) {
			@mask = [*!$mask];
		} else {
			@mask = [$mask!*@*];
		};
	};
	if (!match(*@* $mask)) {
		@mask = [$mask@*];
	};
	return $mask;
};

alias _igdelete (ref, void) {
	fe (target levels reason expires) field {
		^assign -_ignores[$ref][$field];
	};
};

alias _igrefs {
	foreach _ignores ref {
		if (_ignores[$ref][expires] && _ignores[$ref][expires] <= time()) {
			_igdelete $ref;
		} else {
			push function_return $ref;
		};
	};
	return $numsort($function_return);
};

alias _igchange (ref, ...) {
	# Keep obsolete or unknown levels in the saved rule. Only current levels match a context.
	@:ops = sar(g/,/ /$*);
	while (#ops) {
		@:op = shift(ops);
		switch ($op) {
			(REASON) { @ _ignores[$ref][reason] = shift(ops); }
			(TIMEOUT) {
				@:seconds = shift(ops);
				@ _ignores[$ref][expires] = seconds > 0 ? time() + seconds : [];
			}
			(*) {
				@:mode = left(1 $op);
				@:level = toupper($op);
				if (index(-^!/+ $mode) >= 0) {
					@:level = rest(1 $level);
				} elsif (left(5 $level) == [DONT-]) {
					@:mode = [^];
					@:level = rest(5 $level);
				} elsif (left(1 $op) == chr(2) && right(1 $op) == chr(2)) {
					@:mode = [+];
					@:level = mid(1 ${@op - 2} $level);
				};
				@:levels = level;
				if (level == [ALL] || level == [NONE]) {
					@:levels = [DCC $levelctl(LEVELS)];
					@ _ignores[$ref][levels] = [];
				};
				fe ($levels) name {
					@:number = levelctl(LOOKUP $name);
					if (number > 0) {
						@name = levelctl(LOOKUP $number);
					};
					@:kept = [];
					fe ($_ignores[$ref][levels]) old {
						if (rest(1 $old) != name) {
							push :kept $old;
						};
					};
					@ _ignores[$ref][levels] = kept;
					if (level != [NONE] && mode != [-]) {
						switch ($mode) {
							(^) (!) { push _ignores[$ref][levels] ^$name; }
							(+) { push _ignores[$ref][levels] +$name; }
							(*) { push _ignores[$ref][levels] /$name; }
						};
					};
				};
			}
		};
	};
	if (!_ignores[$ref][levels]) {
		_igdelete $ref;
		return;
	};
	return $ref;
};

alias ignorectl (op, key, ...) {
	@:refs = _igrefs();
	switch ($op) {
		(REFNUMS) { return $refs; }
		(REFNUM) (ADD) {
			@:mask = _igmask($key);
			fe ($refs) ref {
				if (_ignores[$ref][target] == mask) {
					if (op == [ADD]) {
						return $_igchange($ref $*);
					};
					return $ref;
				};
			};
			if (op == [ADD] && @key) {
				@:ref = ++_ignore_next_ref;
				@ _ignores[$ref][target] = mask;
				return $_igchange($ref $*);
			};
		}
		(GET) (CHANGE) (DELETE) {
			if (findw($key $refs) < 0) {
				return;
			};
			if (op == [DELETE]) {
				_igdelete $key;
				return 1;
			};
			if (op == [CHANGE]) {
				return $_igchange($key $*);
			};
			switch ($0) {
				(NICK) { return $_ignores[$key][target]; }
				(LEVEL) (LEVELS) { return $_ignores[$key][levels]; }
				(REASON) { return $_ignores[$key][reason]; }
				(EXPIRATION) { return $_ignores[$key][expires]; }
			};
		}
		(PATTERN) (RPATTERN) (WITH_TYPE) (WITH_TYPES) {
			fe ($refs) ref {
				@:mask = _ignores[$ref][target];
				if ((op == [PATTERN] && match($key $mask)) || (op == [RPATTERN] && match($mask $key)) || (op =~ [WITH_TYPE*] && _iglevels($ref $key $*))) {
					push function_return $mask;
				};
			};
		}
	};
};

alias _iglevels (ref, ...) {
	fe ($*) name {
		@:number = levelctl(LOOKUP $name);
		if (number > 0) {
			@name = levelctl(LOOKUP $number);
		};
		if (findw(/$name $_ignores[$ref][levels]) < 0) {
			return 0;
		};
	};
	return 1;
};

alias _ighost (mask, void) {
	if (!ischannel($mask) && !match(*!* $mask) && !match(*@* $mask) && (:host = getuhost($mask))) {
		return *!$host;
	};
	return $mask;
};

alias ignore (targets, ...) {
	if (!@targets) {
		xecho -b Ignorance List:;
		fe ($ignorectl(REFNUMS)) ref {
			_igshow $ref;
		};
		return;
	};
	fe ($sar(g/,/ /$targets)) target {
		if (isnumber($target)) {
			@:ref = target;
			if (@) {
				@:ref = ignorectl(CHANGE $ref $*);
			};
		} else {
			@:ops = *;
			if (!@ops) {
				@:ops = [ALL];
			};
			@:ref = ignorectl(ADD $_ighost($target) $ops);
		};
		if (@ref && !_amn_loading_saved_state) {
			_igshow $ref;
		};
	};
};

alias _igshow (ref, void) {
	if (:mask = ignorectl(GET $ref NICK)) {
		xecho -b [$ref] $mask $igtype($mask);
	};
};

alias _igdisposition (target, level, ...) {
	@:patterns = [];
	fe ($*) ref {
		push :patterns $_ignores[$ref][target];
	};
	@:index = rmatch($target $patterns);
	if (!index) {
		return;
	};
	@:rule = word(${index - 1} $*);
	fe ($_ignores[$rule][levels]) entry {
		if (rest(1 $entry) == level) {
			return $left(1 $entry);
		};
	};
};

on #^context -333 * (server, window, sender, target, level) {
	@:refs = _igrefs();
	if (!@refs || sender == [*]) {
		return;
	};
	if (!match(*!* $sender)) {
		@sender = _igmask($sender);
	};
	@:mode = _igdisposition($sender $level $refs);
	if (!@mode && ischannel($target)) {
		@:mode = _igdisposition($target $level $refs);
	};
	if (mode == [/]) {
		shh;
	};
};
