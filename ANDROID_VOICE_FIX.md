# Voice Navigation - Android Troubleshooting Guide

## Issues Fixed:

### ✅ **Added Debug Logging**
The voice service now has extensive logging to help identify issues:
- `🔊` prefix for TTS-related logs
- `🗺️` prefix for route/navigation logs
- `🧪` prefix for test logs

### ✅ **Added Test Voice Button**
A microphone (🎤) button has been added to the app bar to test TTS directly.

### ✅ **Improved TTS Initialization**
- Language is now set FIRST (critical for Android)
- Added error handlers
- Added completion handlers
- Logs available languages

## How to Troubleshoot:

### Step 1: Check Logs
Run the app with:
```bash
flutter run
```

Watch for these logs in the console:
```
🔊 Initializing TTS...
🔊 Language set result: 1
🔊 Available languages: [...]
🔊 TTS initialization complete
```

If you see errors here, note what they say.

### Step 2: Test TTS Directly
1. Open the app
2. Go to "2D Campus Map"
3. Tap the **microphone icon (🎤)** in the app bar (top-right)
4. You should hear: "Voice navigation test. This is a test message."

**If you DON'T hear this:**
- ✋ Your phone's TTS engine may need to be configured
- ✋ Your phone's volume may be too low
- ✋ Your phone may need TTS data downloaded

### Step 3: Check Android TTS Settings

#### On your Android phone:
1. Go to **Settings** → **System** → **Language & input** → **Text-to-speech output**
2. Make sure you have a TTS engine installed:
   - **Google Text-to-Speech** (recommended)
   - **Samsung TTS** (Samsung devices)
3. Tap **"Listen to an example"** to verify TTS works
4. Check that **English (US)** language data is downloaded

### Step 4: Check Volume
1. Make sure **Media volume** is up (not just ringer volume)
2. Check if phone is in Silent/Do Not Disturb mode
3. Try unplugging headphones if connected

### Step 5: Install/Update Google TTS
If TTS isn't working at all on your phone:

1. Open **Google Play Store**
2. Search for **"Google Text-to-Speech"**
3. Install or Update it
4. Open the app and download **English (US)** voice data

### Step 6: Test Navigation with Logs
When you navigate:

1. Select start location
2. Select destination
3. Tap "Show Route"
4. Watch the console for:

```
🗺️ _computeRoute called - Start: MAIN_BUILDING, Dest: NGO_BUILDING
🗺️ Looking for route: MAIN_BUILDING->NGO_BUILDING
🗺️ Route found: true, Points: 15
🗺️ Voice enabled: true
🗺️ Calling voice navigation for: NGO Building
🔊 announceNavigationStart called for: NGO Building
🔊 speak() called - Enabled: true, Text: "Starting navigation to..."
🔊 Calling TTS speak...
🔊 TTS speak result: 1
🔊 Speech completed
```

**If you see these logs but no sound:**
- Check your phone's audio settings
- Make sure Bluetooth isn't routing audio elsewhere
- Restart the app

**If you DON'T see these logs:**
- The route isn't being found
- Voice is disabled
- Check the integration

## Common Android Issues & Fixes:

### Issue 1: "TTS not initialized"
**Solution:** The TTS engine needs time to initialize. The service now waits properly.

### Issue 2: Language not available
**Log shows:** `Language set result: 0` or `Language set result: -1`

**Solution:**
1. Go to Phone Settings → Text-to-speech
2. Install **English (US)** language data
3. Restart the app

### Issue 3: Silent mode
**Solution:** Check that phone isn't in silent/vibrate mode. TTS respects the media volume channel.

### Issue 4: Bluetooth audio
**Solution:** If you have Bluetooth headphones/speakers paired, audio might be routing there. Disconnect and try again.

### Issue 5: TTS Engine not installed
**Log shows:** Multiple TTS errors

**Solution:** Install Google Text-to-Speech from Play Store.

## Quick Fix Commands:

### Force stop and restart app:
```bash
flutter run --hot
```

### Clear app data (if TTS is corrupted):
```bash
adb shell pm clear com.example.emap_mobile
flutter run
```

### Check TTS on device:
```bash
adb shell settings get secure tts_default_synth
adb shell settings get secure tts_enabled_plugins
```

## Test Checklist:

- [ ] Can you tap the 🎤 button and hear "Voice navigation test"?
- [ ] Do you see "🔊 TTS initialization complete" in logs?
- [ ] When you navigate, do you see "🔊 speak() called" in logs?
- [ ] Is Media volume turned up on your phone?
- [ ] Is Google Text-to-Speech installed and updated?
- [ ] Have you tried restarting the app?
- [ ] Is the voice button (🔊) blue (enabled) not gray?

## Expected Behavior:

### ✅ Working Correctly:
```
Console Output:
🔊 Initializing TTS...
🔊 Language set result: 1
🔊 TTS initialization complete
[User navigates]
🗺️ _computeRoute called
🗺️ Voice enabled: true
🔊 announceNavigationStart called for: NGO Building
🔊 speak() called - Enabled: true, Text: "Starting navigation..."
🔊 Calling TTS speak...
🔊 TTS speak result: 1
[You hear voice]
🔊 Speech completed
```

### ❌ Not Working:
```
Console Output:
🔊 Initializing TTS...
🔊 Language set result: 0  ← Problem!
🔊 Error initializing TTS: ...
```

## Still Not Working?

### Alternative: Use System TTS Test
1. Open phone Settings
2. Go to Accessibility → Text-to-speech
3. Tap "Listen to an example"
4. **If this doesn't work**, your phone's TTS is broken - fix it first
5. **If this works**, check your app's audio permissions

### Check App Permissions:
While the app shouldn't need special permissions for TTS, check:
```bash
adb shell dumpsys package com.example.emap_mobile | Select-String "permission"
```

### Last Resort: Try a different TTS engine
1. Install "eSpeak TTS" from Play Store
2. Set it as default TTS engine
3. Restart app

## Next Steps:

1. **Run the app** with `flutter run`
2. **Tap the microphone 🎤 button** on the 2D map screen
3. **Check logs** for the 🔊 emoji
4. **Report back** what you see/hear

The debug logging will help us identify exactly where the issue is!
