if(~send.isNil){ ~send = Bus.audio(s, 2) };
if(~grnlr_bus.isNil){ ~grnlr_bus = Bus.audio(s, 2) };
fork{
	SynthDef(\reverb,{ arg out=0, inBus=0, lowVolume=0.1, revDepth=0.4, fade=1, gate=1;
		var in, snd, local, limited;
		var chans = 2;

		in = Mix.ar(In.ar(inBus, 1) * EnvGen.ar(Env.asr(fade,1,1,1), gate));

		4.do { in = AllpassN.ar(in, 0.03, {Rand(0.005, 0.02)}.dup(chans), 1); };
		// change this between 0.1 and 0,98:
		local = LocalIn.ar(chans) * {revDepth + Rand(0, 0.05)}.dup(chans);
		local = OnePole.ar(local, 0.5);  // 0-1

		//local = Rotate2.ar(local[0], local[1], 0.23);
		local = AllpassN.ar(local, 0.05, {Rand(0.01, 0.05)}.dup(chans), 2);

		local = DelayN.ar(local, 0.3, [0.19, 0.26]);
		local = AllpassN.ar(local, 0.05, { Rand(0.03, 0.15) }.dup(chans), 2);

		local = LeakDC.ar(local);
		local = local + in;

		LocalOut.ar(local);

		snd = Delay2.ar(local);
		DetectSilence.ar(snd + (gate * 100), doneAction:2);

		limited = Limiter.ar(snd * lowVolume, 0.95, 0.01);
		Out.ar(~grnlr_bus, limited);
		Out.ar(~outBus, limited);

	}).add;

	0.1.wait;

	s.sync;
	if(~rsynths.notNil){
		~rsynths.do(_.release);
	};
	~rsynths = [
		Synth(\reverb, [\inBus, ~send, \lowVolume, 1, \depth, 0.6], addAction: \addToTail),
	];
}.value;