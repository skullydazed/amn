# Copyright (c) 2003-2026 Amnesiac Software Project.
# See the 'COPYRIGHT' file for more information.
subpackage save;

## Escape backslashes first, then dollars, semicolons, parentheses, and braces.
alias save.statement {
	@:statement = *;
	fe (92 36 59 40 41 123 125) code {
		@statement = sar(g|$chr($code)|$chr(92)$chr($code)|$statement);
	};
	return $statement$chr(59);
};

alias save.assignment (name, ...) {
	if (!@) {
		return @$name=[]$chr(59);
	};
	return $save.statement(assign $name $*);
};

alias save.read (path dwords 1, theme, void) {
	@path = twiddle($path);
	if (!theme && !@word(2 $stat("$path"))) {
		return 0;
	};
	if (index(r $info(o)) >= 0 && (substr(.zip $path $realpath($path)) >= 0 || substr(.tar $path $realpath($path)) >= 0)) {
		xecho -v $acban Cannot read $path with this EPIC file reader;
		return 0;
	};
	@:fd = open("$path" R);
	if (fd < 0) {
		xecho -v $acban Could not open $path for reading;
		return 0;
	};
	@:marker = read($fd);
	@:failed = ferror($fd) != 0;
	if (close($fd) != 0 || failed) {
		xecho -v $acban Error reading $path;
		return 0;
	};
	if (match("# amnesiac * file v1 - saved *" "$marker") || (theme && left(2 $marker) == [#:])) {
		load -pf $path;
		return 1;
	};
	load -std $path;
	if (theme) {
		xecho -v $acban Run /tsave $theme <description> to upgrade this theme to PF format.;
	} elsif (_amn_starting) {
		@_amn_legacy_saves = 1;
	} else {
		xecho -v $acban Run /save to upgrade legacy save files to PF format.;
	};
	return 1;
};

## Finish writing the replacement before moving the previous save to its backup.
alias save.replace (path dwords 1, failed, void) {
	@:staged = [${path}.$pid().tmp];
	@:backup = [${path}~];
	@:mode = word(2 $stat("$path"));
	if (!failed && @mode && left(2 $mode) != [10]) {
		@failed = 1;
	};
	@:backed_up = 0;
	if (!failed && @mode) {
		if (rename("$path" "$backup") != 0) {
			xecho $acban Could not back up $path to $backup;
			@failed = 1;
		} else {
			@backed_up = 1;
		};
	};
	if (!failed && rename("$staged" "$path") == 0) {
		return 1;
	};
	if (backed_up && rename("$backup" "$path") != 0) {
		xecho $acban Could not restore $path from $backup;
	};
	if (unlink("$staged") != 0) {
		xecho $acban Could not remove temporary save $staged;
	};
	xecho $acban Could not save $path;
	return 0;
};

alias asave {
	@:path = twiddle($(savepath)$savefile);
	@:fd = open("${path}.$pid().tmp" wbx);
	if (fd < 0) {
		xecho $acban Could not open temporary save for $path;
		return;
	};
	@:failed = write($fd # amnesiac config file v1 - saved $strftime($time() %D %T)) < 0;
	if (write($fd $save.statement(notify - $notify())) < 0) {
		@failed = 1;
	};
	@:vars = 'fke1 fke2 fke3 fke4 fke5 fke6 fke7 fke8 fke9 fke10 fke11 fke12 plog crapl msgl notl awayt awayr showop kickops getumode togaway windowdoubles clonecheck bt_ _bt et_ _et _ss _ort _pubnick _tss _ovsize _ovmode acban rfrombuf rsendbuf';
	fe ($vars) cvar {
		if (write($fd $save.statement(assign $cvar $($cvar))) < 0) {
			@failed = 1;
		};
	};
	if (close($fd) != 0) {
		@failed = 1;
	};
	if (save.replace("$path" $failed)) {
		xecho $acban Amnesiac settings saved to $path;
	};
};

alias setsave {
	@:path = twiddle($(savepath)$setsavefile);
	@:fd = open("${path}.$pid().tmp" wbx);
	if (fd < 0) {
		xecho $acban Could not open temporary save for $path;
		return;
	};
	@:failed = write($fd # amnesiac settings file v1 - saved $strftime($time() %D %T)) < 0;
	fe ($symbolctl(pmatch builtin_variable *)) cur {
		if (write($fd $save.statement(set $cur $getset($cur))) < 0) {
			@failed = 1;
		};
	};
	if (close($fd) != 0) {
		@failed = 1;
	};
	if (!save.replace("$path" $failed)) {
		return;
	};
	xecho $acban Epic settings saved to $(savepath)$setsavefile;
};

alias fsetsave {
	@:path = twiddle($(savepath)$fsetsavefile);
	@:fd = open("${path}.$pid().tmp" wbx);
	if (fd < 0) {
		xecho $acban Could not open temporary save for $path;
		return;
	};
	@:failed = write($fd # amnesiac fset file v1 - saved $strftime($time() %D %T)) < 0;
#fwords is edited in fsets.m
	fe ($fwords) a1 {
		if (write($fd $save.statement(^sfset format_$a1 $(format_$a1))) < 0) {
			@failed = 1;
		};
	};
	if (close($fd) != 0) {
		@failed = 1;
	};
	if (!save.replace("$path" $failed)) {
		return;
	};
	xecho $acban Fset settings saved to $(savepath)$fsetsavefile;
};

alias fsave {
	@:path = twiddle($(savepath)$fsavefile);
	@:fd = open("${path}.$pid().tmp" wbx);
	if (fd < 0) {
		xecho $acban Could not open temporary save for $path;
		return;
	};
	@:failed = write($fd # amnesiac format file v1 - saved $strftime($time() %D %T)) < 0;
	if (write($fd $save.statement(assign scdesc $scdesc)) < 0) {
		@failed = 1;
	};

	fe ($format_strings ) cvar {
		if (write($fd $save.statement(assign theme.format.$cvar $(theme.format.$cvar))) < 0) {
			@failed = 1;
		};
	};
	if (close($fd) != 0) {
		@failed = 1;
	};
	if (!save.replace("$path" $failed)) {
		return;
	};
	xecho $acban Format settings saved to $(savepath)$fsavefile;
};

alias csave {
	@:path = twiddle($(savepath)$csavefile);
	@:fd = open("${path}.$pid().tmp" wbx);
	if (fd < 0) {
		xecho $acban Could not open temporary save for $path;
		return;
	};
	@:failed = write($fd # amnesiac color format file v1 - saved $strftime($time() %D %T)) < 0;
	@:vars = 'c1 c2 c3 c4 c5 sc1 sc2 sc3 sc4';
	fe ($vars ) cvar {
		if (write($fd $save.statement(assign $cvar $($cvar))) < 0) {
			@failed = 1;
		};
	};
	if (close($fd) != 0) {
		@failed = 1;
	};
	if (!save.replace("$path" $failed)) {
		return;
	};
	xecho $acban Color settings saved to $(savepath)$csavefile;
};

alias igsave {
	@:path = twiddle($(savepath)$igsfile);
	@:fd = open("${path}.$pid().tmp" wbx);
	if (fd < 0) {
		xecho $acban Could not open temporary save for $path;
		return;
	};
	@:failed = write($fd # amnesiac ignore file v1 - saved $strftime($time() %D %T)) < 0;
	fe ($_ignore.refs()) refnum {
		@:mask = xform(+ENC $_ignores[$refnum][target]);
		@:deadline = _ignores[$refnum][timeout] ? _ignores[$refnum][timeout] : 0;
		@:reason = xform(+ENC :$_ignores[$refnum][reason]);
		@:line = [^_ignore.load $mask $deadline $reason $_ignores[$refnum][levels]];
		if (write($fd $save.statement($line)) < 0) {
			@failed = 1;
		};
	};
	if (close($fd) != 0) {
		@failed = 1;
	};
	if (save.replace("$path" $failed)) {
		xecho $acban Ignores saved to $path;
	};
};

alias save saveall;
alias saveall {
#core saves
	@_savevar='asave csave fsave fsetsave modsave igsave setsave';
	fe ($_savevar) n1 {
		if (match($n1 $aliasctl(alias match *))) {
			$n1;
		} {xecho Warning: Core alias $n1 not found. Important changes might not be saved;};
	};
#saves from loaded modules
	fe ($listarray(_mods)) n1 {
                if (_modsinfo[$n1][savecmd]) {
			$_modsinfo[$n1][savecmd];
		};
	};
};
