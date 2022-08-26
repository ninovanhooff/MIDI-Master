---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by ninovanhooff.
--- DateTime: 22/07/2022 15:10
---

import "CoreLibs/object"
import "CoreLibs/ui"
import "CoreLibs/graphics"

local gfx <const> = playdate.graphics
local rect <const> = playdate.geometry.rect
local lume <const> = lume
local screenW <const> = playdate.display.getWidth()
local tools <const> = tools
local floor <const> = math.floor
local listY <const> = 18
local smallGutter <const> = 2
local gutter <const> = 4
local trackControlsWidth <const> = 150
local buttonRadius <const> = 2
local rowHeight <const> = 40
local progressBarWidth <const> = 100
local selectionWidth <const> = 2
local progressBarX <const> = screenW - progressBarWidth - smallGutter
local viewModel
local listView = playdate.ui.gridview.new(0, rowHeight)
local trackStrips, stripWidth
listView:setCellPadding(0, 0, 0, smallGutter) -- left, right , top, bottom


class("View").extends()

function View:init(vm)
    trackStrips = {}
    viewModel = vm
    local numTracks = vm.numTracks
    if vm.numTracks == 0 then
        self.error = "Number of tracks is 0. Was the filename spelled correctly?"
        return
    end

    local numSteps = vm:getNumSteps()
    local stepsPerPixel = lume.clamp(
        numSteps / screenW,
        1, 4
    )
    if numSteps / stepsPerPixel > 4000 then
        -- this would be too wide for comfort, bitmap size is limiting factor
        stepsPerPixel = numSteps / 4000
    end
    stripWidth = numSteps / stepsPerPixel
    print("steps per pixel", stepsPerPixel, "stripWidth", stripWidth)
    listView:setNumberOfRows(numTracks)
    for i = 1, numTracks do
        local curStrip = gfx.image.new(stripWidth, rowHeight)
        gfx.pushContext(curStrip)
        trackStrips[i] = curStrip

        local notes = vm:getNotes(i)
        for _, note in ipairs(notes) do
            for curStep = note.step, note.step + note.length do
                gfx.drawPixel(floor(curStep/stepsPerPixel), ((127-note.note) / 127) * rowHeight)
            end
        end
        gfx.popContext()
    end
end

function listView:drawCell(_, row, _, selected, x, y, width, height)
    gfx.pushContext()
    local selectedToolRect
    local font = gfx.getFont()
    if selected then
        gfx.fillRect(x,y+1,trackControlsWidth,height)
    else
        gfx.drawRect(x,y+1,trackControlsWidth,height)
    end

    gfx.setColor(playdate.graphics.kColorXOR)
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

    -- Notes
    gfx.setClipRect(x+trackControlsWidth, listY, screenW-x-trackControlsWidth, 240)


    if viewModel:isSilenced(row) then
        gfx.pushContext()
        gfx.setDitherPattern(0.8, gfx.image.kDitherTypeDiagonalLine) -- invert alpha due to bug in SDK
        gfx.fillRect(trackControlsWidth, y+1, width - trackControlsWidth, height)
        gfx.popContext()
    end

    trackStrips[row]:draw(
        trackControlsWidth - (viewModel:getProgress() * stripWidth),
        y
    )

    gfx.popContext()
end

function drawPot(text, x, y, value)
    value = lume.clamp(value, 0.03, 1.0)
    gfx.drawArc(x, y, 8, 225, 225 + (value*270))
    gfx.drawText(text, x-4, y-8)
end

function View:draw()
    gfx.clear(gfx.kColorWhite)

    -- draw filename without escapes
    local font = gfx.getFont()
    font:drawText(viewModel.currentSongPath, 2,2)

    if viewModel.selectedIdx == 0 then
        -- song selection
        gfx.pushContext()
        gfx.setLineWidth(selectionWidth)
        gfx.setPattern({0x88, 0x44, 0x22, 0x11, 0x88, 0x44, 0x22, 0x11})
        gfx.drawRoundRect(1,1, font:getTextWidth(viewModel.currentSongPath) + 4, 18, 2)
        gfx.popContext()
    end

    if self.error then
        gfx.drawText(self.error, 50,100)
        return
    end

    if listView:getSelectedRow() ~= viewModel.selectedIdx then
        listView:setSelectedRow(viewModel.selectedIdx)
        listView:scrollToRow(viewModel.selectedIdx)
    end

    -- tracks
    listView:drawInRect(smallGutter, listY,screenW - smallGutter,220)

    -- progress
    gfx.drawRect(progressBarX, smallGutter, progressBarWidth, 12)
    gfx.fillRect(
        progressBarX + smallGutter, smallGutter + smallGutter,
        (progressBarWidth - 2* smallGutter) * viewModel:getProgress(),
        12 - 2 * smallGutter)
    gfx.drawLine(0, listY - 1,screenW, listY - 1)

end
