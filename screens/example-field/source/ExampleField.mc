import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Activity;
import Toybox.Lang;

// ExampleField is a simple data field that displays the current speed.
// Copy this as a starting point for new data screens.
class ExampleField extends WatchUi.DataField {

    hidden var mValue as Float = 0.0f;
    hidden var mLabel as String = "SPD";

    function initialize() {
        DataField.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
        // Called once when the field is first shown.
        // Use dc.getWidth() / dc.getHeight() to adapt to the field size.
    }

    // Called once per second during an activity to compute the value.
    function compute(info as Activity.Info) as Void {
        if (info has :currentSpeed && info.currentSpeed != null) {
            // currentSpeed is in m/s; convert to km/h
            mValue = (info.currentSpeed as Float) * 3.6f;
        } else {
            mValue = 0.0f;
        }
    }

    // Called when the field needs to be redrawn.
    function onUpdate(dc as Graphics.Dc) as Void {
        var bgColor = getBackgroundColor();
        var fgColor = (bgColor == Graphics.COLOR_BLACK)
            ? Graphics.COLOR_WHITE
            : Graphics.COLOR_BLACK;

        dc.setColor(fgColor, bgColor);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        // Label at the top
        dc.drawText(
            cx, cy - 20,
            Graphics.FONT_TINY,
            mLabel,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Value in the centre
        dc.drawText(
            cx, cy + 10,
            Graphics.FONT_NUMBER_MEDIUM,
            mValue.format("%.1f"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
}
