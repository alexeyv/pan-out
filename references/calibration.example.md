# Sensor Calibration Reference

Load this reference when polling sensors or interpreting temperature readings.

Copy this file to `calibration.md` and fill in your data:
```
cp references/calibration.example.md references/calibration.md
```

## How to Calibrate

1. Bring a pot of water to a rolling boil
2. Note your altitude — boiling point drops ~1C per 300m above sea level
   - Sea level: 100C
   - 500m: ~98.5C
   - 1000m: ~97C
   - 1500m: ~95C
3. Measure with each instrument and record the difference

## Your Equipment Calibration

### Thermocouple (TC)
- **Reads**: [high/low/accurate] at cooking temps
- **Offset**: [e.g., +3.5C above 50C]
- **Example**: TC displays ___C when actual is ___C
- **Display target for 90C actual**: show "___C"

### IR Thermometer
- **Reads**: [high/low/accurate] at cooking temps
- **Offset**: [e.g., +3C above 50C]
- **Example**: IR displays ___C when actual is ___C
- **Display target for 220C actual**: show "___C"

### Below 50C
Note any offset differences at lower temperatures. Many instruments are accurate below 50C.

## Important: Nature of Calibration Error

Thermometer error is a **linear scale** (slope != 1), not a constant offset. The values above are approximations that work well near the calibration point but diverge further away. They also **drift over time** -- recalibrate periodically.

**Protocols always store actual/true temperatures.** The cook skill reads this file at runtime and presents both values: "We want 90C (about 86-87C on your thermocouple)."

## How to Apply

When presenting sensor targets in conversation:
1. Read the actual target temperature from the protocol
2. Apply the approximate offset to estimate the display value
3. Always present both: "We want XC actual (about YC on your [instrument])"
4. Never ask the cook to do math

## Quick Reference Table

Fill this in after calibration:

| Actual Target | TC Display | IR Display |
|--------------|------------|------------|
| 60C          |            |            |
| 70C          |            |            |
| 80C          |            |            |
| 90C          |            |            |
| 200C         |            |            |
| 220C         |            |            |

## Notes
- Calibration is specific to your equipment. Recalibrate periodically.
- At high surface temps (>200C), IR emissivity varies with cookware. Cast iron is reliable; stainless less so.
