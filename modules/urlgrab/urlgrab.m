# Copyright (c) 2003-2026 Amnesiac Software Project.
# See the 'COPYRIGHT' file for more information.

package amnesiac::urlgrab;

@httpsavefile=word(0 $_modsinfo.urlgrab.savefiles);

alias url urlgrab;
alias urlgrab {
        more ${savepath}$httpsavefile;
};

alias rmurl rmgrab;
alias rmgrab {
	if (!@word(2 $stat("${savepath}$httpsavefile"))) {
		xecho $acban url log file does not exist.;
	}{
		input "remove url log? [y|n]: " {
			if ([$0]==[y]) {
				exec -direct -end {
					if (*1 == 0 && *2 == 0) {
						xecho $acban Log deleted;
					} else {
						xecho $acban Could not remove log;
					};
				} rm -- "$twiddle(${savepath}$httpsavefile)";
			}{
				xecho $acban remlog canceled;
			};
		};
	};
};

alias _url_callback {
	@:path = twiddle(${savepath}$httpsavefile);
	@:fd = open("$path" W);
	if (fd < 0) {
		xecho $acban Could not open $path for writing;
		return;
	};
	@:failed = write($fd $strftime(%x at %I:%M:%S %p) $*) < 0;
	if (close($fd) != 0 || failed) {
		xecho $acban Error writing $path;
	};
};

alias urlload {
	^on #-public 33 "% % *http://*" {_url_callback $*;};
	^on #-public 33 "% % *https://*" {_url_callback $*;};
};
alias urlunload {
	^on #-public 33 "% % *http://*" -;
	^on #-public 33 "% % *https://*" -;
};

alias urlhelp {
//echo ------------------------= Urlgrab Help =------------------;

//echo urlgrab  /urlgrab will view urls catched if any;
//echo uurl     /url will view urls catched if any;
//echo rmgrab   /rmgrab will delete url log;
//echo rmurl    /rmurl will remove url log;
//echo ------------------------------------------------------------;
};
