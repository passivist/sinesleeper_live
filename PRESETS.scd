(
/*
*	TODO:
*		add sendMsg to tablet
*/
~savePreset = { |name, dict|
	var file, valDict, innerDict;

	file = File.open(("PRESETS/" ++ name.asString ++ ".scd").resolveRelative.standardizePath, "w+");
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

	dict = load(("PRESETS/" ++ name.asString ++ ".scd").resolveRelative.standardizePath);
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

/*
~savePreset.value("current_piano", ~grVar);
~loadPreset.value("current_piano");
~grVar.postcs;
*/