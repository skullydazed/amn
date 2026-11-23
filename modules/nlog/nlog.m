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
	@:fd = open("$twiddle($(savepath)$nlogfile)" W);
	if (fd >= 0) {
		@write($fd $toupper($1) by $2 on $strftime(%x at %X));
		@close($fd);
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
	if (fexist($(savepath)$nlogfile) == -1) {
		xecho $acban notify log file does not exist.;
	}{              
		input "remove log? [y|n]: " {
			if (*0=='y') {
				exec rm $(savepath)$nlogfile;
				xecho $acban $(savepath)$nlogfile deleted;
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
	@rename($(savepath)$nfile $(savepath)$nfile~);
    	@savemt = open($(savepath)$nfile W T);
       	@write($savemt @nsolog=[$nsolog]);
	@close($savemt);
	xecho $acban Notify settings saved to $nfile [mod];
};

alias nload {
	if (fexist($(savepath)$nfile) == 1) {
		load $(savepath)$nfile;
	};
};
