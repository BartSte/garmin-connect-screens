import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Activity;
import Toybox.System;
import Toybox.Application;
import Toybox.Lang;

// Minimal7 — full-screen data field for the Garmin Edge Explore 2.
//
// Layout (4 equal rows):
//   Row 1: time of day (24 h)  |  activity timer
//   Row 2: 3-second avg power (W)  — full width, zone-colored background
//   Row 3: speed (km/h)  |  cadence (rpm)
//   Row 4: ascent (m)    |  distance (km)
//
// All cells are separated by divider lines forming a visible grid.
// No labels are shown — numbers only.

// ── Coggan 7-zone model: lower boundary of each zone as % of FTP ──────────
const ZONE2_PCT = 55;
const ZONE3_PCT = 75;
const ZONE4_PCT = 90;
const ZONE5_PCT = 105;
const ZONE6_PCT = 120;
const ZONE7_PCT = 150;

// ── Background color per zone ─────────────────────────────────────────────
const ZONE1_COLOR = 0xAAAAAA; // Z1 active recovery  — light gray
const ZONE2_COLOR = 0x0000AA; // Z2 endurance        — blue
const ZONE3_COLOR = 0x00AA00; // Z3 tempo            — green
const ZONE4_COLOR = 0xFFFF00; // Z4 threshold        — yellow
const ZONE5_COLOR = 0xFF8800; // Z5 VO2 max          — orange
const ZONE6_COLOR = 0xAA0000; // Z6 anaerobic        — red
const ZONE7_COLOR = 0x800080; // Z7 neuromuscular    — purple

class Minimal7 extends WatchUi.DataField {

    // ── state — written by compute(), read by onUpdate() ─────────────────
    hidden var mHour       as Number = 0;
    hidden var mMinute     as Number = 0;
    hidden var mTimerMs    as Number = 0;  // activity timer in ms
    hidden var m3sPower    as Number = 0;  // rolling 3-sample average, watts
    hidden var mSpeed      as Float  = 0.0f; // km/h
    hidden var mCadence    as Number = 0;  // rpm
    hidden var mAscent     as Number = 0;  // meters (cumulative)
    hidden var mDistanceKm as Float  = 0.0f; // km

    // ── 3-second power ring buffer ────────────────────────────────────────
    // Activity.Info only exposes currentPower (instantaneous), so we maintain
    // a 3-slot ring buffer updated every compute() call (~1 Hz) and average it.
    hidden var mPowerBuf as Array = [0, 0, 0] as Array<Number>;
    hidden var mPowerIdx as Number = 0;

    // ── FTP (loaded once at startup from user settings) ───────────────────
    hidden var mFtp as Number = 230;

    function initialize() {
        DataField.initialize();
        mFtp = Application.Properties.getValue("ftp") as Number;
        if (mFtp <= 0) {
            mFtp = 230; // guard against a misconfigured 0 value
        }
    }

    // onLayout is intentionally empty.
    // Row geometry is derived from dc.getWidth()/getHeight() in onUpdate(),
    // so the field adapts automatically to whatever size the OS allocates.
    function onLayout(dc as Graphics.Dc) as Void {
    }

    // Called ~1 Hz during an activity. Reads sensors into member variables.
    function compute(info as Activity.Info) as Void {
        var clock = System.getClockTime();
        mHour   = clock.hour;
        mMinute = clock.min;

        mTimerMs = (info has :timerTime && info.timerTime != null)
            ? (info.timerTime as Number)
            : 0;

        // Advance the ring buffer with the latest power sample.
        var rawPower = (info has :currentPower && info.currentPower != null)
            ? (info.currentPower as Number)
            : 0;
        mPowerBuf[mPowerIdx] = rawPower;
        mPowerIdx = (mPowerIdx + 1) % 3;
        m3sPower = (mPowerBuf[0] + mPowerBuf[1] + mPowerBuf[2]) / 3;

        mSpeed = (info has :currentSpeed && info.currentSpeed != null)
            ? ((info.currentSpeed as Float) * 3.6f) // m/s → km/h
            : 0.0f;

        mCadence = (info has :currentCadence && info.currentCadence != null)
            ? (info.currentCadence as Number)
            : 0;

        mAscent = (info has :totalAscent && info.totalAscent != null)
            ? (info.totalAscent as Number)
            : 0;

        mDistanceKm = (info has :elapsedDistance && info.elapsedDistance != null)
            ? ((info.elapsedDistance as Float) / 1000.0f) // m → km
            : 0.0f;
    }

    // Called when the field needs repainting.
    function onUpdate(dc as Graphics.Dc) as Void {
        var w    = dc.getWidth();
        var h    = dc.getHeight();
        var rowH = h / 4; // integer division — 4 equal rows

        // Clear the whole field to the device background color.
        var bgColor = getBackgroundColor();
        dc.setColor(bgColor, bgColor);
        dc.clear();

        drawRow1(dc, w, rowH, 0);          // time of day | timer
        drawRow2(dc, w, rowH, rowH);       // 3s power (zone background)
        drawRow3(dc, w, rowH, rowH * 2);   // speed | cadence
        drawRow4(dc, w, rowH, rowH * 3);   // ascent | distance

        // Dividers are drawn last so they appear on top of all cell content.
        drawDividers(dc, w, h, rowH);
    }

    // ── Row 1: time of day (left)  |  activity timer (right) ─────────────
    hidden function drawRow1(dc as Graphics.Dc, w as Number, rowH as Number, y as Number) as Void {
        var fg    = defaultFgColor();
        var half  = w / 2;
        var timeStr  = mHour.format("%02d") + ":" + mMinute.format("%02d");
        drawCell(dc, 0,    y, half, rowH, fg, timeStr);
        drawCell(dc, half, y, half, rowH, fg, formatTimer(mTimerMs));
    }

    // ── Row 2: 3-second average power, full width, zone-colored ──────────
    hidden function drawRow2(dc as Graphics.Dc, w as Number, rowH as Number, y as Number) as Void {
        var pct    = (mFtp > 0) ? (m3sPower * 100 / mFtp) : 0;
        var zoneBg = powerZoneColor(pct);
        var zoneFg = powerZoneTextColor(zoneBg);

        dc.setColor(zoneBg, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, y, w, rowH);

        dc.setColor(zoneFg, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            w / 2, y + rowH / 2,
            Graphics.FONT_NUMBER_HOT,
            m3sPower.format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // ── Row 3: speed (left)  |  cadence (right) ──────────────────────────
    hidden function drawRow3(dc as Graphics.Dc, w as Number, rowH as Number, y as Number) as Void {
        var fg   = defaultFgColor();
        var half = w / 2;
        drawCell(dc, 0,    y, half, rowH, fg, mSpeed.format("%.1f"));
        drawCell(dc, half, y, half, rowH, fg, mCadence.format("%d"));
    }

    // ── Row 4: ascent (left)  |  distance (right) ────────────────────────
    hidden function drawRow4(dc as Graphics.Dc, w as Number, rowH as Number, y as Number) as Void {
        var fg   = defaultFgColor();
        var half = w / 2;
        drawCell(dc, 0,    y, half, rowH, fg, mAscent.format("%d"));
        drawCell(dc, half, y, half, rowH, fg, mDistanceKm.format("%.2f"));
    }

    // ── Grid dividers ─────────────────────────────────────────────────────
    // Three horizontal lines at every row boundary.
    // Vertical lines split rows 1, 3, and 4; row 2 (power) is full-width.
    hidden function drawDividers(dc as Graphics.Dc, w as Number, h as Number, rowH as Number) as Void {
        dc.setColor(defaultFgColor(), Graphics.COLOR_TRANSPARENT);

        // Horizontal lines
        dc.drawLine(0, rowH,     w, rowH);      // between rows 1 and 2
        dc.drawLine(0, rowH * 2, w, rowH * 2);  // between rows 2 and 3
        dc.drawLine(0, rowH * 3, w, rowH * 3);  // between rows 3 and 4

        // Vertical lines (not on the full-width power row)
        var mid = w / 2;
        dc.drawLine(mid, 0,        mid, rowH);      // row 1 split
        dc.drawLine(mid, rowH * 2, mid, rowH * 3);  // row 3 split
        dc.drawLine(mid, rowH * 3, mid, h);          // row 4 split
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    // Centers text inside a rectangular cell.
    hidden function drawCell(
        dc      as Graphics.Dc,
        x       as Number,
        y       as Number,
        w       as Number,
        h       as Number,
        fgColor as Number,
        text    as String
    ) as Void {
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            x + w / 2,
            y + h / 2,
            Graphics.FONT_NUMBER_MEDIUM,
            text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // White text on black device background, black text on light background.
    hidden function defaultFgColor() as Number {
        return (getBackgroundColor() == Graphics.COLOR_BLACK)
            ? Graphics.COLOR_WHITE
            : Graphics.COLOR_BLACK;
    }

    // Returns the Coggan zone background color for a given % of FTP.
    hidden function powerZoneColor(pct as Number) as Number {
        if (pct >= ZONE7_PCT) { return ZONE7_COLOR; }
        if (pct >= ZONE6_PCT) { return ZONE6_COLOR; }
        if (pct >= ZONE5_PCT) { return ZONE5_COLOR; }
        if (pct >= ZONE4_PCT) { return ZONE4_COLOR; }
        if (pct >= ZONE3_PCT) { return ZONE3_COLOR; }
        if (pct >= ZONE2_PCT) { return ZONE2_COLOR; }
        return ZONE1_COLOR;
    }

    // Returns white or black text color for sufficient contrast on a zone background.
    // Dark zones (blue, red, purple) get white; light zones get black.
    hidden function powerZoneTextColor(zoneBg as Number) as Number {
        if (zoneBg == ZONE2_COLOR ||
            zoneBg == ZONE6_COLOR ||
            zoneBg == ZONE7_COLOR) {
            return Graphics.COLOR_WHITE;
        }
        return Graphics.COLOR_BLACK;
    }

    // Formats an activity timer (milliseconds) as "M:SS" or "H:MM:SS".
    hidden function formatTimer(ms as Number) as String {
        var totalSecs = ms / 1000;
        var hours     = totalSecs / 3600;
        var minutes   = (totalSecs % 3600) / 60;
        var secs      = totalSecs % 60;
        if (hours > 0) {
            return hours.format("%d") + ":"
                + minutes.format("%02d") + ":"
                + secs.format("%02d");
        }
        return minutes.format("%d") + ":" + secs.format("%02d");
    }
}
