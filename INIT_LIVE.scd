/*
* --------------------------
*	sinesleeper live set
* --------------------------
*/

// ---------------------------------------------------------------- //
// ----------------------- STARTUP ROUTINE ------------------------ //
// ---------------------------------------------------------------- //

s.reboot;
(
fork{
	MIDIClient.init;

	MIDIClient.sources[1].postln;
	MIDIIn.connect(0, MIDIClient.sources[1]);

	~tablet = NetAddr.new("192.168.1.6", 5000);

	//~clock = MIDISyncClock.init;
	~clock = TempoClock.default;
	~outBus = [0, 1];

	0.5.wait;

	if(~send.isNil){ ~send = Bus.audio(s, 2) };
	if(~grnlr_bus.isNil){ ~grnlr_bus = Bus.audio(s, 2) };
	if(~grndl_bus.isNil){ ~grndl_bus = Bus.audio(s, 2) };
};
)
(
fork{
	loadRelative("CONTROLS.scd");
	loadRelative("reverb.scd");
	loadRelative("LOOPER.scd");
	loadRelative("GRNLR_SC/GRNLR_GUI.scd");
	loadRelative("GRNDL/GRNDL.scd");
	loadRelative("PRESETS.scd");
}
)


// ---------------------------------------------------------------- //
// ----------------- for testing debugging etc... ----------------- //
// ---------------------------------------------------------------- //

// PORT:
NetAddr.langPort;

~clock.beats.postln;

(
SynthDef(\ping, { |out, freq|
	var sig, env;
	env = EnvGen.kr(Env.perc(0.001, 0.4, 1, -8), doneAction: 2);
	sig = SinOsc.ar(freq) * env ! 2;
	Out.ar(~outBus, sig * -6.dbamp);
}).add;
)

(
Pdef(
	\clock_test,
	Pbind(
		\instrument, \ping,
		\octave, 7,
		\note, 0,
		\dur, 1
)).play(~clock);
)

Pdef(\clock_test).stop;
