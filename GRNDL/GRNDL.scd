// LIVE GRANULATION
// buffer based delay
/*
*	TODO:
*		rework variables as Dictionary like in GRNLR for easier interfacing with MIDI and OSC
*/
(
if(~send.isNil){ ~send = Bus.audio(s, 2) };
if(~grnlr_bus.isNil){ ~grnlr_bus = Bus.audio(s, 2) };
if(~grndl_bus.isNil){ ~grndl_bus = Bus.audio(s, 2) };

s.waitForBoot{
	// AUDIO
	var bufLength, buffer, feedBus, pan;

	// GUI
	var win;
	// CONTROLS
	~grndlPar = ();

	////////////////////////////////////////////////////////////
	// ----------------------- GUI -------------------------- //
	////////////////////////////////////////////////////////////
	win = Window.new("grndl", Rect(880, 440, 400, 300), false);

	win.onClose_{
		Tdef(\grndl).stop;
	};

	~grndlPar.put(\pos,
		EZKnob.new(win,
			Rect(10, 0, 40, 80),
			"pos",
			[0.01, 1, 'lin', 0, 0.1],
			initAction: true,
	));

	~grndlPar.put(\rPos,
		EZNumber.new(win,
			Rect(10, 85, 40, 40),
			"rPos",
			[0, 1, 'lin', 0, 0],
			initAction: true,
			layout: 'line2'
	));

	~grndlPar.put(\dur,
		EZKnob.new(win,
			Rect(60, 0, 40, 80),
			"dur",
			[0.01, 2,'exp', 0, 1],
			initAction: true,
	));

	~grndlPar.put(\rDur,
		EZNumber.new(win,
			Rect(60, 85, 40, 40),
			"rDur",
			[0, 1, 'lin', 0, 0],
			initAction: true,
			layout: 'line2'
	));

	~grndlPar.put(\fill,
		EZKnob.new(win,
			Rect(110, 0, 40, 80),
			"fill",
			[0.01, 6, 'lin', 0, 1],
			initAction: true,
	));

	~grndlPar.put(\rFill,
		EZNumber.new(win,
			Rect(110, 85, 40, 40),
			"rFill",
			[0, 1, 'lin', 0, 0],
			initAction: true,
			layout: 'line2'
	));

	~grndlPar.put(\trans,
		EZKnob.new(win,
			Rect(160, 0, 40, 80),
			"rate",
			[-12, 12, 'lin', 1, 0],
			initAction: true,
	));

	~grndlPar.put(\rRate,
		EZNumber.new(win,
			Rect(160, 85, 40, 40),
			"rRate",
			[0, 1, 'lin', 0, 0],
			initAction: true,
			layout: 'line2'
	));

	~grndlPar.put(\freqLo,
		EZKnob.new(win,
			Rect(10, 130, 40, 80),
			"freqLo",
			[20, 20000, 6, 0, 20000],
			initAction: true,
	));

	~grndlPar.put(\rFreqLo,
		EZNumber.new(win,
			Rect(10, 215, 40, 40),
			"rLo",
			[0, 1, 'lin', 0, 0],
			initAction: true,
			layout: 'line2'
	));

	~grndlPar.put(\qLo,
		EZNumber.new(win,
			Rect(10, 255, 40, 40),
			"qLo",
			[0, 1, 'lin', 0, 1],
			initAction: true,
			layout: 'line2'
	));

	~grndlPar.put(\freqHi,
		EZKnob.new(win,
			Rect(60, 130, 40, 80),
			"freqHi",
			[20, 20000, 6, 0, 20],
			initAction: true,
	));

	~grndlPar.put(\rFreqHi,
		EZNumber.new(win,
			Rect(60, 215, 40, 40),
			"rHi",
			[0, 1, 'lin', 0, 0],
			initAction: true,
			layout: 'line2'
	));

	~grndlPar.put(\qHi,
		EZNumber.new(win,
			Rect(60, 255, 40, 40),
			"qHi",
			[0, 1, 'lin', 0, 1],
			initAction: true,
			layout: 'line2'
	));

	~grndlPar.put(\feed,
		EZKnob.new(win,
			Rect(110, 130, 40, 80),
			"feed",
			[0, 2, 'lin', 0, 0],
			initAction: true,
	));

	~grndlPar.put(\rFeed,
		EZNumber.new(win,
			Rect(110, 215, 40, 40),
			"rFeed",
			[0, 1, 'lin', 0, 0],
			initAction: true,
			layout: 'line2'
	));

	~grndlPar.put(\amp,
		EZKnob.new(win,
			Rect(160, 130, 40, 80),
			"amp",
			[0, 1, 'lin', 0, 1],
			initAction: true,
	));

	~grndlPar.put(\rAmp,
		EZNumber.new(win,
			Rect(160, 215, 40, 40),
			"rAmp",
			[0, 1, 'lin', 0, 0],
			initAction: true,
			layout: 'line2'
	));

	~grndlPar.put(\lfoLength,
		EZKnob.new(win,
			Rect(220, 0, 40, 80),
			"length",
			[0.125, 16, 'lin', 0.125, 1],
			initAction: true,
	));

	~grndlPar.put(\lfoAmt,
		EZKnob.new(win,
			Rect(270, 0, 40, 80),
			"amt",
			[0, 1, 'lin', 0, 0],
			initAction: true,
	));

	~grndlPar.put(\send,
		EZKnob.new(win,
			Rect(220, 130, 40, 80),
			"send",
			[0, 1, 'lin', 0, 0],
			initAction: true,
	));

	win.drawFunc_{
		Pen.smoothing_(false);
		Pen.line(210@0, 210@300);
		Pen.stroke;
	};

	// some cleanup:
	win.onClose_{
		Tdef(\grndl).stop;
		Tdef(\grndlPan).stop;
		Ndef(\pos).free;
		Ndef(\write).free;
		Ndef(\off).free;
	};

	////////////////////////////////////////////////////////////
	// -------------------- AUDIO --------------------------- //
	////////////////////////////////////////////////////////////

	bufLength = 2;
	buffer = Buffer.alloc(s, bufLength * s.sampleRate, 2);

	if(~feedBus.isNil){~feedBus = Bus.audio(s, 2) };

	Ndef(\pos, { LFSaw.ar(1/bufLength).range(0, 1) ! 2 });

	Ndef(\write, { |write = 0|
		var sig;
		BufWr.ar(
			(In.ar(~grndl_bus) + In.ar(~feedBus) ).tanh,
			buffer, BufFrames.kr(buffer) * Ndef.ar(\pos)
		);
	});

	Ndef(\write).fadeTime = 0.5;

	SynthDef(\grndl, {|out, buf, pos=0.1, dur=0.5, fill, freqHi=60, freqLo=200, qHi=1, qLo=1, rate=1, amp=1, feed=0.1, panPos, send=0|
		var env, sig;
		env = Env.new([0,1,1,0], (fill * dur) * (1/3 ! 3), [-3, 1, 3]);
		env = EnvGen.ar(env, doneAction: 2);
		pos = pos * Rand(0.99, 1.01 ! 2);
		sig = PlayBuf.ar(2, buf, rate, startPos: pos.wrap(0, 1) * BufFrames.kr(buf));
		sig = HPF.ar(sig, 30).tanh;
		sig = RHPF.ar( RLPF.ar(sig, freqLo, qLo), freqHi, qHi);
		//sig = Balance2.ar(sig[0], sig[1], pan);
		sig = sig * panPos.linlin(-1, 1, 0, 1);
		sig = sig * env;

		Out.ar(~feedBus, sig * feed);
		Out.ar(~send, (sig * amp) * send);
		Out.ar(~outBus, sig * amp)
	}).add;

	////////////////////////////////////////////////////////////
	// ------------------- CONTROL -------------------------- //
	////////////////////////////////////////////////////////////

	Tdef(\grndlPan, {
		var i = 0;
		loop{
			i = (i + 1) % (~grndlPar.lfoLength.value * 24);
			pan = ((i / (~grndlPar.lfoLength.value * 24))).linlin(0, 1, -1, 1) * ~grndlPar.lfoAmt.value;
			pan = (pan * 3).tanh;
			(1/24).wait;
		}
	}).play(~clock);

	Tdef(\grndl, {
		loop{
			var localDur = ~grndlPar.dur.value * (~grndlPar.rDur.value.rand + (1 - (~grndlPar.rDur.value/2))).clip(0.01, 2);

			Synth(\grndl, [
				\buf,		buffer,
				\pos,		Ndef(\off, { Ndef.ar(\pos) + (~grndlPar.pos.value * rand(~grndlPar.rPos.value)) }),
				\rate,	~grndlPar.trans.value.midiratio * (~grndlPar.rRate.value.rand + (1 - (~grndlPar.rRate.value/2))),
				\fill,	~grndlPar.fill.value * (~grndlPar.rFill.value.rand + (1 - (~grndlPar.rFill.value/2))),
				\feed,	(~grndlPar.feed.value * (~grndlPar.rFeed.value.rand + (1 - (~grndlPar.rFeed.value/2)))).clip(0, 2),
				\dur,		localDur,
				\freqHi, (~grndlPar.freqHi.value * (~grndlPar.rFreqHi.value + (1 - (~grndlPar.rFreqHi.value/2)))).clip(20, 20000),
				\qHi,		~grndlPar.qHi.value,
				\freqLo, (~grndlPar.freqLo.value * (~grndlPar.rFreqLo.value + (1 - (~grndlPar.rFreqLo.value/2)))).clip(20, 20000),
				\qLo,		~grndlPar.qLo.value,
				\send,	~grndlPar.send.value,
				\panPos,	~grndlPar.pan,
				\amp, 	(~grndlPar.amp.value * (~grndlPar.rAmp.value + (1 - (~grndlPar.rAmp.value / 2)))).clip(0, 1)
			]);
			localDur.wait;
		}
	}).play;

	win.front
}
)