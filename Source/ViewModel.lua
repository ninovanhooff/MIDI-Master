---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by ninovanhooff.
--- DateTime: 22/07/2022 15:15
---

import "CoreLibs/object"

local snd <const> = playdate.sound

local floor <const> = math.floor
local getCrankChange <const> = playdate.getCrankChange
local justPressed <const> = playdate.buttonJustPressed
-- local justReleased <const> = playdate.buttonJustReleased
local buttonDown <const> = playdate.kButtonDown
local buttonUp <const> = playdate.kButtonUp
--local buttonLeft <const> = playdate.kButtonLeft
--local buttonRight <const> = playdate.kButtonRight
--local buttonA <const> = playdate.kButtonA
--local buttonB <const> = playdate.kButtonB

class("ViewModel").extends()

function ViewModel:init(songPath)
    self.currentSongPath = songPath
    self.trackProps = playdate.datastore.read(self.currentSongPath)
    print(songPath, trackProps)
    self.sequence, self.trackProps = loadMidi(songPath, self.trackProps)

    print("Sequence length (steps)", self.sequence:getLength())
    print("Sequence tempo", self.sequence:getTempo())
    self.numTracks = self.sequence:getTrackCount()
    for i = 1, self.numTracks do
        local synth
        if i == 10 then
            synth = "drums"
        else
            synth = snd.kWaveSawtooth
        end
    end
    self.selectedIdx = 1
    self:applyMuteAndSolo()
    self.crankSpeed = self.sequence:getTempo() / 4
    self.sequence:play()
end

function ViewModel:getNumSteps()
    return self.sequence:getLength()
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

function ViewModel:getVolume(trackNum)
    return self.trackProps[trackNum].volume
end

function ViewModel:getNotes(trackNum)
    return self:getTrack(trackNum):getNotes(1, self:getNumSteps())
end

function ViewModel:isMuted(trackNum)
    return self.trackProps[trackNum].isMuted
end

--- when the track is silent, because it is muted or another track is solo
function ViewModel:isSilenced(trackNum)
    local anySolo = false
    for _,item in ipairs(self.trackProps) do
        if item.isSolo then
            anySolo = true
            break
        end
    end

    local props = self.trackProps[trackNum]
    return props.isMuted or (anySolo and not props.isSolo)
end

function ViewModel:applyMuteAndSolo()
    for i = 1, #self.trackProps do
        local track = self:getTrack(i)
        local muteTrack = self:isSilenced(i)
        track:setMuted(muteTrack)
        if muteTrack then
            track:getInstrument():allNotesOff()
        end
        print("set track silenced for ",i, muteTrack)
    end
end

function ViewModel:toggleMuted(trackNum)
    local isMuted = self:isMuted(trackNum)
    self.trackProps[trackNum].isMuted = not isMuted
    self:applyMuteAndSolo()
end

function ViewModel:isSolo(trackNum)
    return self.trackProps[trackNum].isSolo
end

function ViewModel:toggleSolo(trackNum)
    self.trackProps[trackNum].isSolo = not self:isSolo(trackNum)
    self:applyMuteAndSolo()
end

function ViewModel:toggleInstrument(trackNum)
    local props = self.trackProps[trackNum]
    local curSynth = props.synth
    props.synth = selectNext(synths, curSynth)
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
    printTable(trackProps)
    track:setInstrument(createInstrument(
        track:getPolyphony(), trackProps
    ))
    self.sequence:play()
end

function ViewModel:movePlayHead(change)
    local targetStep = self:getCurrentStep() + floor(change * self.crankSpeed)
    targetStep = targetStep % self:getNumSteps()
    self.sequence:goToStep(targetStep, true)
end

function ViewModel:update()
    if justPressed(buttonDown) and self.selectedIdx < self.numTracks then
        self.selectedIdx = self.selectedIdx + 1
    elseif justPressed(buttonUp) and self.selectedIdx > 1 then
        self.selectedIdx = self.selectedIdx - 1
    end

    local _, accChange = getCrankChange()
    if accChange ~= 0 then
        self:movePlayHead(accChange)
    end
end

function ViewModel:save()
    print("saving", self.currentSongPath)
    playdate.datastore.write(self.trackProps, self.currentSongPath, true)
end

function ViewModel:finish()
    self:save()
    self.sequence:stop()
end

function ViewModel:keyReleased(key)
    local trackNum = self.selectedIdx
    if key == "m" then
        self:toggleMuted(trackNum)
    elseif key == "n" then
        self:toggleSolo(trackNum)
    elseif key == "i" then
        self:toggleInstrument(trackNum)
    elseif key == "v" then
        self:changeTrackProp(trackNum, "volume", -0.1)
    elseif key == "b" then
        self:changeTrackProp(trackNum, "volume", 0.1)
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
