# Copyright (c) 2003-2026 Amnesiac Software Project.
# See the 'COPYRIGHT' file for more information.
# last modified by skullY 01.12.08 - initial commit
# relaysmtp - Relay messages to and from irc using email
# Original implementation 2007 Aug 12, Zach White (skullY@EFnet)
# Cleaned up and contributed to amnesiac, 2008 Jan 12
#
# This script lets you send and receive irc messages via smtp. You must have
# a way to get email to your irc client. Many carriers support sending email
# via sms, allowing you to use this script to relay via sms.

if (word(2 $loadinfo()) != [pf]) {
	load -pf $word(1 $loadinfo());
	return;
};

package amnesiac::relaysmtp;

# /config stuff
osetitem relaysmtp rsmtpstatus SMTP relay on/off:;
alias config.rsmtpstatus {
	if ([$0]==[-r]) {
		if ([$_modsinfo.relaysmtp.phoneStatus]==[0]) {
			return off;
		} else {
			return on;
		};
	} elif ([$0]==[-s]) {
		# Change or toggle the current status (on/off)
		switch ($1) {
			(on) {
				@_modsinfo.relaysmtp.phoneStatus = 1;
			}
			(off) {
				@_modsinfo.relaysmtp.phoneStatus = 0;
			}
			(toggle) {
				if (_modsinfo.relaysmtp.phoneStatus==0) {
					@_modsinfo.relaysmtp.phoneStatus = 1;
				} {
					@_modsinfo.relaysmtp.phoneStatus = 0;
				};
			};
		};
		xecho -b relaysmtp: Current status is $_modsinfo.relaysmtp.statusType[$_modsinfo.relaysmtp.phoneStatus];
	};
};

osetitem relaysmtp rsmtpemailuser Email username:;
alias config.rsmtpemailuser {
	# The username for the outgoing email
	if ([$0]==[-r]) {
		return $_modsinfo.relaysmtp.emailUser;
	} else if ([$0]==[-l]) {
		@_modsinfo.relaysmtp.emailUser = "$1";
	} else if ([$0]==[-s]) {
		@_modsinfo.relaysmtp.emailUser = "$1";
		xecho -b relaysmtp: Current email username is $_modsinfo.relaysmtp.emailUser;
	};
};

osetitem relaysmtp rsmtpemailpass Email shared key:;
alias config.rsmtpemailpass {
	# The shared key we put in outgoing email
	if ([$0]==[-r]) {
		return $_modsinfo.relaysmtp.emailPass;
	} else if ([$0]==[-l]) {
		@_modsinfo.relaysmtp.emailPass = "$1";
	} else if ([$0]==[-s]) {
		@_modsinfo.relaysmtp.emailPass = "$1";
		xecho -b relaysmtp: Current email shared key is $_modsinfo.relaysmtp.emailPass;
	};
};

osetitem relaysmtp rsmtpemaildomain Email domain:;
alias config.rsmtpemaildomain {
	# The domain we send email from
	if ([$0]==[-r]) {
		return $_modsinfo.relaysmtp.emailDomain;
	} else if ([$0]==[-l]) {
		@_modsinfo.relaysmtp.emailDomain = "$1";
	} else if ([$0]==[-s]) {
		@_modsinfo.relaysmtp.emailDomain = "$1";
		xecho -b relaysmtp: Current email domain is $_modsinfo.relaysmtp.emailDomain;
	};
};

osetitem relaysmtp rsmtpemailsep Email separator:;
alias config.rsmtpemailsep {
	# What separates the components of the email address
	if ([$0]==[-r]) {
		return $_modsinfo.relaysmtp.emailSep;
	} else if ([$0]==[-l]) {
		@_modsinfo.relaysmtp.emailSep = "$1";
	} else if ([$0]==[-s]) {
		@_modsinfo.relaysmtp.emailSep = "$1";
		xecho -b relaysmtp: Current email separator is $_modsinfo.relaysmtp.emailSep;
	};
};

osetitem relaysmtp rsmtpdestaddress Relay destination:;
alias config.rsmtpdestaddress {
	# The address we relay messages to
	if ([$0]==[-r]) {
		return $_modsinfo.relaysmtp.destAddress;
	} else if ([$0]==[-l]) {
		@_modsinfo.relaysmtp.destAddress = "$1";
	} else if ([$0]==[-s]) {
		@_modsinfo.relaysmtp.destAddress = "$1";
		xecho -b relaysmtp: Current relay destination is $_modsinfo.relaysmtp.destAddress;
	};
};

osetitem relaysmtp rsmtpsendmail Sendmail:;
alias config.rsmtpsendmail {
	# The location of the sendmail binary
	if ([$0]==[-r]) {
		return $_modsinfo.relaysmtp.sendmail;
	} else if ([$0]==[-l]) {
		@_modsinfo.relaysmtp.sendmail = "$1";
	} else if ([$0]==[-s]) {
		@_modsinfo.relaysmtp.sendmail = "$1";
		xecho -b relaysmtp: Current sendmail location is $_modsinfo.relaysmtp.sendmail;
	};
};

## Aliases refered to by the config
alias rsmtphelp {
	more $(loadpath)modules/relaysmtp/README;
};

alias rsmtpload {
	^load $(savepath)relaysmtp.save;
};

alias rsmtpsave {
	@:path = twiddle($(savepath)relaysmtp.save);
	@:fd = open("${path}.$pid().tmp" wbx);
	if (fd < 0) {
		xecho $acban Could not open temporary save for $path;
		return;
	};
	@:failed = 0;
	if (write($fd config.rsmtpstatus -l $_modsinfo.relaysmtp.phoneStatus) < 0) {
		@failed = 1;
	};
	if (write($fd config.rsmtpemailuser -l $_modsinfo.relaysmtp.emailUser) < 0) {
		@failed = 1;
	};
	if (write($fd config.rsmtpemailpass -l $_modsinfo.relaysmtp.emailPass) < 0) {
		@failed = 1;
	};
	if (write($fd config.rsmtpemaildomain -l $_modsinfo.relaysmtp.emailDomain) < 0) {
		@failed = 1;
	};
	if (write($fd config.rsmtpemailsep -l $_modsinfo.relaysmtp.emailSep) < 0) {
		@failed = 1;
	};
	if (write($fd config.rsmtpemaildestaddress -l $_modsinfo.relaysmtp.destAddress) < 0) {
		@failed = 1;
	};
	if (write($fd config.rsmtpsendmail -l $_modsinfo.relaysmtp.sendmail) < 0) {
		@failed = 1;
	};
	if (close($fd) != 0) {
		@failed = 1;
	};
	if (!save.replace("$path" $failed)) {
		return;
	};
	xecho -b RelaySMTP settings saved to $(savepath)relaysmtp.save;
};

## Internal aliases
alias _sendmail (ircDest, msg) {
	@:emailAddress = [${_modsinfo.relaysmtp.emailUser}${_modsinfo.relaysmtp.emailSep}${_modsinfo.relaysmtp.emailPass}${_modsinfo.relaysmtp.emailSep}${ircDest}@${_modsinfo.relaysmtp.emailDomain}];
	@:fds = exec($_modsinfo.relaysmtp.sendmail -f $emailAddress $_modsinfo.relaysmtp.destAddress);
	if (numwords($fds) != 3) {
		xecho -b RelaySMTP could not open sendmail pipes;
		return;
	};
	@:in = word(0 $fds);
	@:out = word(1 $fds);
	@:err = word(2 $fds);
	@:failed = close($err) != 0;
	if (write($in To: $_modsinfo.relaysmtp.destAddress) < 0 ||
	    write($in From: $emailAddress) < 0 ||
	    write($in Subject: ${ircDest}!$userhost($ircDest)) < 0 ||
	    write($in) < 0 ||
	    write($in $msg) < 0) {
		@failed = 1;
	};
	if (close($in) != 0) {
		@failed = 1;
	};
	if (close($out) != 0 || failed) {
		xecho -b RelaySMTP error writing to sendmail;
	};
};

# The alias that processes the queue
alias _smtpQueueProcess (void) {
	timer -ref relaysmtp 10 _smtpQueueProcess;
	@:queue = twiddle($_modsinfo.relaysmtp.cmdQueue);
	@:work = [${queue}.work];
	if (!@word(2 $stat("$work"))) {
		@:mode = word(2 $stat("$queue"));
		if (!@mode) {
			return;
		};
		if (left(2 $mode) != [10]) {
			xecho -b RelaySMTP expected a regular queue file at $queue;
			return;
		};
		if (rename("$queue" "$work") != 0) {
			xecho -b RelaySMTP could not move $queue to $work;
			return;
		};
	};
	if (index(r $info(o)) >= 0 && (substr(.zip $work $realpath($work)) >= 0 || substr(.tar $work $realpath($work)) >= 0)) {
		xecho $acban Cannot read $work with this EPIC file reader;
		return;
	};
	@:smtpQueue = open("$work" R);
	if (smtpQueue < 0) {
		xecho $acban Could not open $work for reading;
		return;
	};
	if (unlink("$work") != 0) {
		xecho -b RelaySMTP could not remove $work;
		@:read_failed = ferror($smtpQueue) != 0;
		if (close($smtpQueue) != 0 || read_failed) {
			xecho $acban Error reading $work;
		};
		return;
	};
	while (!eof($smtpQueue)) {
		@:line = read($smtpQueue);
		if (ferror($smtpQueue)) {
			break;
		};
		if (strip(" " $line) != []) {
			@:pass = word(1 $line);
			@:nick = word(2 $line);
			@:msg = afterw($nick $line);
			if (pass == _modsinfo.relaysmtp.emailPass) {
				xecho -b relaysmtp: /msg $nick $msg;
				msg $line;
			};
		};
	};
	@:read_failed = ferror($smtpQueue) != 0;
	if (close($smtpQueue) != 0 || read_failed) {
		xecho $acban Error reading $work;
	};
};

# The hook to send messages to our phone.
^on -MSG * (ircDest, msg) {
	if (msg=[on]) {
		smtp on;
	} elif (msg=[off]) {
		smtp off;
	} elif (cw_modsinfo.relaysmtp.phoneStatus == 1) {
		_sendmail $ircDest $msg;
	} elif (cw_modsinfo.relaysmtp.phoneStatus == 2) {
		# This will eventually be for only getting msged from certain
		# people
		_sendmail $ircDest $msg;
	};
};

# The alias that lets the user turn smtp on and off
alias relaysmtp (status) {
	if ([$status]==[]) {
		xecho -b relaysmtp: Current status is $_modsinfo.relaysmtp.statusType[$_modsinfo.relaysmtp.phoneStatus];
	} {
		config.rsmtpstatus -s $status;
	};
};

# Finish up by starting the queue
_smtpQueueProcess;
