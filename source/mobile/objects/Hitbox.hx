/*
 * Copyright (C) 2025 Mobile Porting Team
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package mobile.objects;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.geom.Matrix;

/**
 * A zone with 4 hints (A hitbox).
 * It's really easy to customize the layout.
 *
 * @author Homura Akemi (HomuHomu833)
 */
class Hitbox extends FlxSpriteGroup {
	/**
	 * Array of MobileButton representing the hints.
	 */
	public var hints(default, null):Array<MobileButton>;
	public var extraHint:MobileButton = new MobileButton();

	final guh2:Float = 0.00001;
	final guh:Float = utilities.Options.getData("mobileCAlpha") >= 0.9 ? utilities.Options.getData("mobileCAlpha") - 0.2 : utilities.Options.getData("mobileCAlpha");

	/**
	 * Creates the zone with the specified number of hints.
	 *
	 * @param ammo The amount of hints you want to create.
	 * @param perHintWidth The width that the hints will use.
	 * @param perHintHeight The height that the hints will use.
	 * @param colors The color per hint.
	 */
	public function new(ammo:UInt, perHintWidth:Int, perHintHeight:Int):Void {
		super();
		hints = new Array<MobileButton>();

		for (i in 0...ammo)
			add(hints[i] = createHint(i * perHintWidth, (states.PlayState.instance.songHasDodges && !utilities.Options.getData("hitboxPos") ? 200 : 0), perHintWidth, (states.PlayState.instance.songHasDodges ? perHintHeight - 200 : perHintHeight), getHintColor(ammo, i)));

		if (states.PlayState.instance.songHasDodges)
			add(extraHint = createHint(0, (utilities.Options.getData("hitboxPos") ? FlxG.height - 200 : 0), FlxG.width, 200, 0xFF0066FF));

		scrollFactor.set();
	}

	/**
	 * Cleans up memory.
	 */
	override public function destroy():Void {
		super.destroy();

		for (i in 0...hints.length)
			hints[i] = FlxDestroyUtil.destroy(hints[i]);

		hints.splice(0, hints.length);
	}

	/**
	 * Creates a hint with specified properties.
	 *
	 * @param X The x position of the hint.
	 * @param Y The y position of the hint.
	 * @param Width The width of the hint.
	 * @param Height The height of the hint.
	 * @param Color The color of the hint.
	 * @return The created MobileButton representing the hint.
	 */
	private function createHint(X:Float, Y:Float, Width:Int, Height:Int, Color:Int = 0xFFFFFF):MobileButton {
		var hint:MobileButton = new MobileButton(X, Y);
		hint.loadGraphic(createHintGraphic(Width, Height, Color));

		hint.label = new FlxSprite();
		hint.labelStatusDiff = (utilities.Options.getData("hitboxType") != "Hidden") ? guh : guh2;
		hint.label.loadGraphic(createHintGraphic(Width, Math.floor(Height * 0.035), Color, true));
		if (utilities.Options.getData("hitboxPos"))
			hint.label.offset.y -= (hint.height - hint.label.height);
		else
			hint.label.offset.y += (hint.height - hint.label.height);

		if (utilities.Options.getData("hitboxType") != "Hidden") {
			var hintTween:FlxTween = null;
			var hintLaneTween:FlxTween = null;

			hint.onDown.callback = function() {
				if (hintTween != null)
					hintTween.cancel();

				if (hintLaneTween != null)
					hintLaneTween.cancel();

				hintTween = FlxTween.tween(hint, {alpha: guh}, guh / 100, {
					ease: FlxEase.circInOut,
					onComplete: (twn:FlxTween) -> hintTween = null
				});

				hintLaneTween = FlxTween.tween(hint.label, {alpha: guh2}, guh / 10, {
					ease: FlxEase.circInOut,
					onComplete: (twn:FlxTween) -> hintTween = null
				});
			}

			hint.onOut.callback = hint.onUp.callback = function() {
				if (hintTween != null)
					hintTween.cancel();

				if (hintLaneTween != null)
					hintLaneTween.cancel();

				hintTween = FlxTween.tween(hint, {alpha: guh2}, guh / 10, {
					ease: FlxEase.circInOut,
					onComplete: (twn:FlxTween) -> hintTween = null
				});

				hintLaneTween = FlxTween.tween(hint.label, {alpha: guh}, guh / 100, {
					ease: FlxEase.circInOut,
					onComplete: (twn:FlxTween) -> hintTween = null
				});
			}
		}

		hint.moves = hint.solid = false;
		hint.multiTouch = hint.immovable = true;
		hint.antialiasing = utilities.Options.getData("antialiasing");
		hint.scrollFactor.set();
		hint.label.alpha = hint.alpha = guh2;
		hint.canChangeLabelAlpha = false;
		//hint.active = !utilities.Options.getData("botplay");
		#if FLX_DEBUG
		hint.ignoreDrawDebug = true;
		#end
		return hint;
	}

	/**
	 * Creates the graphic for a hint with specified properties.
	 *
	 * @param Width The width of the hint.
	 * @param Height The height of the hint.
	 * @param Color The color of the hint.
	 * @return The created BitmapData representing the hint graphic.
	 */
	private function createHintGraphic(Width:Int, Height:Int, Color:Int = 0xFFFFFF, ?isLane:Bool = false):BitmapData {
		var shape:Shape = new Shape();
		shape.graphics.beginFill(Color);

		if (utilities.Options.getData("hitboxType") == "No Gradient") {
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(Width, Height, 0, 0, 0);

			if (isLane)
				shape.graphics.beginFill(Color);
			else
				shape.graphics.beginGradientFill(RADIAL, [Color, Color], [0, 1], [60, 255], matrix, PAD, RGB, 0);
			shape.graphics.drawRect(0, 0, Width, Height);
			shape.graphics.endFill();
		} else if (utilities.Options.getData("hitboxType") == "No Gradient (Old)") {
			shape.graphics.lineStyle(10, Color, 1);
			shape.graphics.drawRect(0, 0, Width, Height);
			shape.graphics.endFill();
		} else { // if (utilities.Options.getData("hitboxType") == 'Gradient')
			shape.graphics.lineStyle(3, Color, 1);
			shape.graphics.drawRect(0, 0, Width, Height);
			shape.graphics.lineStyle(0, 0, 0);
			shape.graphics.drawRect(3, 3, Width - 6, Height - 6);
			shape.graphics.endFill();
			if (isLane)
				shape.graphics.beginFill(Color);
			else
				shape.graphics.beginGradientFill(RADIAL, [Color, FlxColor.TRANSPARENT], [1, 0], [0, 255], null, null, null, 0.5);
			shape.graphics.drawRect(3, 3, Width - 6, Height - 6);
			shape.graphics.endFill();
		}

		var bitmap:BitmapData = new BitmapData(Width, Height, true, 0);
		bitmap.draw(shape, true);
		return bitmap;
	}

	@:dox(hide)
	private function getHintColor(ammo:Int, currentAmmo:Int):FlxColor
	{
		final ORANGE:FlxColor = 0xF9A949;
		final PURPLE:FlxColor = 0x5F1FBD;
		final GREEN:FlxColor = 0x2DC671;
		final PINK:FlxColor = 0xF88989;
		final RED:FlxColor = 0xEE2959;
		final LIME:FlxColor = 0x6BC951;
		final GRAY:FlxColor = 0xC3B5C4;
		final GREEN2:FlxColor = 0x2EC671;
		final PINK2:FlxColor = 0xF68A88;
		final MAGENTA:FlxColor = 0xE82487;
		final VIOLET:FlxColor = 0x823697;
		final LIME2:FlxColor = 0x6AC94F;
		final BRIGHT_RED:FlxColor = 0xFF0100;
		final BLUE:FlxColor = 0x1E28FE;
		final HOT_PINK:FlxColor = 0xF52F56;
		final DARK_PURPLE:FlxColor = 0x571AB8;

		final colorPresets:Map<Int, Array<FlxColor>> = [
			6 => [ORANGE, PURPLE, GREEN, PINK, RED, LIME],
			7 => [ORANGE, PURPLE, GREEN, GRAY, PINK, RED, LIME],
			9 => [ORANGE, RED, PURPLE, GREEN2, GRAY, PINK2, MAGENTA, VIOLET, LIME2],
			10 => [ORANGE, RED, PURPLE, GREEN2, GRAY, GRAY, PINK2, MAGENTA, VIOLET, LIME2],
			12 => [ORANGE, RED, PURPLE, GREEN2, BRIGHT_RED, GRAY, GRAY, BLUE, PINK2, MAGENTA, VIOLET, LIME2]
		];

		final defaultColors:Array<FlxColor> = [ORANGE, HOT_PINK, DARK_PURPLE, GREEN];
		final colors:Array<FlxColor> = colorPresets.exists(ammo) ? colorPresets.get(ammo) : defaultColors;

		return colors[currentAmmo];
	}
}
