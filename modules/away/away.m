# Copyright (c) 2003-2026 Amnesiac Software Project.
# See the 'COPYRIGHT' file for more information.
if (word(2 $loadinfo()) != [pf]) {
	load -pf $word(1 $loadinfo());
	return;
};

package amnesiac::away;
osetitem away awaytime A-setaway time:;
osetitem away awaytog A-setaway on/off:;
osetitem away awaymsg A-msg:;
osetitem away awaylogmsg A-log msgs:;
osetitem away awaylogcrap A-log crap/miscs:;
osetitem away awaylognotice A-log notices:;
osetitem away awaylogpub A-log public:;


#awaystat is per default 0. Without this awaystat will be undefined.
@awaystat=0;
@awaysavefile=word(0 $_modsinfo.away.savefiles);
alias awayhelp {
	//echo ----------------------= Away Help =---------------------------;
	//echo $cparse("%Wu%nsage%K:%n /remlog         Remove away log");
	//echo $cparse("%Wu%nsage%K:%n /readlog        Read away log");
	//echo $cparse("%Wu%nsage%K:%n /away <reason>  Enter away mode with <reason>");
	//echo $cparse("%Wu%nsage%K:%n /back           Exit away mode");
	//echo $cparse("%Wu%nsage%K:%n /config away    Set away settings");
	//echo $cparse("Away log saved in $(savepath)$awaysavefile");
	//echo ---------------------------------------------------------------;
};

alias remlog  {
	if (!@word(2 $stat("$(savepath)$awaysavefile"))) {
		xecho $acban log file does not exist.;
	}{
		input "remove log? [y|n]: " {
			if ([$0]==[y]) {
				exec -direct -end {
					if (*1 == 0 && *2 == 0) {
						xecho $acban Log deleted;
					} else {
						xecho $acban Could not remove log;
					};
				} rm -- "$twiddle($(savepath)$awaysavefile)";
			}{
				xecho $acban remlog canceled;
			};
		};
	};
};

alias readlog {
	decodemore $(savepath)$awaysavefile;
};

on -idle * {
	if (*0!= 0) {
		if (awayt == *0 && awaystat != 1 && togaway != 'OFF') {
			away autoaway after $0 mins;
			xecho $acban Auto-Away after $0 minutes;
		};
	};
};

on #-connect 1 * {
	if (awaystat) {
		//away away: \($(awaymsg)\) $fparse(format_away);
	};
};

alias away (msg){
	@awayl='on';
	@awaystat=1;
	@awaymsg= @msg > 0 ? msg : awayr;
	//away away: \($(awaymsg)\) $fparse(format_away);
};

alias back {
	if ([$A]) {
		@awayl='off';
		if ( awaystat == 1 ) {
			//away;
			@awaystat=0;
			if (@word(2 $stat("$(savepath)$awaysavefile"))) {
				xecho -v $acban type /readlog to view log.;
			};
		};

	}{
		xecho -v $acban you are not away..;
	};
};

#configs
alias config.awaytime {
	if ( *0 == '-r' ) {
		return $awayt;
	} else if (*0 == '-s') {
		if (# >1) {
			@ awayt = [$1];
		};
		xecho -v $acban away time set to "$awayt";
	};
};

alias config.awaymsg (cmd, reason){
	if ( cmd == '-r' ) {
		return $awayr;
	} else if (cmd == '-s') {
		if (@reason) {
			@ awayr = reason;
		};
		xecho -v $acban away reason set to "$awayr";
	};
};

alias config.awaytog {
	if ( *0 == '-r' ) {
		return $togaway;
	} else if (*0 == '-s') {
		config.matchinput on|off togaway '$1' away toggle;
	};
};

alias config.awaylogcrap {
	if ( *0 == '-r' ) {
		return $crapl;
	} else if (*0 == '-s') {
		config.matchinput on|off crapl '$1' misc crap logging;
	};
};

alias config.awaylogmsg {
	if ( *0 == '-r' ) {
		return $msgl;
	} else if (*0 == '-s') {
		config.matchinput on|off msgl '$1' msg logging;
	};
};

alias config.awaylognotice {
	if ( *0 == '-r' ) {
		return $notl;
	} else if (*0 == '-s') {
		config.matchinput on|off notl '$1' notice logging;
	};
};

alias config.awaylogpub {
	if ( *0 == '-r' ) {
		return $plog;
	} else if (*0 == '-s') {
		config.matchinput on|off plog '$1' public logging;
	};
};

## Wrappers
alias awaytime {
	config.awaytime -s $*;
};

alias awaymsg {
	config.awaymsg -s $*;
};

alias awaytog {
	config.awaytog -s $*;
};

alias logcrap {
	config.awaylogcrap -s $*;
};

alias logm {
	config.awaylogmsg -s $*;
};

alias logn {
	config.awaylognotice -s $*;
};

alias logpub {
	config.awaylogpub -s $*;
};

## cmd line aliases.
alias mlog {logm $*;};
alias clog {logcrap $*;};
alias nlog {logn $*;};
alias playback {readlog;};
alias atog {awaytog $*;};
alias awayt {awaytime $*;};
alias awayr {awaymsg $*;};

## away hook func
alias _awaylog {
	@:path = twiddle($(savepath)$awaysavefile);
	@:fd = open("$path" W);
	if (fd < 0) {
		xecho $acban Could not open $path for writing;
		return;
	};
	@:failed = write($fd $encode($0 $strftime(%x at %I:%M:%S %p) $1-)) < 0;
	if (close($fd) != 0 || failed) {
		xecho $acban Error writing $path;
	};
};

## logging hooks
on #-ctcp 2 "*" {
	if (crapl =='ON' && awaystat && awayl =='ON') {
		^_awaylog CTCP $0 \($userhost()\) requested $2 $3- from $1;
	};
};
on #-msg 4 "*" {
	if (msgl =='ON' && awaystat && awayl =='ON') {
		^_awaylog MSG $0 \($userhost()\) $1-;
	};
};

on #-notice 3 "*" {
	if (notl=='ON'&&awaystat&&awayl=='ON'&&match(*[*#*]* $1-)==0) {
		^_awaylog NOTICE $0 \($userhost()\) $1-;
	};
};

on #-notice 4 "*[*#*]*" {
	if (crapl=='ON'&&awaystat&&awayl=='ON') {
		^_awaylog WALL $*;
	};
};

on #-public_other 4 "*" {
	if (awayl=='ON'&&awaystat&&match(*$servernick()* $2-)&&plog=='ON') {
		^_awaylog PUBLIC <$0:$1> $2-;
	};
};

on #-public 5 "*" {
	if (awayl=='ON'&&awaystat&&match(*$servernick()* $2-)&&plog=='ON') {
		^_awaylog PUBLIC <$0:$1> $2-;
	};
};

on #-kick 33 "$servernick()" {
	if (awayl=='ON'&&awaystat&&crapl=='ON') {
		^_awaylog KICK $1 kicked you off $2 for reason $3-;
	};
};

##away decode func
alias decodemore (cfile) {
	if (@cfile) {
		@ line = 0;
		@ done = 0;
		@ rows = winsize() - 1;
		if (@word(2 $stat("$cfile"))) {
			if (index(r $info(o)) >= 0 && (substr(.zip $cfile $realpath($cfile)) >= 0 || substr(.tar $cfile $realpath($cfile)) >= 0)) {
				xecho $acban Cannot read $cfile with this EPIC file reader;
				return;
			};
			@:fd = open("$cfile" R);
			if (fd < 0) {
				xecho $acban Could not open $cfile for reading;
				return;
			};
			while (!eof($fd) && (pause!='q')) {
				while (line++ != rows) {
					@ ugh = decode($read($fd));
					if (ferror($fd) || (eof($fd) && ugh == [])) {
						@ line = rows;
						@ done = 1;
					} {
						xecho $ugh;
					};
				};
				if (!done) {
					^assign pause $"Enter q to quit, or anything else to continue ";
					@ line = 0;
				};
			};
			@:read_failed = ferror($fd) != 0;
			if (close($fd) != 0 || read_failed) {
				xecho $acban Error reading $cfile;
			};
			@ line = done = rows = pause = ugh = '';
		}{
			xecho -b $cfile\: no such file.;
		};
	};
};
#archon'96
