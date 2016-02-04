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

LID.initializeLID;
LID.findAvailable;
~joy = LID.openPath("/dev/input/event11");


(
fork{
	MIDIClient.init;

	MIDIClient.sources[3].postln;
	MIDIIn.connect(0, MIDIClient.sources[1]);
	//MIDIIn.connect(0, MIDIClient.sources[0]);
	MIDIIn.connect(0, MIDIClient.sources[3]);

	~tablet = NetAddr.new("192.168.1.19", 5000);

	// ~clock = MIDISyncClock.init;
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
	loadRelative("CONTROLS/MIDI.scd");
	//loadRelative("CONTROLS/JOYSTICK.scd");
	loadRelative("CONTROLS/OSC.scd");
	loadRelative("reverb.scd");
	// loadRelative("LOOPER.scd");
	loadRelative("GRNLR_SC/GRNLR_GUI.scd");
	loadRelative("GRNDL/GRNDL.scd");
	loadRelative("PRESETS.scd");
}
)


// ---------------------------------------------------------------- //
// ----------------- for testing debugging etc... ----------------- //
// ---------------------------------------------------------------- //
LID.closeAll;

~grndl_bus.scope
// PORT:
NetAddr.langPort;

~clock.beats.postln;
~outBus = [12, 13];
(
SynthDef(\ping, { |out, freq|
	var sig, env;
	env = EnvGen.kr(Env.perc(0.0001, 0.1, 1, -8), doneAction: 2);
	sig = Blip.ar(freq ! 2) * env;
	Out.ar(~outBus, sig * -6.dbamp);
}).add;
)

(
Tdef(\clock_test, { loop{
	~clock.beats.postln;
	if(~clock.beats.floor % 4 == 0){
		Synth(\ping, [\freq, 2500]);
	}{
		Synth(\ping, [\freq, 1500]);
	};
	1.wait;
}}).play(~clock);
)
(
SynthDef(\git, {|out, input=0|
	var sig = SoundIn.ar(input, 1).tanh;
	sig = sig ! 2;
	Out.ar(~grndl_bus, sig);
	Out.ar(~send, sig * 0.3);
	Out.ar(out, sig);
}).add
)

~git = Synth(\git, [\input, 3]);
~git.free
Tdef(\clock_test).stop;

(
MIDIdef.noteOn(\noteOn, {|vel, note|
	if(~firstNote.isNil){
		~notes = ();
		~firstNote = note;
	};
	~notes.put(note.asSymbol, note);
}, chan: 0);
)