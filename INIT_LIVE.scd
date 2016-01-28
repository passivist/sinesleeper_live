/*
* --------------------------
*	sinesleeper live set
* --------------------------
*/

// ---------------------------------------------------------------- //
// ----------------------- STARTUP ROUTINE ------------------------ //
// ---------------------------------------------------------------- //
s.latency_(nil);
s.reboot;
(
fork{
	MIDIClient.init;

	// MIDIIn.connect(0, MIDIClient.sources[3]);
	// MIDIIn.connect(0, MIDIClient.sources[5]);

	~tablet = NetAddr.new("192.168.0.175", 5000);

	//~clock = MIDISyncClock.init;
	~clock = TempoClock.default.tempo = 2;
	~outBus = [0, 1];

	0.3.wait;

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
~grndl_bus.scope
// PORT:
NetAddr.langPort;

~clock.beats.postln;

(
SynthDef(\ping, { |out, freq|
	var sig, env;
	env = EnvGen.kr(Env.perc(0.001, 0.05, 1, -8), doneAction: 2);
	sig = Blip.ar(freq ! 2, 5) * env;
	Out.ar(~outBus, sig * -6.dbamp);
}).add;
)

(
Tdef(\clock_test, { loop{
	if(~clock.beats % 4 == 0){
		Synth(\ping, [\freq, 2500]);
	}{
		Synth(\ping, [\freq, 1500]);
	};
	1.wait;
}}).play(~clock);
)

Tdef(\clock_test).stop;


