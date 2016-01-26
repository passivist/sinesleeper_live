/*
* ----------------MIDI MAPPING---------------------
* TODO:
* 		Werte Abholen: Aktuellen stand der MIDI werte buffern sobald die Mode geändert wird,
*		wenn Mode dann wieder den selben wert erreicht diese werte mit den incoming midi werten vergleichen
*/

{
	var win = Window.new("buttonstate", 110@50, false);
	var text = StaticText.new(win, 110@50);
	var mode = 0;

	text.string = "sends / delay";
	text.align_(\center);

	//win.front;

	MIDIdef.cc(\tracks, { |val, cc|
		val = val / 127;
		{
			if(cc < 47){
				~looperLevels[cc - 41].valueAction_(val)
			}{
				if(cc == 47){
					~grnlrPar.vol.valueAction_(val)
				};
				if(cc == 48){
					~grndlPar.vol.valueAction_(val)
				}
			}
		}.defer
	}, (41 .. 48) );

	MIDIdef.cc(\knobsA, { |val, cc|
		val = val / 127;
		{
			if(cc < 37){
				if(mode==0){
					~looperSends[cc - 31].valueAction_(val)
				}{
					~looperLfoAmt[cc - 31].valueAction_(val)
				}

			}{
				if(cc == 37){
					~grnlrPar.send.valueAction_(val)
				};
				if(cc == 38){
					~grndlPar.send.valueAction_(val)
				}
			}


		}.defer
	}, (31 .. 38) );

	MIDIdef.cc(\knobsB, { |val, cc|
		val = val / 127;
		{
			if(cc < 27){
				if(mode==0){
					~looperDelays[cc - 21].valueAction_(val)
				}{
					~looperLfoFreq[cc - 21].valueAction_(val.linexp(0, 1, 1, 40))
				}

			}{
				if(cc == 27){
					~grnlrPar.delay.valueAction_(val)
				};
				if(cc == 28){
					~grndlPar.feed.valueAction_(val.linlin(0, 1, 0, 2))
				}
			}

		}.defer
	}, (21 .. 28) );

	MIDIdef.cc(\modeselector, {|val, cc|
		if(val > 0){
			{
				switch(cc,
					71, {
						text.string = "sends / delay";
						mode = 0;
					},
					72, {
						text.string = "panning";
						mode = 1;
					},
				);
				win.refresh;
			}.defer;
		}
	}, (71 .. 74));

	MIDIdef.cc(\presets, {|val, cc|
		if(val > 0){
			{
				switch(cc,
					88, { ~loadPreset.value("INIT") }
				)
			}.defer;
		}
	}, (81 ..88));

	// GRNLR
	OSCdef(\grnlr_pos, {|msg|
		{ ~grnlrPar.pos.valueAction_(msg[1]) }.defer;
	}, '/GRNLR/pos');
	OSCdef(\grnlr_rPos, {|msg|
		{ ~grnlrPar.rPos.valueAction_(msg[1].lincurve(0, 1, 0, 1, 3)) }.defer;
	}, '/GRNLR/rPos');

	OSCdef(\grnlr_dur, {|msg|
		{ ~grnlrPar.dur.valueAction_(msg[1].linexp(0, 1, 0.01, 2)) }.defer;
	}, '/GRNLR/dur');
	OSCdef(\grnlr_rDur, {|msg|
		{ ~grnlrPar.rDur.valueAction_(msg[1]) }.defer;
	}, '/GRNLR/rDur');

	OSCdef(\grnlr_fill, {|msg|
		{ ~grnlrPar.fillFactor.valueAction_(msg[1].linexp(0, 1, 0.1, 16)) }.defer;
	}, '/GRNLR/fill');
	OSCdef(\grnlr_rFill, {|msg|
		{ ~grnlrPar.rFill.valueAction_(msg[1]) }.defer;
	}, '/GRNLR/rFill');

	OSCdef(\grnlr_dir, {|msg|
		{ ~grnlrPar.dir.valueAction_(msg[1]) }.defer;
	}, '/GRNLR/dir');

	OSCdef(\grnlr_curve, {|msg|
		{ ~grnlrPar.envCurve.valueAction_(msg[1]) }.defer;
	}, '/GRNLR/curve');

	OSCdef(\grnlr_filtLo, {|msg|
		{ ~grnlrPar.filtFreqLo.valueAction_(msg[1].linexp(0, 1, 20000, 20)) }.defer;
	}, '/GRNLR/filterLo');
	OSCdef(\grnlr_filtHi, {|msg|
		{ ~grnlrPar.filtFreqHi.valueAction_(msg[1].linexp(0, 1, 20, 20000)) }.defer;
	}, '/GRNLR/filterHi');

	OSCdef(\grnlr_qLo, {|msg|
		{ ~grnlrPar.qLo.valueAction_(msg[1].linlin(0, 1, 1, 0)) }.defer;
	}, '/GRNLR/qLo');
	OSCdef(\grnlr_qHi, {|msg|
		{ ~grnlrPar.qHi.valueAction_(msg[1].linlin(0, 1, 1, 0)) }.defer;
	}, '/GRNLR/qHi');

	// GRNDL
	OSCdef(\grndl_pos, {|msg|
		{ ~grndlPar.pos.valueAction_(msg[1]) }.defer;
	}, '/GRNDL/pos');
	OSCdef(\grndl_rPos, {|msg|
		{ ~grndlPar.rPos.valueAction_(msg[1].lincurve(0, 1, 0, 1, 3)) }.defer;
	}, '/GRNDL/rPos');

	OSCdef(\grndl_dur, {|msg|
		{ ~grndlPar.dur.valueAction_(msg[1].linexp(0, 1, 0.01, 2)) }.defer;
	}, '/GRNDL/dur');
	OSCdef(\grndl_rDur, {|msg|
		{ ~grndlPar.rDur.valueAction_(msg[1]) }.defer;
	}, '/GRNDL/rDur');

	OSCdef(\grndl_fill, {|msg|
		{ ~grndlPar.fill.valueAction_(msg[1].linexp(0, 1, 0.1, 6)) }.defer;
	}, '/GRNDL/fill');
	OSCdef(\grndl_rFill, {|msg|
		{ ~grndlPar.rFill.valueAction_(msg[1]) }.defer;
	}, '/GRNDL/rFill');

	OSCdef(\grndl_rate, {|msg|
		{ ~grndlPar.rate.valueAction_(msg[1]) }.defer;
	}, '/GRNDL/rate');
	OSCdef(\grndl_rRate, {|msg|
		{ ~grndlPar.rRate.valueAction_(msg[1]) }.defer;
	}, '/GRNDL/rRate');

	OSCdef(\grndl_filtLo, {|msg|
		{ ~grndlPar.filtLo.valueAction_(msg[1].linexp(0, 1, 20, 20000)) }.defer;
	}, '/GRNDL/filterLo');
	OSCdef(\grndl_filtHi, {|msg|
		{ ~grndlPar.filtHi.valueAction_(msg[1].linexp(0, 1, 20, 20000)) }.defer;
	}, '/GRNDL/filterHi');

	OSCdef(\grndl_qLo, {|msg|
		{ ~grndlPar.qLo.valueAction_(msg[1]) }.defer;
	}, '/GRNDL/qLo');
	OSCdef(\grndl_qHi, {|msg|
		{ ~grndlPar.qHi.valueAction_(msg[1]) }.defer;
	}, '/GRNDL/qHi');
}.defer;