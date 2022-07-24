# MIDI Master

A tool for mastering MIDI files.
It currently only supports the Playdate Simulator.

Masters are saved in the Data folder.
This folder is created when you first save a master. On Mac, the location of that folder is `~/Developer/PlaydateSDK/Disk/Data/com.ninovanhooff.midimaster`

## Controls

Currently, Playdate controls are not implemented, and the keyboard can be used in the Simulator to control MIDI master.

### Editing

See the bottom part of [ViewModel.lua](https://github.com/ninovanhooff/MIDI-Master/blob/main/Source/ViewModel.lua)

### Save/load

up/down - previous/next track in song

Crank - scrobble song (rewind / fast forward)

Z - Save master (overwriting any saved master for the current song) and open next song.
