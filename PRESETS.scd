~savePreset = { |name, dict|
	var file, valDict;

	file = File.open(("PRESETS/" ++ name.asString ++ ".scd").resolveRelative, "w+");
	valDict = ();

	dict.keysValuesDo{|key, val| valDict.put(key, val.value)};

	file.write(valDict.cs);
	file.close;
};

~loadPreset = {|name|
	var dict, buf;

	dict = load(("PRESETS/" ++ name.asString ++ ".scd").resolveRelative);
	dict.keysValuesDo{|key, val|
		var obj = ~grnlrPar[key];
		if(obj.isKindOf(EZNumber) || obj.isKindOf(EZKnob)){
			[key, val].postln;
			obj.valueAction_(val);
		};
	};

	if(dict[\path].notNil){
		buf = Buffer.read(s, dict[\path]);
		~grnlrPar.waveform.load(dict[\path]);
		{ 0.1.wait; ~loadSynth.value(buf, ~grnlr_bus) }.fork(AppClock)
	}
};

/*
~savePreset.value("surge_perc", ~grnlrPar);
~loadPreset.value("surge_perc");
*/

/*

buf = Buffer.read(s, path);														// load dragged sample into buffer
buf.postln;

waveform.load(path);																	// load waveform into SoundFileView
{ 0.1.wait; ~loadSynth.value(buf, ~grnlr_bus) }.fork(AppClock)			// build synthdef with buffer


*/