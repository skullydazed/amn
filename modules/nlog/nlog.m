# Copyright (c) 2003-2010 Amnesiac Software Project.
# See the 'COPYRIGHT' file for more information.

if (word(2 $loadinfo()) != [pf]) {
	load -pf $word(1 $loadinfo());
	return;
};

subpackage nlog;
osetitem misc nlog Log notify signoffs:;

@nfile=word(0 $_modsinfo.nlog.savefiles);
@nlogfile=word(1 $_modsinfo.nlog.savefiles);
@nsolog='off';

on #-hook 10 "amnesiac_notify *" {
	if (*1 == [SignOff] && nsolog != [on]) {
		return;
	};
	@:path = twiddle($(savepath)$nlogfile);
	@:fd = open("$path" W);
	if (fd < 0) {
		xecho $acban Could not open $path for writing;
		return;
	};
	@:failed = write($fd $toupper($1) by $2 on $strftime(%x at %X)) < 0;
	if (close($fd) != 0 || failed) {
		xecho $acban Error writing $path;
	};
};

alias config.nlog {
	if ( *0 == '-r' ) {
		return $nsolog;
	} else if (*0 == '-s') {
		config.matchinput on|off nsolog '$1' notify signoff log;
	};
};

alias nsotog {
	config.nlog -s $*;
};

# notify aliases.
alias rnlog  {
	if (!@word(2 $stat("$(savepath)$nlogfile"))) {
		xecho $acban notify log file does not exist.;
	}{              
		input "remove log? [y|n]: " {
			if (*0=='y') {
				exec -direct -end {
					if (*1 == 0 && *2 == 0) {
						xecho $acban Log deleted;
					} else {
						xecho $acban Could not remove log;
					};
				} rm -- "$twiddle($(savepath)$nlogfile)";
			}{
				xecho $acban rnlog canceled;
			};
		};
	};
};


alias ncache {
	more $(savepath)$nlogfile;
};

alias nlist ncache;
alias rmnlog rnlog;

alias nsave {
	@:path = twiddle($(savepath)$nfile);
	@:fd = open("${path}.$pid().tmp" wbx);
	if (fd < 0) {
		xecho $acban Could not open temporary save for $path;
		return;
	};
	@:failed = 0;
	if (write($fd @nsolog=[$nsolog]) < 0) {
		@failed = 1;
	};
	if (close($fd) != 0) {
		@failed = 1;
	};
	if (!save.replace("$path" $failed)) {
		return;
	};
	xecho $acban Notify settings saved to $nfile [mod];
};

alias nload {
	if (@word(2 $stat("$(savepath)$nfile"))) {
		load $(savepath)$nfile;
	};
};
