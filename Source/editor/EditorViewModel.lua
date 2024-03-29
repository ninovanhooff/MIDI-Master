---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by ninovanhooff.
--- DateTime: 22/07/2022 15:15
---

import "CoreLibs/object"

local masterplayer <const> = masterplayer
local playdate <const> = playdate
local snd <const> = playdate.sound
local lume <const> = masterplayer.lume
local abs <const> = math.abs

local tools <const> = tools
local floor <const> = math.floor
local menu <const> = playdate.getSystemMenu()
local getCrankChange <const> = playdate.getCrankChange
local justPressed <const> = playdate.buttonJustPressed
local buttonDown <const> = playdate.kButtonDown
local buttonUp <const> = playdate.kButtonUp
local buttonLeft <const> = playdate.kButtonLeft
local buttonRight <const> = playdate.kButtonRight
local buttonA <const> = playdate.kButtonA
local buttonB <const> = playdate.kButtonB

class("EditorViewModel").extends()

function EditorViewModel:init(songPath)
    self.songPath = songPath
    self.synthReferences = {}
end

function EditorViewModel:createInstrument(trackProps)
    local inst, addedSynths = masterplayer.createInstrument(trackProps)
    self.synthReferences = lume.concat(self.synthReferences, addedSynths)
    return inst
end

function EditorViewModel:getTempo()
    return self.sequence:getTempo()
end

function EditorViewModel:getNumSteps()
    return self.sequence:getLength()
end

function EditorViewModel:getCurrentStep()
    return self.sequence:getCurrentStep()
end

function EditorViewModel:getProgress()
    -- it seems currentstep can be larger than getLength, so clamp
    return lume.clamp(self:getCurrentStep() / self.sequence:getLength(), 0, 1)
end

function EditorViewModel:trackName(idx)
    local instrument = self.trackProps[idx].instrument
    return string.format("%s : ", idx) .. (instrument.name)
end

function EditorViewModel:getTrack(trackNum)
    return self.sequence:getTrackAtIndex(trackNum)
end

function EditorViewModel:getVolume(trackNum)
    return self.trackProps[trackNum].volume
end

function EditorViewModel:getNotes(trackNum, step, maxStep)
    return self:getTrack(trackNum):getNotes(step or 1, maxStep or self:getNumSteps())
end

function EditorViewModel:getNotesActive(trackNum)
    local curStep = self:getCurrentStep()
    local notes = self:getNotes(trackNum, curStep, curStep+100)
    return lume.reduce(notes, function(a, b) return a .. math.floor(b.note) .. "," end, "")
end

function EditorViewModel:isMuted(trackNum)
    return self.trackProps[trackNum].isMuted
end

--- when the track is silent, because it is muted or another track is solo
function EditorViewModel:isSilenced(trackNum)
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

function EditorViewModel:applyMuteAndSolo()
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

function EditorViewModel:toggleMuted(trackNum)
    local isMuted = self:isMuted(trackNum)
    self.trackProps[trackNum].isMuted = not isMuted
    self:applyMuteAndSolo()
    self.controlsNeedDisplay = true
end

function EditorViewModel:isSolo(trackNum)
    return self.trackProps[trackNum].isSolo
end

function EditorViewModel:toggleSolo(trackNum)
    self.trackProps[trackNum].isSolo = not self:isSolo(trackNum)
    self:applyMuteAndSolo()
    self.controlsNeedDisplay = true
end

function EditorViewModel:applyInstrument(trackNum, props)
    local newInstrument = self:createInstrument(props)
    self:getTrack(trackNum):setInstrument(newInstrument)
    -- calling play again will apply the changes to the running sequence
    self.sequence:play()
    print("Changed track", trackNum, "new refCount:", #self.synthReferences)
    self.controlsNeedDisplay = true
end

function EditorViewModel:previousInstrument(trackNum)
    local props = self.trackProps[trackNum]
    local curSynth = props.instrument
    props.instrument = selectPrevious(masterplayer.instruments, curSynth)
    self:applyInstrument(trackNum, props)
end

function EditorViewModel:nextInstrument(trackNum)
    local props = self.trackProps[trackNum]
    local curSynth = props.instrument
    props.instrument = selectNext(masterplayer.instruments, curSynth)
    self:applyInstrument(trackNum, props)
end

function EditorViewModel:getADSR(trackNum)
    local props = self.trackProps[trackNum]
    return
        props.attack,
        props.decay,
        props.sustain,
        props.release
end

--- unique midi note numbers present in track
function EditorViewModel:trackNotes(trackNum)
    return self.trackProps[trackNum].notes
end

function EditorViewModel:getNonEmptyTrackIndices()
    local result = {}
    for i, trackProps in ipairs(self.trackProps) do
        if #trackProps.notes > 0 then
            table.insert(result, i)
        end
    end
    return result
end

function EditorViewModel:changeTrackProp(trackNum, key, amount)
    local trackProps = self.trackProps[trackNum]
    local track = self:getTrack(trackNum)
    trackProps[key] = lume.clamp(
        trackProps[key] + amount,
        0, 1
    )
    printTable(trackProps)
    track:setInstrument(self:createInstrument(trackProps))
    print("Changed track", trackNum, "new refCount:", #self.synthReferences)
    self.sequence:play()
    self.controlsNeedDisplay = true
end

function EditorViewModel:movePlayHead(change)
    local targetStep = self:getCurrentStep() + floor(change * self.crankSpeed)
    targetStep = targetStep % self:getNumSteps()
    self.sequence:goToStep(targetStep, true)
end

local function changeAmount(tool)
    if tool == tools.volume then
        return 0.05
    else
        return 0.1
    end
end

function EditorViewModel:onIncrease()
    if self.selectedIdx == 0 then
        self.loadNextSong = true
    elseif self.selectedTool == tools.instrument then
        self:nextInstrument(self.selectedIdx)
    elseif self.selectedTool == tools.isMuted then
        self:toggleMuted(self.selectedIdx)
    elseif self.selectedTool == tools.isSolo then
        self:toggleSolo(self.selectedIdx)
    else
        self:changeTrackProp(self.selectedIdx, self.selectedTool.name, changeAmount(self.selectedTool))
    end
    self.controlsNeedDisplay = true
end

function EditorViewModel:onDecrease()
    if self.selectedIdx == 0 then
        self.loadPreviousSong = true
    elseif self.selectedTool == tools.instrument then
        self:previousInstrument(self.selectedIdx)
    elseif self.selectedTool == tools.isMuted then
        self:toggleMuted(self.selectedIdx)
    elseif self.selectedTool == tools.isSolo then
        self:toggleSolo(self.selectedIdx)
    else
        self:changeTrackProp(self.selectedIdx, self.selectedTool.name, -changeAmount(self.selectedTool))
    end
    self.controlsNeedDisplay = true
end

function EditorViewModel:setSelectedTrack(idx)
    self.selectedIdx = idx
    self.controlsNeedDisplay = true
end

function EditorViewModel:setSelectedTool(toolEnum)
    self.selectedTool = toolEnum
    self.controlsNeedDisplay = true
end

function EditorViewModel:load()
    local songPath = self.songPath
    self.trackProps = playdate.datastore.read(self.songPath)
    self.sequence, self.trackProps = masterplayer.loadMidi(songPath, self.trackProps)
    if not self.sequence then
        -- trackProps should contain error
        error(self.trackProps)
    end

    self.sequence, self.trackProps = masterplayer.loadMidi(songPath, self.trackProps)
    local sequence, trackProps = self.sequence, self.trackProps
    if not sequence then
        self.error = trackProps
    else
        for i,item in ipairs(trackProps) do
            local inst, addedSynths = masterplayer.createInstrument(item)
            self.synthReferences = lume.concat(self.synthReferences, addedSynths)
            sequence:getTrackAtIndex(i):setInstrument(inst)
        end
    end

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
    self.selectedTool = tools.attack
    self:applyMuteAndSolo()
    self.crankSpeed = self.sequence:getTempo() / 4
    self.sequence:play()
    ---
    self.controlsNeedDisplay = true
    self.loaded = true
end

function EditorViewModel:update()
    if justPressed(buttonDown) and self.selectedIdx < self.numTracks then
        self:setSelectedTrack(self.selectedIdx + 1)
    elseif justPressed(buttonUp) and self.selectedIdx > 1 then
        self:setSelectedTrack(self.selectedIdx - 1)
    elseif justPressed(buttonLeft) then
        self:setSelectedTool(selectPreviousEnum(tools, self.selectedTool))
    elseif justPressed(buttonRight) then
        self:setSelectedTool(selectNextEnum(tools, self.selectedTool))
    elseif justPressed(buttonA) then
        self:onIncrease()
    elseif justPressed(buttonB) then
        self:onDecrease()
    end

    local _, accChange = getCrankChange()
    if abs(accChange) > 1 then
        self:movePlayHead(accChange)
        if not self.sequence:isPlaying() then
            self.sequence:play()
        end
    end
end


function EditorViewModel:crankDocked()
    self.sequence:play()
end

function EditorViewModel:crankUndocked()
    self.sequence:stop()
end

function EditorViewModel:save()
    print("saving", self.songPath)
    playdate.datastore.write(self.trackProps, self.songPath, true)
    setMessage("Saved : " .. self.songPath .. ".json")
end

function EditorViewModel:finish()
    self:save()
    self.sequence:stop()
end

function EditorViewModel:keyReleased(key)
    local trackNum = self.selectedIdx
    if key == "m" then
        self:toggleMuted(trackNum)
    elseif key == "n" then
        self:toggleSolo(trackNum)
    elseif key == "i" then
        self:nextInstrument(trackNum)
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

function EditorViewModel:setMenuItems()
    menu:removeAllMenuItems()

    menu:addCheckmarkMenuItem("Auto-save", isAutoSaveEnabled(), function(isChecked)
        setAutoSaveEnabled(isChecked)
        self:setMenuItems()
    end)
    menu:addMenuItem("Open", function()
        pushScreen(FileSelectorScreen.createMidiPicker())
    end)

    if not isAutoSaveEnabled() then
        menu:addMenuItem("Save", function()
            self:save()
        end)
    end
end

function EditorViewModel:resume()
    self.controlsNeedDisplay = true
    self:setMenuItems()
end

function EditorViewModel:gameWillPause()
    self:pause()
end

function EditorViewModel:pause()
    self.sequence:stop()
    if isAutoSaveEnabled() then
        self:save()
    end
end

function EditorViewModel:destroy()
    self:pause()

    for i=1, self.numTracks do
        self:getTrack(i):clearNotes()
    end
    self.sequence = nil
    self.synthReferences = nil
end
