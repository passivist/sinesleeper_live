(
~savePreset = { |name, dict|
	var file, valDict, innerDict;

	file = File.open(("PRESETS/" ++ name.asString ++ ".scd").resolveRelative, "w+");
	valDict = ();


	dict.keysValuesDo{ |outKey, outVal|
		innerDict = ();
		outVal.keysValuesDo{ |key, val|
			if(val.isKindOf(EZGui) || val.isKindOf(Button) || val.isKindOf(Slider)){
				innerDict.put(key, val.value);
			}{
				innerDict.put(key, val.cs);
			}
		};
		valDict.put(outKey, innerDict)
	};
	valDict.postcs;

	file.write(valDict.cs);
	file.close;
};

~loadPreset = {|name|
	var dict, buf;

	dict = load(("PRESETS/" ++ name.asString ++ ".scd").resolveRelative);
	dict.keysValuesDo{ |outKey, outVal|
		var subDict = dict[outKey];
		subDict.keysValuesDo{ |key, val|
			var obj = ~grVar[outKey][key];

			if(obj.isKindOf(EZGui) || obj.isKindOf(Slider) || obj.isKindOf(Button)){
				obj.valueAction_(val);
			};
			if(obj.isKindOf(Env)){
				var env = val.compile.value;
				~grVar[outKey][key] = env;
				~grVar[outKey][\envView].setEnv(env);
			}
		}
	};

	if(dict[\grnlr][\path].notNil){
		buf = Buffer.read(s, dict[\grnlr][\path]);
		~grnlrPar.waveform.load(dict[\grnlr][\path]);
		{ 0.1.wait; ~loadSynth.value(buf, ~grnlr_bus) }.fork(AppClock)
	}

};
)
~grVar['seqPos']['env'] = Env([0, 1], 1);
~grVar['seqPos']['envView'].setEnv(Env([0, 1], 1))
~grVar['seqPos']['env'].cs
/*
~savePreset.value("seqTest", ~grVar);
~loadPreset.value("seqTest");
~grVar.postcs;
*/

/*

buf = Buffer.read(s, path);														// load dragged sample into buffer
buf.postln;

waveform.load(path);																	// load waveform into SoundFileView
{ 0.1.wait; ~loadSynth.value(buf, ~grnlr_bus) }.fork(AppClock)			// build synthdef with buffer


*/