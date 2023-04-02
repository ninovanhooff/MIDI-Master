# MIDI Master

A tool for mastering MIDI files.

Masters are saved in the Data folder.
This folder is created when you first save a master. On Mac, the location of that folder is `~/Developer/PlaydateSDK/Disk/Data/com.ninovanhooff.midimaster`

## Differences between Simulator and hardware playback

There may be differences in playback between Simulator and hardware devices, this also includes 
cases where songs sound better on hardware. Testing on hardware is always recommended.

## Add your own songs

### Using the MIDI Master pdx

Open the pdx folder (Mac: right-click the pdx and select "Show package contents").
Add your songs to the "songs" folder inside the pdx.

### When compiling MIDI Master from source

Add your songs to the Source/songs folder. Then compile the project.
In a terminal, navigate to the folder where this READMe.md file is located and execute (mac command):

`pdc Source midi_master.pdx && open midi_master.pdx`

## Controls

### Playdate controls

- dpad left/right: select parameter to adjust (volume, instrument, attack decay, sustain, release ...)
- dpad up/down: select channel a.k.a. track a.k.a instrument
- select dpad up to select the song title and press A to save the current master and load the next song
- A: increase selected parameter value
- B: Decrease selected parameter value
- Crank: scrobble song (rewind / fast forward)

### Keyboard controls

Keyboard controls can be used in simulator or when using the simulator to control the device.

See the bottom part of [ViewModel.lua](https://github.com/ninovanhooff/MIDI-Master/blob/main/Source/ViewModel.lua)
for the mappings

## Add your own sampled instruments (for Developers)

MIDI Master comes with a few bundled sampled instruments. These are included as [Toyboxes](https://github.com/toyboxpy/toybox.py).
To add your own instrument, create a Toybox out of it.

Steps to add your own instrument to MIDI Master:

- Create your own instrument as a Toybox./ See these examples: [Choir Ah](https://github.com/ninovanhooff/master-player-choir-ah), [Drums Electric](https://github.com/ninovanhooff/master-player-drums-electric).
- Download the MIDI Master source code
- Download [Toybox](https://github.com/toyboxpy/toybox.py)
- Use Toybox to add your instrument to MIDI Master
- open [main.lua](https://github.com/ninovanhooff/MIDI-Master/blob/main/Source/main.lua) and add your instrument using the `masterplayer.addInstrument()` function
- compile MIDI Master
