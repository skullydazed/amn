# Copyright (c) 2003-2026 Amnesiac Software Project.
# See the 'COPYRIGHT' file for more information.

# <hop> in serverlist.m, i'd love to know why you're torturing the poor FULLDESC
#       return value like that. ;-)
# <hop> if the return value isn't usable, i'd rather fix the return value than
#       require you to murder it.
# <hop> so there is a $serverctl(READ_FILE filename)
# <hop> and if you write all of the $serverctl(GET <refnum> FULLDESC) to that
#       file, it'll Just Work(tm).

if (word(2 $loadinfo()) != [pf]) {
	load -pf $word(1 $loadinfo());
	return;
};
alias servload {
};
alias servsave {
	@:path = twiddle($(savepath)servergroups.conf);
	@:fd = open("${path}.$pid().tmp" wbx);
	if (fd < 0) {
		xecho $acban Could not open temporary save for $path;
		return;
	};
	@:failed = 0;
	if (write($fd ** amnesiac servergroups file - saved $strftime($time() %D %T)) < 0) {
		@failed = 1;
	};
	fe ($serverctl(ALLGROUPS)) cg {
		if (write($fd [$cg]) < 0) {
			@failed = 1;
		};
		@:refs=serverctl(GMATCH $cg);
		fe ($refs) cr {
			@:desc=serverctl(GET $cr FULLDESC);
			echo $desc;
			@:sname=before(: $desc);
			@:port=before(: $after(1 : $desc));
			if (@port && port!=6667) {
				@port=":$port";
			}{
				@port="";
			};
			@mstr="$sname$port";
			fe (pass.2 nick.3 type.5 proto.6 vhost.7) cc {
				@:cur=after($after(. $cc) : $desc);
				@cur=before(: $cur);
				if (@cur) {
					@mstr #= ":$before(. $cc)=$cur";
				};
			};

			if (write($fd $mstr) < 0) {
				@failed = 1;
			};
		};
	};
	if (close($fd) != 0) {
		@failed = 1;
	};
	@save.replace("$path" $failed);
};
