---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by ninovanhooff.
--- DateTime: 22/07/2022 15:15
---

import "CoreLibs/object"

local snd <const> = playdate.sound

local justPressed <const> = playdate.buttonJustPressed
-- local justReleased <const> = playdate.buttonJustReleased
local buttonDown <const> = playdate.kButtonDown
local buttonUp <const> = playdate.kButtonUp
--local buttonLeft <const> = playdate.kButtonLeft
--local buttonRight <const> = playdate.kButtonRight
--local buttonA <const> = playdate.kButtonA
--local buttonB <const> = playdate.kButtonB

class("ViewModel").extends()

function ViewModel:init(midiPath)
    self.sequence, self.trackProps = loadMidi(midiPath)

    print("Sequence length (steps)", self.sequence:getLength())
    print("Sequence tempo", self.sequence:getTempo())
    self.numTracks = self.sequence:getTrackCount()
    self.activeNoteCache = {}
    for i = 1, self.numTracks do
        self.activeNoteCache[i] = {}
        local synth
        if i == 10 then
            synth = "drums"
        else
            synth = snd.kWaveSawtooth
        end
    end
    self.selectedIdx = 1
    self.activeNoteCache = {}
    self.sequence:play()
end

function ViewModel:getCurrentStep()
    return self.sequence:getCurrentStep()
end

function ViewModel:getProgress()
    return self:getCurrentStep() / self.sequence:getLength()
end

function ViewModel:trackName(idx)
    local synth = self.trackProps[idx].synth
    return string.format("%s : ", idx) .. synthNames[synth]
end

function ViewModel:getTrack(trackNum)
    return self.sequence:getTrackAtIndex(trackNum)
end

function ViewModel:getVisibleNotes(trackNum)
    -- todo use noteCache, or simply read all notes up front?
    local startStep = self:getCurrentStep() - 280
    return self:getTrack(trackNum):getNotes(startStep, startStep + 480)
end

function ViewModel:isMuted(trackNum)
    return self.trackProps[trackNum].isMuted
end

--- when the track is silent, because it is muted or another track is solo
function ViewModel:drawShaded(trackNum)
    if self:isMuted(trackNum) then
        return true
    end

    for i = 1, self.numTracks do
        if self:isSolo(i) and i ~= trackNum then
            return true
        end
    end

    return false
end

function ViewModel:setMuted(trackNum, muted)
    self.trackProps[trackNum].isMuted = muted
    local track = self:getTrack(trackNum)
    track:setMuted(muted)
    track:getInstrument():allNotesOff()
end

function ViewModel:toggleMuted(trackNum)
    local isMuted = self:isMuted(trackNum)
    self:setMuted(trackNum, not isMuted)
end

function ViewModel:isSolo(trackNum)
    return self.trackProps[trackNum].isSolo
end

function ViewModel:toggleSolo(trackNum)
    local newIsSolo = not self:isSolo(trackNum)
    for i, item in ipairs(self.trackProps) do
        item.isSolo = i == trackNum and newIsSolo
        local track = self:getTrack(i)
        local muteTrack = item.isMuted or (newIsSolo and i ~= trackNum)
        track:setMuted(muteTrack)
        if muteTrack then
            track:getInstrument():allNotesOff()
        end
        print("set solo for ", i, item.isSolo, "muted", item.isMuted or (newIsSolo and i ~= trackNum))
    end
end

function ViewModel:toggleInstrument(trackNum)
    local props = self.trackProps[trackNum]
    local curSynth = props.synth
    local nextIndex = lume.find(synths, curSynth) + 1
    if nextIndex > #synths then
        nextIndex = 1
    end
    props.synth = synths[nextIndex]
    local polyphony = self:getTrack(trackNum):getPolyphony()
    local newInstrument = createInstrument(polyphony, props)
    self:getTrack(trackNum):setInstrument(newInstrument)
    -- calling play again will apply the changes to the running sequence
    self.sequence:play()
end

function ViewModel:getADSR(trackNum)
    local props = self.trackProps[trackNum]
    return
        props.attack,
        props.decay,
        props.sustain,
        props.release
end

function ViewModel:changeTrackProp(trackNum, key, amount)
    local trackProps = self.trackProps[trackNum]
    local track = self:getTrack(trackNum)
    trackProps[key] = lume.clamp(
        trackProps[key] + amount,
        0, 1
    )
    track:setInstrument(createInstrument(
        track:getPolyphony(), trackProps
    ))
    self.sequence:play()
end

function ViewModel:update()
    if justPressed(buttonDown) and self.selectedIdx < self.numTracks then
        self.selectedIdx = self.selectedIdx + 1
    elseif justPressed(buttonUp) and self.selectedIdx > 1 then
        self.selectedIdx = self.selectedIdx - 1
    end
end

function ViewModel:keyReleased(key)
    local trackNum = self.selectedIdx
    if key == "m" then
        self:toggleMuted(trackNum)
    elseif key == "n" then
        self:toggleSolo(trackNum)
    elseif key == "i" then
        self:toggleInstrument(trackNum)
    elseif key == "r" then
        self:changeTrackProp(trackNum, "attack", 0.1)
    elseif key == "f" then
        self:changeTrackProp(trackNum, "attack", -0.1)
    elseif key == "t" then
        self:changeTrackProp(trackNum, "decay",0.1)
    elseif key == "g" then
        self:changeTrackProp(trackNum, "decay", -0.1)
    elseif key == "y" then
        self:changeTrackProp(trackNum, "sustain", 0.1)
    elseif key == "h" then
        self:changeTrackProp(trackNum, "sustain", -0.1)
    elseif key == "u" then
        self:changeTrackProp(trackNum, "release", 0.1)
    elseif key == "j" then
        self:changeTrackProp(trackNum, "release", -0.1)
    end
end
