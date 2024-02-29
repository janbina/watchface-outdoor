import Toybox.Math;
import Toybox.Time;
import Toybox.Lang;
import Toybox.Position;
import Toybox.System;

class Utils {

    // Radian value at important points around the clock
    static const RadAt3oclock = 0;
    static const RadAt6oclock = Math.PI / 2 * 3;
    static const RadAt9oclock = Math.PI;
    static const RadAt12oclock = Math.PI / 2;

    // returns [x,y] coordinates of a point that is inside of a circle with center in [radius, radius],
    // which is moved [distanceFromBorder] towards the center of the circle and [angle] from 3 o'clock position
    static function pointOnCircle(radius, distanceFromBorder, angle) {
        var x = radius + (radius - 1 - distanceFromBorder) * Math.cos(angle);
        var y = radius + (radius - 1 - distanceFromBorder) * Math.sin(angle);
        return [x, y];
    }

    static function secondsToRad(seconds) {
        return seconds.toFloat() / Time.Gregorian.SECONDS_PER_DAY * 2 * Math.PI;
    }

    static function timeToSeconds(info as System.ClockTime) {
        return info.hour * Time.Gregorian.SECONDS_PER_HOUR + info.min * Time.Gregorian.SECONDS_PER_MINUTE + info.sec;
    }

    static function abs(num) {
        return num >= 0 ? num : -num; 
    }

    static function locationsAreSame(a as Position.Location, b as Position.Location) as Boolean {
        if (a == null && b == null) { return true; }
        if (a == null || b == null) { return false; }
        var rA = a.toRadians();
        var rB = b.toRadians();

        return rA[0] == rB[0] && rA[1] == rB[1];
    }
}
