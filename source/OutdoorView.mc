import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Activity;
import Toybox.Position;
import Toybox.Time;
import Toybox.SensorHistory;
import Toybox.Sensor;

class OutdoorView extends WatchUi.WatchFace {

    var dayProgressView;

    // CONFIGURATION ==========================================================
    const dayArcWidth = 30;

    const colorMarkBig = 0xffffff;
    const colorMarkNormal = 0xcccccc;

    const lengthMarkBig = 17;
    const lengthMarkNormal = 10;
    const widthMarkBig = 3;
    const widthMarkNormal = 2;
    const markOffset = dayArcWidth;

    const drawCurrentDate = true;
    const currentDateColor = 0xffde31;

    // INTERNAL STATE =========================================================
    var isHidden = false;
    var isInSleepMode = false;
    var isLowPower = false;

    function initialize() {
        WatchFace.initialize();

        dayProgressView = new DayProgressView();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {}

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        isHidden = false;
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
        isHidden = true;
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        if (isHidden) {
            return;
        }

        if(dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        drawHourMarks(dc);

        dayProgressView.draw(dc);

        drawTime(dc);

        drawBottomView(dc);
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

    private function drawTime(dc as Dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cX = w / 2;
        var cY = h / 2;
        var radius = w / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        var clockTime = System.getClockTime();

        var is24Hour = System.getDeviceSettings().is24Hour;
        var timeText = "";
        if (is24Hour) {
            timeText = clockTime.hour.format("%02d") + ":" + clockTime.min.format("%02d");
        } else {
            var hour = clockTime.hour % 12;
            hour = hour == 0 ? 12 : hour;
            timeText = hour + ":" + clockTime.min.format("%02d");
        }

        dc.drawText(cX, cY, Graphics.FONT_NUMBER_MEDIUM, timeText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawBottomView(dc as Dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cX = w / 2;
        var cY = h / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var elevation = SensorHistory.getElevationHistory({ :period => 1 }).next().data.toNumber();
        dc.drawText(cX, cY + 80, Graphics.FONT_SMALL, elevation, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawHourMarks(dc as Dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cX = w / 2;
        var cY = h / 2;
        var radius = w / 2;
        var outerRad = radius - markOffset;
        // 0 angle is at 3 o'clock, we are starting at 6
        var start = Math.PI / 2;
        
        for (var hour = 1; hour <= 24; hour += 1) {
            var lineLen = hour % 6 == 0 ? lengthMarkBig : lengthMarkNormal;
            var lineWidth = hour % 6 == 0 ? widthMarkBig : widthMarkNormal;
            var color = hour % 6 == 0 ? colorMarkBig : colorMarkNormal;
            
            dc.setPenWidth(lineWidth);
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);

            var innerRad = outerRad - lineLen;
            var angle = start + hour * Math.PI / 12;
    
            var sY = radius + innerRad * Math.sin(angle);
            var eY = radius + outerRad * Math.sin(angle);
            var sX = radius + innerRad * Math.cos(angle);
            var eX = radius + outerRad * Math.cos(angle);
            dc.drawLine(sX, sY, eX, eY);

            if (hour % 6 == 0) {
                var tX = radius + (innerRad - 20) * Math.cos(angle);
                var tY = radius + (innerRad - 20) * Math.sin(angle);
                if (hour == 24 && drawCurrentDate) {
                    dc.setColor(currentDateColor, Graphics.COLOR_TRANSPARENT);
                    var date = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT).day;
                    dc.drawText(tX, tY, Graphics.FONT_XTINY, date.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                } else {
                    dc.drawText(tX, tY, Graphics.FONT_XTINY, hour.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                }
            }
        }
    }
}
