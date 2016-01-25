/* sine sleeper live set:
*	funktionalität:
*		ableton style session view with tracks and loops start, stop, record and overdub
*
*  TODO:
*		overdub funktionalität
*		implement drag and drop functionality between GRNLR and the looper:
*			you should be able to drag cells into GRNLR and have the corresponding buffer load
*
*		make grid interface for controlling via midi or osc
*
*		track volume sometimes doesn't work
*
*
*/


// LOOPER:

if(~send.isNil){ ~send = Bus.audio(s, 2) };
if(~grnlr_bus.isNil){ ~grnlr_bus = Bus.audio(s, 2) };
if(~grndl_bus.isNil){ ~grndl_bus = Bus.audio(s, 2) };

s.waitForBoot {
	// GUI
	var win, clipCells, recordButtons, stopButtons, sendKnobs, delayKnobs, lfoAmtKnobs, lfoFreqKnobs, levelSliders;

	// Interaction
	var updateMouseAction, mouseActionPlay, mouseActionStop, mouseActionRecording;
	var updateCellAction;

	// Control
	var bpm, clock;

	// Audio
	var busses, tracks;

	////////////////////////////////////////////////////////////
	// -------------------- AUDIO --------------------------- //
	////////////////////////////////////////////////////////////

	busses = Array.fill(8, { Bus.audio(s, 2) });
	{
		SynthDef(\recorder, {|bus, buf, preLevel=0, loop=0|
			var in, rec;
			in = In.ar(~grnlr_bus, 2);
			rec = RecordBuf.ar(in, buf, 0, 1, preLevel, 1, loop, 1, 2);
		}).add;

		SynthDef(\player, {|bus, buf, loop=0|
			var sig;
			sig = PlayBuf.ar(2, buf, 1, 1, 0, loop, 2);
			Out.ar(bus, sig)
		}).add;

		SynthDef(\track, {|out, in, amp=0, send=0, delay=0, lfoFreq=1, lfoAmt=0|
			var sig, lfo;
			lfo = LFSaw.kr(lfoFreq, mul: lfoAmt * 2).tanh;
			sig = In.ar(in, 2) * amp;
			sig = Balance2.ar(sig[0], sig[1], lfo);
			Out.ar(~send, sig * send);
			Out.ar(~grndl_bus, sig * delay);
			Out.ar(~outBus, sig);
		}).add;

		s.sync;

		tracks = Array.fill(8, { |i|
			Synth(\track, [ \in, busses[i] ])
		});
	}.fork;


	////////////////////////////////////////////////////////////
	// ----------------------- GUI -------------------------- //
	////////////////////////////////////////////////////////////

	win = Window.new("looper", 660@450, false, true);

	clipCells = {
		var array = Array.fill2D(6, 8, {|row, col| PlaySlot.new(win, row, col)} );
		s.sync;
		array
	}.value;

	//clipCells[0][2].buffer_( Buffer.read(s, "/Volumes/MacHD 750 1/AudioVideo/Samples/EIGENE/Rythmic/Gitarre Perc/GitLoop_A_120A.wav")).name_("BE_A");

	// associate busses with PlaySlots
	6.do{ |i|
		clipCells[i].do{ |cell|
			cell.bus = busses[i];
		};
	};

	recordButtons 	= Array.fill(6, { |i| RecordButton.new(win, i) });
	stopButtons 	= Array.fill(6, { |i|   StopButton.new(win, i) });

	// draw track controls
	levelSliders = Array.fill(6, { |i|
		EZSlider.new(win,
			Rect((i * 110) + 10, 330, 40, 110),
			nil,
			[0, 1, 'lin', 0, 0.7],
			{|slider|
				var val = slider.value;
				tracks[i].set(\amp, val);
				val.postln
			},
			0,
			false,
			30, 30, 0, 20, 'vert'
		)
	});

	// make sliders global
	~looperLevels = levelSliders;

	sendKnobs = Array.fill(6, { |i|
		EZKnob.new  (win,
			Rect((i * 110) + 60, 335, 40, 50),
			nil,
			[0, 1, 'lin', 0, 0],
			{ |knob|
				var val = knob.value;
				tracks[i].set(\send, val)
			},
		)
	});
	// make sliders global
	~looperSends = sendKnobs;

	delayKnobs = Array.fill(6, { |i|
		EZKnob.new  (win,
			Rect((i * 110) + 60, 390, 40, 50),
			nil,
			[0, 1, 'lin', 0, 0],
			{ |knob|
				var val = knob.value;
				tracks[i].set(\delay, val)
			},
		)
	});
	~looperDelays = delayKnobs;

	lfoAmtKnobs = Array.fill(6, { |i|
		EZKnob.new(win,
			Rect((i * 110) + 10, 280, 40, 50),
			nil,
			[0, 1, 'lin', 0, 0],
			{ |knob|
				var val = knob.value;
				tracks[i].set(\lfoAmt, val)
			}
		)
	});
	~looperLfoAmt = lfoAmtKnobs;

	lfoFreqKnobs = Array.fill(6, { |i|
		EZKnob.new(win,
			Rect((i * 110) + 60, 280, 40, 50),
			nil,
			[1, 40, 'exp', 0, 1],
			{ |knob|
				var val = knob.value;
				tracks[i].set(\lfoFreq, val)
			}
		)
	});
	~looperLfoFreq = lfoFreqKnobs;

	// draw a grid on the window
	win.drawFunc_{
		Pen.smoothing_(false);
		6.do{|i|
			Pen.moveTo(i*110@0);
			Pen.lineTo(i*110@500);
		};
		9.do{|i|
			Pen.moveTo(0@i*30);
			Pen.lineTo(640@i*30);
		};
		Pen.stroke;
	};

	// cleanup after on window-close
	win.onClose_{
		tracks.do{ |synth| synth.free };
		busses.do{ |bus| bus.free };
		clipCells.do{ |rows|
			rows.do{|cell|
				if(cell.synthSlot.notNil) {
					cell.stopSynth();
				}
			}
		}
	};

	////////////////////////////////////////////////////////////
	// ------------------- CONTROL -------------------------- //
	////////////////////////////////////////////////////////////

	bpm = 120;
	//clock = TempoClock.default.tempo = bpm/120;
	clock = ~clock;

	////////////////////////////////////////////////////////////
	// ----------------- INTERACTION ------------------------ //
	////////////////////////////////////////////////////////////

	updateCellAction = {
		clipCells.do{ |row|
			row.do{ |cell|
				cell.isClicked_(false);
				cell.cellMouseAction_{
					if(cell.isClicked.not){
						updateCellAction.value;
						cell.isClicked_(true);
					};
				};
			}
		};
	};

	updateCellAction.value;

	updateMouseAction = {
		clipCells.do{|row|
			row.do { |cell|

				if(recordButtons[cell.row].state){
					mouseActionRecording.value(cell);
				} {
					if(cell.isFilled){
						mouseActionPlay.value(cell);
					}{
						mouseActionStop.value(cell);
					}
				}
			}
		}
	};

	// TODO: deal with empty cell case! -> still relevant?
	mouseActionRecording = { |cell|
		cell.buttonMouseAction_{
			if(cell.state == "recording"){
				cell.changeState("prepareToPlay");
				clock.play({
					{
						cell.changeState("stopRecording");
						clipCells[cell.row].do{ |cell|
							if(cell.isFilled){
								switch (cell.state,
									"prepareToPlay",		{ cell.changeState("stopped")			},
									"stopRecording",		{ cell.changeState("playing")			},
									"playing",				{ cell.changeState("stopped")			},
									"prepareToRecord",	{ cell.changeState("stopped")			},
									"recording",			{ cell.changeState("stopped")			},
								);
							}
						};
					}.defer
				}, 1);
			}{
				cell.changeState("prepareToRecord");
				clock.play({
					{
						clipCells[cell.row].do{ |cell|
							if(cell.isFilled){
								switch (cell.state,
									"prepareToPlay",		{ cell.changeState("stopped")			},
									"playing",				{ cell.changeState("stopped")			},
									"prepareToRecord",	{ cell.changeState("recording")		},
									"recording",			{ cell.changeState("stopped")			},
								);
							}
						};
					}.defer
				}, 1)
			};
		}
	};

	mouseActionPlay = { |cell|
		cell.buttonMouseAction_{
			cell.changeState("prepareToPlay");

			clock.play({
				{
					clipCells[cell.row].do{ |cell|
						if(cell.isFilled){
							switch (cell.state,
								"prepareToPlay",		{ cell.changeState("playing")			},
								"playing",				{ cell.changeState("stopped")			},
								"recording",			{ cell.changeState("stopRecording")	},
							);
						}
					};
				}.defer
			}, 1)
		}
	};

	mouseActionStop = { |cell|
		cell.buttonMouseAction_{
			cell.changeState("stopping");

			clock.play({
				{
					clipCells[cell.row].do{ |cell|
						cell.changeState("stopped");
					};
				}.defer
			}, 1)
		}
	};

	updateMouseAction.value();

	stopButtons.do { |stopButton|
		stopButton.mouseDownAction_{
			clipCells[stopButton.row].do { |cell|
				if(cell.isFilled){
					cell.changeState("stopping");
					clock.sched(1, {
						{ cell.changeState("stopped") }.defer;
					})
				}
			}
		}
	};

	recordButtons.do { |recordButton|
		recordButton.mouseDownAction_{
			if(recordButton.state){ recordButton.changeState(false) }{ recordButton.changeState(true) };
			updateMouseAction.value;
		}
	};

	~clipCells = clipCells;

	win.refresh;
	win.front;
}