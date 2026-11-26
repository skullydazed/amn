# Copyright (c) 2003-2026 Amnesiac Software Project.
# See the 'COPYRIGHT' file for more information.

package amnesiac::mjoin;

@chansfile=word(0 $_modsinfo.mjoin.savefiles);

## some aliases for mjoin
alias chanlist listchan;
alias addjoin {addchan $*;};
alias ajoin {addchan $*;};
alias unajoin {delchan $*;};
alias deljoin {delchan $*;};
alias mjhelp ajhelp;
##end aliases.

alias addchan {
	if (# < 2 || ! isnumber($1)) {
		xecho $acban Usage: /addchan #chan <window#> [key];
	}{
		@setitem(channel_array 0 !);
		@setitem(channel_array $numitems(channel_array) $0 $1 $2);
		xecho $acban.. added $0 to channel list \(window: $1\);
	};
};

alias listchan {
	if (numitems(channel_array) == 1) {
			xecho $acban no channels current on list;
	}{
xecho -v -- ------------------------------------------------------------------;
		for (@xx=1, xx<numitems(channel_array), @xx++) {
			xecho -v  | $cparse(%K[%n$xx%K]%n) $getitem(channel_array $xx);
		};
xecho -v -- ------------------------------------------------------------------;
	};
};

alias delchan {
	if ( ! # ) {
	    	xecho $acban Usage: /delchan item number | #channel;
     	}{
		if (isnumber($0)) {
			@:thenum = [$0];
		}{
			@:thenum = matchitem(channel_array $0);
			if (thenum < 0) {
				xecho $acban channel $0 not found in the channel list;
				return;
			};
		};
		xecho $acban deleted $getitem(channel_array $thenum) from the list;
		@delitem(channel_array $thenum);
	};
};


alias mjoin {
	for (@xx=1, xx<numitems(channel_array), @xx++) {
		@:cur=getitem(channel_array $xx);
		@:chan = word(0 $cur);
		@:winno = word(1 $cur);
		@:key = word(2 $cur);
		^wjn $winno $chan $key;
	};
};

alias chansave {
	@:path = twiddle($(savepath)$chansfile);
	@:fd = open("${path}.$pid().tmp" wbx);
	if (fd < 0) {
		xecho $acban Could not open temporary save for $path;
		return;
	};
	@:failed = write($fd # amnesiac channel list file v1 - saved $strftime($time() %D %T)) < 0;
	for (@xx=1, xx<numitems(channel_array), @xx++) {
		if (write($fd $save.assignment(chans.$xx $getitem(channel_array $xx))) < 0) {
			@failed = 1;
		};
	};
	if (close($fd) != 0) {
		@failed = 1;
	};
	if (!save.replace("$path" $failed)) {
		return;
	};
	xecho $acban Mjoin channel(s) saved to $(savepath)$chansfile [mod];
};

alias chanload {
	foreach chans entry {
		^assign -chans.$entry;
	};
	save.read "$(savepath)$chansfile";
	@delarray(channel_array);
	@ii = 1;
	@setitem(channel_array 0 !);
	while (chans[$ii]) {
		@setitem(channel_array $ii $chans[$ii]);
		@ii++;
	};
};

alias ajhelp {
		//echo ----------------------= Mjoin Help =---------------------------;
		//echo addchan /addchan #chan <window#> [key] will add specified channel to mjoin;
		//echo addjoin /addjoin #chan <window#> [key] will add specified channel to mjoin;
		//echo delchan /delchan <num> |#chan will delete channel from mjoin list;
		//echo listchan /listchan will show a list of channels on the mjoin list;
		//echo mjoin  /mjoin will join all channels on mjoin list;
		//echo chansave /chansave will save mjoin list;
		//echo chanload /chanload will load mjoin list from $(savepath)$chansfile;
		//echo                   -= Mjoin Quick Aliases =-;
		//echo listc/listchan ajlist/listchan chanlist/listchan;
		//echo addjoin/addchan ajoin/addchan;
		//echo unajoin/delchan deljoin/delchan rmjoin/delchan unjoin/delchan;
		//echo ---------------------------------------------------------------;
};
