package states;

import dependency.FNFUIState;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import song.Conductor;

/* 
	Music beat state happens to be the first thing on my list of things to add, it just so happens to be the backbone of
	most of the project in its entirety. It handles a couple of functions that have to do with actual music and songs and such.

	I'm not going to change any of this because I don't truly understand how songplaying works, 
	I mostly just wanted to rewrite the actual gameplay side of things.
 */
class MusicBeatState extends FNFUIState
{
	// original variables extended from original game source
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	public var lastSection:Float = 0;

	public var curStep:Int = 0;
	public var curBeat:Int = 0;
	public var curSection:Int = 0;

	// fixes a bug with FlxUITabMenu where it wouldn't respect the current camera zoom
	public var camBeat:FlxCamera;

	// class create event
	override function create()
	{
		// dump
		Paths.clearStoredMemory();
		if ((!Std.isOfType(this, states.PlayState)) && (!Std.isOfType(this, states.editors.OriginalChartingState)))
			Paths.clearUnusedMemory();

		// create controls event;
		Controls.keyEventPress.add(keyEventPress);
		Controls.keyEventRelease.add(keyEventRelease);

		camBeat = FlxG.camera;

		super.create();

		// For debugging
		FlxG.watch.add(Conductor, "songPosition");
		FlxG.watch.add(this, "curBeat");
		FlxG.watch.add(this, "curStep");
		FlxG.watch.add(this, "curSection");
	}

	override function destroy()
	{
		// destroy controls;
		Controls.keyEventPress.remove(keyEventPress);
		Controls.keyEventRelease.remove(keyEventRelease);

		super.destroy();
	}

	public function keyEventPress(action:String, key:Int, state:KeyState) {}

	public function keyEventRelease(action:String, key:Int, state:KeyState) {}

	// class 'step' event
	override function update(elapsed:Float)
	{
		updateContents();

		super.update(elapsed);
	}

	public function updateContents()
	{
		updateCurStep();

		curBeat = Math.floor(curStep / 4);
		curSection = Math.floor(curStep / 16);

		// delta time bullshit
		var trueStep:Int = curStep;
		for (i in storedSteps)
			if (i < oldStep)
				storedSteps.remove(i);
		for (i in oldStep...trueStep)
		{
			if (!storedSteps.contains(i) && i > 0)
			{
				curStep = i;
				stepHit();
				skippedSteps.push(i);
			}
		}
		if (skippedSteps.length > 0)
			skippedSteps = [];
		curStep = trueStep;

		//
		if (oldStep != curStep && curStep > 0 && !storedSteps.contains(curStep))
			stepHit();
		oldStep = curStep;
	}

	var oldStep:Int = 0;
	var storedSteps:Array<Int> = [];
	var skippedSteps:Array<Int> = [];

	public function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();

		if (!storedSteps.contains(curStep))
			storedSteps.push(curStep);
	}

	public function beatHit():Void
	{
		// trace('Section: ' + curSection + ' Last: ' + lastSection);
	}

	public function sectionHit():Void
	{
		if (curSection != lastSection)
			lastSection = Std.int(curSection);
	}

	var textField:FlxText;
	var fieldTween:FlxTween;

	public function logTrace(input:String, duration:Float, traceOnConsole:Bool = true, ?cam:FlxCamera)
	{
		if (traceOnConsole)
			trace(input);
		if (textField != null)
		{
			var oldField:FlxText = cast textField;
			FlxTween.tween(oldField, {alpha: 0}, 0.6, {
				onComplete: function(twn:FlxTween)
				{
					remove(oldField);
					oldField.destroy();
				}
			});
			textField = null;
		}

		if (fieldTween != null)
		{
			fieldTween.cancel();
			fieldTween = null;
		}

		if (input != '' && duration > 0)
		{
			textField = new FlxText(0, 0, FlxG.width, input);
			textField.setFormat(Paths.font("vcr"), 32, 0xFFFFFFFF, CENTER);
			textField.setBorderStyle(OUTLINE, 0xFF000000, 2);
			textField.alpha = 0;
			textField.screenCenter(X);
			if (cam != null)
				textField.cameras = [cam];
			add(textField);

			fieldTween = FlxTween.tween(textField, {alpha: 1}, 0.2, {
				onComplete: function(twn:FlxTween)
				{
					fieldTween = FlxTween.tween(textField, {alpha: 0}, 0.2, {
						startDelay: duration,
						onComplete: function(twn:FlxTween)
						{
							remove(textField);
							textField.destroy();
							textField = null;
							if (fieldTween == twn)
								fieldTween = null;
						}
					});
				}
			});
		}
	}
}

class MusicBeatSubstate extends FlxSubState
{
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;
	private var lastSection:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	private var curSection:Int = 0;

	override function create()
	{
		// create controls event;
		Controls.keyEventPress.add(keyEventPress);
		Controls.keyEventRelease.add(keyEventRelease);

		super.create();
	}

	override function destroy()
	{
		// destroy controls;
		Controls.keyEventPress.remove(keyEventPress);
		Controls.keyEventRelease.remove(keyEventRelease);

		super.destroy();
	}

	public function keyEventPress(action:String, key:Int, state:KeyState) {}

	public function keyEventRelease(action:String, key:Int, state:KeyState) {}

	override function update(elapsed:Float)
	{
		var oldStep:Int = curStep;

		updateCurStep();
		curBeat = Math.floor(curStep / 4);
		curSection = Math.floor(curStep / 16);

		if (oldStep != curStep && curStep > 0)
			stepHit();

		super.update(elapsed);
	}

	private function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		// trace('Section: ' + curSection + ' Last: ' + lastSection);
	}

	public function sectionHit():Void
	{
		if (curSection != lastSection)
			lastSection = Std.int(curSection);
	}
}
