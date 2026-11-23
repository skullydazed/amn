# Copyright (c) 2003-2010 Amnesiac Software Project.
# See the 'COPYRIGHT' file for more information.
## codelogic's theme module, thanx to robohak for help w/ padding
## modified crapple/kreca 05&06

if (word(2 $loadinfo()) != [pf]) {
	load -pf $word(1 $loadinfo());
	return;
};

subpackage theme;

alias tsave (name,...) {
	@:oldvars='auth desc name c1 c2 c3 c4 c5 sc1 sc2 sc3 sc4 acban';

	if (!@) {
		xecho $acban $scriptname usage: /tsave <theme> <description>;
		return;
	};
	@:path = twiddle($(loadpath)themes/${name}.th);
	@:fd = open("${path}.$pid().tmp" wbx);
	if (fd < 0) {
		xecho $acban Could not open temporary save for $path;
		return;
	};
	@:failed = 0;
	@desc = *;
	@:auth=N;
	if (write($fd :$auth) < 0) {
		@failed = 1;
	};
	if (write($fd :$desc) < 0) {
		@failed = 1;
	};
	if (write($fd :$name) < 0) {
		@failed = 1;
	};
	if (write($fd assign scdesc \\\($desc\\\)) < 0) {
		@failed = 1;
	};
	fe ($oldvars ) cvar {
		if (write($fd assign $cvar $($cvar)) < 0) {
			@failed = 1;
		};
	};
	fe ($format_strings ) cvar {
		if (write($fd assign theme.format.$cvar $(theme.format.$cvar)) < 0) {
			@failed = 1;
		};
	};
	@:mode = word(2 $stat("$path"));
	if (close($fd) != 0 || failed || (@mode && left(2 $mode) != [10]) || rename("${path}.$pid().tmp" "$path") != 0) {
		if (unlink("${path}.$pid().tmp") != 0) {
			xecho $acban Could not remove temporary save ${path}.$pid().tmp;
		};
		xecho $acban Could not save $path;
		return;
	};
	xecho $acban saved theme file [$(loadpath)themes/$(name).th] $desc;
};

alias theme (name,void) {
	if (!@name) {
		//echo      file name           author              description;
		fe ($glob($(loadpath)themes\/*.th)) th {
			if (index(r $info(o)) >= 0 && (substr(.zip $th $realpath($th)) >= 0 || substr(.tar $th $realpath($th)) >= 0)) {
				xecho $acban Cannot read $th with this EPIC file reader;
				continue;
			};
			@:thfile = open("$th" R);
			if (thfile < 0) {
				xecho $acban Could not open $th for reading;
				continue;
			};
			@:auth = after(: $read($thfile));
			@:desc = [];
			@:name = [];
			if (!ferror($thfile)) {
				@desc = after(: $read($thfile));
			};
			if (!ferror($thfile)) {
				@name = after(: $read($thfile));
			};
			@:read_failed = ferror($thfile) != 0;
			if (close($thfile) != 0 || read_failed) {
				xecho $acban Error reading $th;
				continue;
			};
			//echo      $[10]name          $[12]auth        $desc$repeat(${20-strlen($strip( $stripansicodes($desc)))}  );
		};
		xecho $acban current theme is $scdesc;
	}{
		if (!@word(2 $stat("$(loadpath)themes/${name}.th"))) {
			xecho $acban theme ${name} does not exist;
		}{
			load $(loadpath)themes/${name}.th;
			@format.init();
			^getusers;
			xecho $acban loaded theme file [${name}.th] by $auth $desc;
		};
	};
};
