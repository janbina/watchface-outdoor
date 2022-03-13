import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Activity;
import Toybox.Position;
import Toybox.Time;
import Toybox.SensorHistory;
import Toybox.Sensor;

/**
 * View that displays day phases around the watchface
 */
class DayProgressView {

    private const sunCalc = new SunCalc();

    // CONFIGURATION ==========================================================
    private const dayArcWidth = 30;

    private const colorNight = Graphics.COLOR_TRANSPARENT;
    private const colorAstro = 0x200000;
    private const colorNautic = 0x523000;
    private const colorCivil = 0xac8910;
    private const colorDay = 0xffde31;

    private const mColorNight = Graphics.COLOR_WHITE;
    private const mColorAstro = Graphics.COLOR_WHITE;
    private const mColorNautic = Graphics.COLOR_WHITE;
    private const mColorCivil = Graphics.COLOR_WHITE;
    private const mColorDay = Graphics.COLOR_BLACK;

    private const phases = [ASTRO_DAWN, NAUTIC_DAWN, DAWN, SUNRISE, SUNSET, DUSK, NAUTIC_DUSK, ASTRO_DUSK];
    private const colors = [colorNight, colorAstro, colorNautic, colorCivil, colorDay, colorCivil, colorNautic, colorAstro, colorNight];
    private const markerColors = [mColorNight, mColorAstro, mColorNautic, mColorCivil, mColorDay, mColorCivil, mColorNautic, mColorAstro, mColorNight];
    
    // INTERNAL STATE =========================================================
    // array of Time.Gregorian with times for phases, might be nulls inside
    private var times = null;
    private var lastUpdateMoment = new Time.Moment(0);
    private var lastLocation = new Position.Location({ :latitude => 50.0595854, :longitude => 14.3255427, :format => :degrees });
    // var lastLocation = new Position.Location({ :latitude => 69.4678871, :longitude => 25.5009158, :format => :degrees });
    // var lastLocation = new Position.Location({ :latitude => -55.358697, :longitude => -64.5372558, :format => :degrees });

    function draw(dc as Dc) {
        updateSunTimesIfNeeded();

        if (times == null) { return; }

        var w = dc.getWidth();
        var h = dc.getHeight();
        var cX = w / 2;
        var cY = h / 2;
        var radius = w / 2;

        var currentTimeSeconds = Utils.timeToSeconds(System.getClockTime());
        var markerColor = markerColors[0];

        dc.setPenWidth(dayArcWidth);

        if (!hasAnyPhase()) { // only daylight, yay
            dc.setColor(colorDay, Graphics.COLOR_TRANSPARENT);
            markerColor = mColorDay;
            dc.drawCircle(cX, cY, radius - dayArcWidth / 2);
        } else { // at least one phase, now do the magic
            var startSec = null;
            var endSec = null;
            var absoluteStart = null;
            var lastDrawnIndex = 0;
            for (var i = 0; i < times.size(); i++) {
                if (times[i] == null) { continue; } // skip stupid nulls

                if (startSec == null) {
                    absoluteStart = Utils.timeToSeconds(times[i]);
                    startSec = absoluteStart;
                    continue;
                }

                endSec = Utils.timeToSeconds(times[i]);

                // here we draw, finally
                if (currentTimeSeconds > startSec && currentTimeSeconds <= endSec) {
                    markerColor = markerColors[i];
                }
                var start = getAngle(startSec);
                var end = getAngle(endSec);
                dc.setColor(colors[i], Graphics.COLOR_TRANSPARENT);
                dc.drawArc(cX, cY, radius - dayArcWidth / 2, Graphics.ARC_CLOCKWISE, start, end);
                startSec = endSec;
                lastDrawnIndex = i;
            }
            if (currentTimeSeconds > startSec || currentTimeSeconds <= absoluteStart) {
                markerColor = markerColors[lastDrawnIndex + 1];
            }
            var start = getAngle(startSec);
            var end = getAngle(absoluteStart);
            dc.setColor(colors[lastDrawnIndex + 1], Graphics.COLOR_TRANSPARENT);
            dc.drawArc(cX, cY, radius - dayArcWidth / 2, Graphics.ARC_CLOCKWISE, start, end);
        }
        
        var angle = Utils.secondsToRad(currentTimeSeconds) + Utils.RadAt12oclock;
        var start = Utils.pointOnCircle(radius, 0, angle);
        var end = Utils.pointOnCircle(radius, 30-2, angle);

        dc.setColor(markerColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(4);
        dc.drawLine(start[0], start[1], end[0], end[1]);
    }

    // we only update times if its needed, we don't need to do that every second
    // as of now, it is when location changes or once every 10 minutes
    private function updateSunTimesIfNeeded() {
        var location = Activity.getActivityInfo().currentLocation;
        var currentLocation = location != null ? location : lastLocation;
        var currentTime = Time.now();

        // if we dont have location, we cannot update
        if (currentLocation == null) { return; }

        var locationChanged = !Utils.locationsAreSame(lastLocation, currentLocation);
        var timeChanged = Utils.abs(currentTime.value() - lastUpdateMoment.value()) > 60 * 10;
        
        if (locationChanged || timeChanged) {
            System.println("DEBUG: updating sun times: locationChanged=" + locationChanged + ", timeChanged=" + timeChanged);
            lastLocation = currentLocation;
            lastUpdateMoment = currentTime;

            times = new[phases.size()];
            for (var i = 0; i < phases.size(); i++) {
                var time = sunCalc.calculate(currentTime, currentLocation.toRadians(), phases[i]);

                var timeInfo = time != null ? Time.Gregorian.info(time, Time.FORMAT_SHORT) : null;

                times[i] = timeInfo;
                System.println("DEBUG: time for " + phases[i] + " = " + (time == null ? "NONE" : SunCalc.printMoment(time)));
            }
        }
    }

    // return angle for drawArc
    // day starts at 6 oclock position, which is 270 degrees angle in garmin api
    private function getAngle(sec) {
        var rad = Utils.secondsToRad(sec);
        var deg = Math.toDegrees(Utils.RadAt6oclock - rad);
        return deg;
    }

    private function hasAnyPhase() {
        if (times == null) { return false; }
        for (var i = 0; i < times.size(); i++) {
            if (times[i] != null) { return true; }
        }
        return false;
    }
}
