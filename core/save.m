# Copyright (c) 2003-2010 Amnesiac Software Project.
# See the 'COPYRIGHT' file for more information.
if (word(2 $loadinfo()) != [pf]) {
	load -pf $word(1 $loadinfo());
	return;
};

subpackage save;

## Write a complete replacement before moving the previous save to its backup.
alias save.replace (path, failed, void) {
	@:backup = [${path}~];
	@:staged = [${path}.$pid().tmp];
	@:had_save = fexist($path) == 1;
	if (failed || (had_save && rename($path $backup) != 0)) {
		@unlink($staged);
		return 0;
	};
	if (rename($staged $path) != 0) {
		if (had_save) {
			@rename($backup $path);
		};
		@unlink($staged);
		return 0;
	};
	return 1;
};

alias asave {
	@:path = twiddle($(savepath)$savefile);
	@:fd = open(${path}.$pid().tmp wb);
	if (fd < 0) {
		xecho $acban Could not save Amnesiac settings to $path;
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
	@close($fd);
	if (save.replace($path $failed)) {
		xecho $acban Amnesiac settings saved to $path;
	} else {
		xecho $acban Could not save Amnesiac settings to $path;
	};
};

alias setsave {
	@rename($(savepath)$setsavefile $(savepath)$setsavefile~);
        @savemt = open($(savepath)$setsavefile W T);
        @write($savemt ** amnesiac settings file - saved $strftime($time() %D %T));
	fe ($symbolctl(pmatch builtin_variable *)) cur {
		@write($savemt set $cur $getset($cur));
	}
	@close($savemt);
	xecho $acban Epic settings saved to $(savepath)$setsavefile;
};

alias fsetsave {  
	@rename($(savepath)$fsetsavefile $(savepath)$fsetsavefile~);
        @fsetsavemt = open($(savepath)$fsetsavefile W T);
        @write($fsetsavemt ** amnesiac format file - saved $strftime($time() %D %T));
#fwords is edited in fsets.m
	fe ($fwords) a1 {
		@write($fsetsavemt ^sfset format_$a1 $(format_$a1));
	};
	@close($fsetsavemt);
	xecho $acban Fset settings saved to $(savepath)$fsetsavefile;
};

alias fsave {
	@rename($(savepath)$fsavefile $(savepath)$fsavefile~);
        @savemt = open($(savepath)$fsavefile W T);
        @write($savemt ** amnesiac format file - saved $strftime($time() %D %T));
	@write($savemt assign scdesc $scdesc);
	
	fe ($format_strings ) cvar {
		@write($savemt assign theme.format.$cvar $(theme.format.$cvar));
	};
	@close($savemt);
	xecho $acban Format settings saved to $(savepath)$fsavefile;
};

alias csave {
	@:vars = 'c1 c2 c3 c4 c5 sc1 sc2 sc3 sc4';
	@rename($(savepath)$csavefile $(savepath)$csavefile~);
        @savemt = open($(savepath)$csavefile W T);
        @write($savemt ** amnesiac color format file - saved $strftime($time() %D %T));
	fe ($vars ) cvar {
		@write($savemt assign $cvar $($cvar));
	};
	@close($savemt);
	xecho $acban Color settings saved to $(savepath)$csavefile;
};

alias igsave {
	@:path = twiddle($(savepath)$igsfile);
	@:fd = open(${path}.$pid().tmp wb);
	if (fd < 0) {
		xecho $acban Could not save ignores to $path;
		return;
	};
	@:failed = 0;
	fe ($ignorectl(REFNUMS)) ref {
		@:mask = ignorectl(GET $ref NICK);
		if (write($fd ^ignore $mask $igtype($mask)) < 0) {
			@failed = 1;
		};
	};
	@close($fd);
	if (save.replace($path $failed)) {
		xecho $acban Ignores saved to $path;
	} else {
		xecho $acban Could not save ignores to $path;
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
