---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by ninovanhooff.
--- DateTime: 22/07/2022 15:10
---

import "CoreLibs/object"
import "CoreLibs/ui"
import "CoreLibs/graphics"

local gfx <const> = playdate.graphics
local font <const> = gfx.getFont()

local rect <const> = playdate.geometry.rect
local lume <const> = masterplayer.lume
local screenW <const> = playdate.display.getWidth()
local tools <const> = tools
local floor <const> = math.floor
local max <const> = math.max
local isSimulator <const> = playdate.isSimulator
local listY <const> = 18
local smallGutter <const> = 2
local gutter <const> = 4
local trackControlsWidth <const> = 150
local buttonRadius <const> = 2
local rowHeight <const> = 40
local progressBarWidth <const> = 100
local selectionWidth <const> = 2
local progressBarX <const> = screenW - progressBarWidth - smallGutter
local maxStripWidth <const> = 4000

class("EditorView").extends()

local function createDrawInstrumentControls(viewModel) return function(_, row, selected, x, y, _, height)
    gfx.pushContext()

    if selected then
        gfx.fillRect(x,y,trackControlsWidth,height)
    else
        gfx.drawRect(x,y,trackControlsWidth,height)
    end

    gfx.setColor(gfx.kColorXOR)
    gfx.setImageDrawMode(gfx.kDrawModeNXOR) -- text

    font:drawText(viewModel:trackName(row), x + gutter, y + gutter)

    local soloButtonX = x+gutter
    local muteButtonX = x + 16 + gutter*2
    local buttonY = y + 20

    -- solo
    if viewModel:isSolo(row) then
        gfx.fillRoundRect(soloButtonX, buttonY, 16,16, buttonRadius)
    else
        gfx.drawRoundRect(soloButtonX, buttonY, 16,16, buttonRadius)
    end
    gfx.drawText("s", soloButtonX+5, buttonY)

    -- mute
    if viewModel:isMuted(row) then
        gfx.fillRoundRect(muteButtonX, buttonY, 16,16, buttonRadius)
    else
        gfx.drawRoundRect(muteButtonX, buttonY, 16,16, buttonRadius)
    end
    gfx.drawText("m", muteButtonX + 3, buttonY)

    gfx.setLineWidth(2)
    local potY = y + 13
    local potY2 = y + 31
    local potSpacing = 22
    local attack, decay, sustain, release = viewModel:getADSR(row)

    -- volume
    local volumeX <const> = muteButtonX + 24
    local volumeY <const> = buttonY + 11
    local volumeTrackLength <const> = 40
    local volumeHeight <const> = 8
    local volumePos = lume.lerp(
        volumeX, volumeX+volumeTrackLength,
        viewModel:getVolume(row)
    )
    gfx.drawLine(volumeX, volumeY, volumeX+volumeTrackLength, volumeY)
    gfx.fillCircleAtPoint(volumePos, volumeY, volumeHeight / 2)
    gfx.drawLine(volumePos, volumeY-2, volumePos, volumeY+2)

    -- attack
    local attackX = trackControlsWidth - 40
    drawPot("a", attackX, potY, attack)
    -- decay
    local decayX = attackX + potSpacing
    drawPot("d", decayX, potY, decay)
    -- sustain
    local sustainX = attackX
    drawPot("s", sustainX, potY2, sustain)
    -- release
    local releaseX = sustainX + potSpacing
    drawPot("r", releaseX, potY2, release)

    local selectedToolRect
    if selected then
        local tool = viewModel.selectedTool
        if tool == tools.instrument then
            selectedToolRect = rect.new(x + smallGutter, y + smallGutter + 1, font:getTextWidth(viewModel:trackName(row)) + gutter, 15)
        elseif tool == tools.isSolo then
            selectedToolRect = rect.new(soloButtonX - 2, buttonY - 2, 20, 20)
        elseif tool == tools.isMuted then
            selectedToolRect = rect.new(muteButtonX - 2, buttonY - 2, 20, 20)
        elseif tool == tools.volume then
            selectedToolRect = rect.new(volumeX - 4, volumeY - 6, volumeTrackLength + 7, volumeHeight + 3)
        elseif tool == tools.attack then
            selectedToolRect = rect.new(attackX - 11, potY - 10, 22, 18)
        elseif tool == tools.decay then
            selectedToolRect = rect.new(decayX - 11, potY - 10, 22, 18)
        elseif tool == tools.sustain then
            selectedToolRect = rect.new(sustainX - 11, potY2 - 10, 22, 18)
        elseif tool == tools.release then
            selectedToolRect = rect.new(releaseX - 11, potY2 - 10, 22, 18)
        end
    end


    gfx.setLineWidth(1)
    -- selected tool rectangle
    if selectedToolRect then
        gfx.pushContext()
        gfx.setLineWidth(selectionWidth)
        gfx.setPattern({0x77, 0xBB, 0xDD, 0xEE, 0x77, 0xBB, 0xDD, 0xEE})
        gfx.drawRoundRect(selectedToolRect, 2)
        gfx.popContext()
    end
    gfx.popContext()
end
end


local function createListViewDrawCell(view, viewModel) return function (_,_, row, _, selected, x, y, width, height)
    local listView = view.listView
    local trackStrips = view.trackStrips
    if viewModel.controlsNeedDisplay or listView.needsDisplay or messageJustHidden then
        listView:drawInstrumentControls(row, selected, x, y, width, height)
    end

    if listView.needsDisplay or #viewModel:trackNotes(row) > 0 then
        gfx.pushContext()
        -- clipRect for notes area
        gfx.setClipRect(x+trackControlsWidth, max(y, listY), width, height)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(x+trackControlsWidth, y, width, height)
        gfx.setColor(gfx.kColorBlack)

        -- Shade silenced tracks
        if viewModel:isSilenced(row) then
            gfx.pushContext()
            gfx.setDitherPattern(0.8, gfx.image.kDitherTypeDiagonalLine) -- invert alpha due to bug in SDK
            gfx.fillRect(trackControlsWidth, y+1, width - trackControlsWidth, height)
            gfx.popContext()
        end

        -- notes (trackStrips)
        if trackStrips[row] then
            trackStrips[row]:draw(
                trackControlsWidth - (viewModel:getProgress() * view.stripWidth),
                y
            )
        end


        -- note info
        local activeNotesText = viewModel:getNotesActive(row)
        if isSimulator then
            gfx.drawText(activeNotesText, screenW - font:getTextWidth(activeNotesText), y + gutter)
        end

        gfx.popContext()
    end



end
end

function EditorView:init(vm)
    gfx.clear(gfx.kColorWhite)
    self.trackStrips = {}
    self.stripWidth = 0
    self.viewModel = vm
    self.listView = playdate.ui.gridview.new(0, rowHeight)
    local listView = self.listView
    listView:setCellPadding(0, 0, 0, smallGutter) -- left, right , top, bottom

    listView.view = self
    listView.viewModel = viewModel
    listView.drawInstrumentControls = createDrawInstrumentControls(self.viewModel)
    listView.drawCell = createListViewDrawCell(self, self.viewModel)
    if self.viewModel.numTracks == 0 then
        self.error = "Number of tracks is 0. Was the filename spelled correctly?"
        return
    end

    self.trackStripsBuilder = coroutine.create(self.buildStripsYielding)
end

function drawPot(text, x, y, value)
    value = lume.clamp(value, 0.03, 1.0)
    gfx.drawArc(x, y, 8, 225, 225 + (value*270))
    gfx.drawText(text, x-4, y-8)
end

function EditorView:buildStripsYielding()
    local viewModel = self.viewModel
    local nonEmptyTrackIndices = viewModel:getNonEmptyTrackIndices()
    local dynamicStepWindow = 800
    local numSteps = viewModel:getNumSteps()
    local stepsPerPixel = lume.clamp(
        numSteps / screenW,
        1, 4
    )
    if numSteps / stepsPerPixel > maxStripWidth then
        -- this would be too wide for comfort, bitmap size is limiting factor
        stepsPerPixel = numSteps / maxStripWidth
    end
    self.stripWidth = numSteps / stepsPerPixel
    print("steps per pixel", stepsPerPixel)
    for _, trackIdx in ipairs(nonEmptyTrackIndices) do
        coroutine.yield(0)
        local curStrip = gfx.image.new(self.stripWidth, rowHeight)
        self.trackStrips[trackIdx] = curStrip
    end
    local step = 1
    while step < numSteps do
        local _, estimatedLoad = coroutine.yield(step/numSteps)
        for _, trackIdx in ipairs(nonEmptyTrackIndices) do
            local curStrip = self.trackStrips[trackIdx]
            gfx.pushContext(curStrip)

            local notes = viewModel:getNotes(trackIdx, step, step + dynamicStepWindow)
            for _, note in ipairs(notes) do
                local y = ((127-note.note) / 127) * rowHeight
                gfx.drawLine(
                    floor(note.step/stepsPerPixel), y,
                    floor((note.step + note.length)/stepsPerPixel), y
                )
            end
            gfx.popContext()
        end

        step = step + dynamicStepWindow
        if estimatedLoad > 0.9 then
            dynamicStepWindow = floor(dynamicStepWindow * 0.9)
        elseif estimatedLoad < 0.6 then
            dynamicStepWindow = floor(dynamicStepWindow * 1.1)
        end
        dynamicStepWindow = lume.clamp(dynamicStepWindow,100, 5000)
        print("load and window", estimatedLoad, dynamicStepWindow)
    end
end

function EditorView:drawStaticUI()
    gfx.pushContext()
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0,0, screenW, listY)
    gfx.setColor(gfx.kColorBlack)
    -- draw filename without escapes
    font:drawText(self.viewModel.songPath, 2,2)
    -- progress outline
    gfx.drawRect(progressBarX, smallGutter, progressBarWidth, 12)
    self.staticUIDrawn = true
    gfx.popContext()
end

function EditorView:drawLoading(songPath)
    local text = "Loading " .. songPath .. " . . ."
    local w,h = gfx.getTextSize(text)
    gfx.clear(gfx.kColorWhite)
    font:drawText(text, 200- w/2, 120 - h/2, kTextAlignment.center)
end

function EditorView:songLoaded()
    self.listView:setNumberOfRows(self.viewModel.numTracks)
end

function EditorView:draw(viewModel, estimatedLoad)
    if not self.staticUIDrawn or viewModel.controlsNeedDisplay then
        self:drawStaticUI()
    end

    local loadProgress = 0
    if coroutine.status(self.trackStripsBuilder) ~= "dead" then
        _, loadProgress = coroutine.resume(self.trackStripsBuilder, self, estimatedLoad)
        if type(loadProgress) == "string" then
            error(loadProgress)
        end
        if not loadProgress then
            loadProgress = 1
        end
    end


    -- progress
    ---- clear, in case of rewind
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(
        progressBarX + smallGutter, smallGutter + smallGutter,
        progressBarWidth - smallGutter - smallGutter,
        12 - 2 * smallGutter)
    ---- draw load progress
    gfx.setColor(gfx.kColorBlack)
    --gfx.setPattern({0xFF, 0xFF, 0xFF, 0x0, 0x0, 0xFF, 0xFF, 0xFF})
    gfx.fillRect(
        progressBarX + smallGutter*2, smallGutter + 5,
        (progressBarWidth - 4* smallGutter) * loadProgress,
        6 - 2 * smallGutter)
    ---- draw play progress
    gfx.setColor(gfx.kColorXOR)
    gfx.fillRect(
        progressBarX + smallGutter, smallGutter + smallGutter,
        (progressBarWidth - 2* smallGutter) * viewModel:getProgress(),
        12 - 2 * smallGutter)


    gfx.setColor(gfx.kColorBlack)
    -- title bar divider
    gfx.drawLine(0, listY - 1,screenW, listY - 1)

    if viewModel.selectedIdx == 0 then
        -- song selection
        gfx.pushContext()
        gfx.setLineWidth(selectionWidth)
        gfx.setPattern({0x88, 0x44, 0x22, 0x11, 0x88, 0x44, 0x22, 0x11})
        gfx.drawRoundRect(1,1, font:getTextWidth(viewModel.songPath) + 4, 18, 2)
        gfx.popContext()
    end

    if self.error then
        gfx.drawText(self.error, 50,100)
        return
    end

    local listView = self.listView
    if listView:getSelectedRow() ~= viewModel.selectedIdx then
        listView:setSelectedRow(viewModel.selectedIdx)
        listView:scrollToRow(viewModel.selectedIdx)
    end

    -- tracks (strips + controls)
    if viewModel.controlsNeedDisplay or listView.needsDisplay or messageJustHidden then
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, listY,screenW,240-listY)
        gfx.setColor(gfx.kColorBlack)
    end
    listView:drawInRect(smallGutter, listY,screenW - smallGutter,240-listY)
    viewModel.controlsNeedDisplay = false
end

function EditorView:resume()
    self.staticUIDrawn = false
end
