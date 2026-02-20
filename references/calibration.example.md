# Sensor Calibration Reference

Load this reference when polling sensors or interpreting temperature readings.

Calibration is optional. The skills work fine without it — they'll just use the temperatures as-is. But if your instruments read high or low, calibration lets the skills correct for that automatically.

## Your Readings

The help skill can walk you through capturing these. You just read numbers off your thermometers — the skill does the math.

### Probe Thermometer

Two-point calibration against ice water and boiling water is a standard method — it gives a reliable linear correction across the cooking range.

- **Model**: [your thermometer]
- **Ice water (0C actual)**: displayed ___C
- **Boiling water (___C actual for your altitude)**: displayed ___C

### IR Thermometer (sanity check only)

IR readings depend on the emissivity of the surface, which varies by material, finish, and temperature. You can't meaningfully calibrate an IR gun in a kitchen — but you can sanity-check it. Heat a cast-iron pan, read it with your probe, then with the IR gun. If they're in the same ballpark, you're fine. If the IR gun is way off, you know not to trust it for precision.

- **Model**: [your IR gun]
- **Sanity check**: probe read ___C, IR read ___C on [surface]

### Altitude

If you're at altitude, boiling point is lower — ~1C per 300m:
- Sea level: 100C
- 500m: ~98.5C
- 1000m: ~97C
- 1500m: ~95C

## How the Skills Use This

For the probe, the skills derive a linear correction from the two data points (thermometer error is a scale factor, not a constant offset — that's why two points matter). The IR gun isn't calibrated — it's just sanity-checked. The skills treat IR readings as approximate and won't rely on them for precision. Protocols store actual/true temperatures. At runtime, the cook skill converts to display values so you see: "We want 90C (about 87C on your probe)." The cook never has to do math.

## When to Use Which

- **Probe**: liquids, internal meat temps, anything where you need a precise number. The probe is your primary instrument.
- **IR gun**: quick surface checks — is the pan preheated? Is it heating evenly? Where are the hot spots? The IR gun is fast and spatial, but approximate. Don't use it where precision matters.
- **Don't IR boiling water** — the turbulent surface (liquid, steam, bubbles) gives readings that swing 5–15C between shots. Use the probe for boiling liquids.

## Notes

- Probe calibration drifts over time. Recalibrate every few months or when readings seem off.
- At high surface temps (>200C), IR emissivity varies with cookware. Cast iron is reliable; stainless less so.
