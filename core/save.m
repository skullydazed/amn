# Copyright (c) 2003-2010 Amnesiac Software Project.
# See the 'COPYRIGHT' file for more information.
if (word(2 $loadinfo()) != [pf]) {
	load -pf $word(1 $loadinfo());
	return;
};

subpackage save;

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
	@:failed = write($fd ** amnesiac config file - saved $strftime($time() %D %T)) < 0;
	if (write($fd notify - $notify()) < 0) {
		@failed = 1;
	};
	@:vars = 'fke1 fke2 fke3 fke4 fke5 fke6 fke7 fke8 fke9 fke10 fke11 fke12 plog crapl msgl notl awayt awayr showop kickops getumode togaway windowdoubles clonecheck bt_ _bt et_ _et _ss _ort _pubnick _tss _ovsize _ovmode acban rfrombuf rsendbuf';
	fe ($vars) cvar {
		if (write($fd assign $cvar $($cvar)) < 0) {
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
	@:failed = 0;
	if (write($fd ** amnesiac settings file - saved $strftime($time() %D %T)) < 0) {
		@failed = 1;
	};
	fe ($symbolctl(pmatch builtin_variable *)) cur {
		if (write($fd set $cur $getset($cur)) < 0) {
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
	@:failed = 0;
	if (write($fd ** amnesiac format file - saved $strftime($time() %D %T)) < 0) {
		@failed = 1;
	};
#fwords is edited in fsets.m
	fe ($fwords) a1 {
		if (write($fd ^sfset format_$a1 $(format_$a1)) < 0) {
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
	@:failed = 0;
	if (write($fd ** amnesiac format file - saved $strftime($time() %D %T)) < 0) {
		@failed = 1;
	};
	if (write($fd assign scdesc $scdesc) < 0) {
		@failed = 1;
	};

	fe ($format_strings ) cvar {
		if (write($fd assign theme.format.$cvar $(theme.format.$cvar)) < 0) {
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
	@:failed = 0;
	@:vars = 'c1 c2 c3 c4 c5 sc1 sc2 sc3 sc4';
	if (write($fd ** amnesiac color format file - saved $strftime($time() %D %T)) < 0) {
		@failed = 1;
	};
	fe ($vars ) cvar {
		if (write($fd assign $cvar $($cvar)) < 0) {
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
	@:failed = 0;
	fe ($ignorectl(REFNUMS)) ref {
		@:mask = ignorectl(GET $ref NICK);
		if (write($fd ^ignore $mask $igtype($mask)) < 0) {
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
