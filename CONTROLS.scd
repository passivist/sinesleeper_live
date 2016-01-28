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
					~grVar.grnlr.vol.valueAction_(val)
				};
				if(cc == 48){
					~grndlPar.amp.valueAction_(val)
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
					~grVar.grnlr.send.valueAction_(val)
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
					~grVar.grnlr.delay.valueAction_(val)
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
		{ ~grVar.grnlr.pos.valueAction_(msg[1]) }.defer;
	}, '/GRNLR/pos');
	OSCdef(\grnlr_rPos, {|msg|
		{ ~grVar.grnlr.rPos.valueAction_(msg[1].lincurve(0, 1, 0, 1, 3)) }.defer;
	}, '/GRNLR/rPos');

	OSCdef(\grnlr_dur, {|msg|
		{ ~grVar.grnlr.dur.valueAction_(msg[1].linexp(0, 1, 0.01, 2)) }.defer;
	}, '/GRNLR/dur');
	OSCdef(\grnlr_rDur, {|msg|
		{ ~grVar.grnlr.rDur.valueAction_(msg[1]) }.defer;
	}, '/GRNLR/rDur');

	OSCdef(\grnlr_fill, {|msg|
		{ ~grVar.grnlr.fillFactor.valueAction_(msg[1].linexp(0, 1, 0.1, 16)) }.defer;
	}, '/GRNLR/fill');
	OSCdef(\grnlr_rFill, {|msg|
		{ ~grVar.grnlr.rFill.valueAction_(msg[1]) }.defer;
	}, '/GRNLR/rFill');

	OSCdef(\grnlr_dir, {|msg|
		{ ~grVar.grnlr.dir.valueAction_(msg[1]) }.defer;
	}, '/GRNLR/dir');

	OSCdef(\grnlr_curve, {|msg|
		{ ~grVar.grnlr.envCurve.valueAction_(msg[1]) }.defer;
	}, '/GRNLR/curve');

	OSCdef(\grnlr_filtLo, {|msg|
		{ ~grVar.grnlr.filtFreqLo.valueAction_(msg[1].linexp(0, 1, 20000, 20)) }.defer;
	}, '/GRNLR/filterLo');
	OSCdef(\grnlr_filtHi, {|msg|
		{ ~grVar.grnlr.filtFreqHi.valueAction_(msg[1].linexp(0, 1, 20, 20000)) }.defer;
	}, '/GRNLR/filterHi');

	OSCdef(\grnlr_qLo, {|msg|
		{ ~grVar.grnlr.qLo.valueAction_(msg[1].linlin(0, 1, 1, 0)) }.defer;
	}, '/GRNLR/qLo');
	OSCdef(\grnlr_qHi, {|msg|
		{ ~grVar.grnlr.qHi.valueAction_(msg[1].linlin(0, 1, 1, 0)) }.defer;
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
		{ ~grndlPar.trans.valueAction_(msg[1]) }.defer;
	}, '/GRNDL/rate');
	OSCdef(\grndl_rRate, {|msg|
		{ ~grndlPar.rRate.valueAction_(msg[1]) }.defer;
	}, '/GRNDL/rRate');

	OSCdef(\grndl_filtLo, {|msg|
		{ ~grndlPar.freqLo.valueAction_(msg[1].linexp(0, 1, 20, 20000)) }.defer;
	}, '/GRNDL/filterLo');
	OSCdef(\grndl_filtHi, {|msg|
		{ ~grndlPar.freqHi.valueAction_(msg[1].linexp(0, 1, 20, 20000)) }.defer;
	}, '/GRNDL/filterHi');

	OSCdef(\grndl_qLo, {|msg|
		{ ~grndlPar.qLo.valueAction_(msg[1]) }.defer;
	}, '/GRNDL/qLo');
	OSCdef(\grndl_qHi, {|msg|
		{ ~grndlPar.qHi.valueAction_(msg[1]) }.defer;
	}, '/GRNDL/qHi');
}.defer;