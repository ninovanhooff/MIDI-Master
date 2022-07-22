---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by ninovanhooff.
--- DateTime: 22/07/2022 15:10
---

import "CoreLibs/object"
import "CoreLibs/ui"

local gfx <const> = playdate.graphics
local stepWidth <const> = 4
local smallGutter <const> = 2
local gutter <const> = 4
local trackControlsWidth <const> = 150
local buttonRadius <const> = 2
local rowHeight <const> = 40
local viewModel
local listView = playdate.ui.gridview.new(0, rowHeight)
listView:setCellPadding(0, 0, gutter, gutter) -- left, right , top, bottom


class("View").extends()

function View:init(vm)
    viewModel = vm
    listView:setNumberOfRows(vm.numTracks)
end

function listView:drawCell(section, row, column, selected, x, y, width, height)
    gfx.pushContext()
    if selected then
        gfx.fillRect(x,y,trackControlsWidth,height)
    else
        gfx.drawRect(x,y,trackControlsWidth,height)
    end

    gfx.setColor(playdate.graphics.kColorXOR)
    gfx.setImageDrawMode(gfx.kDrawModeNXOR) -- text

    gfx.drawText(viewModel:trackName(row), x + gutter, y + gutter)

    local soloButtonX = x+gutter
    local muteButtonX = x + 16 + gutter*2
    local buttonY = y + 20

    if viewModel:isSolo(row) then
        gfx.fillRoundRect(soloButtonX, buttonY, 16,16, buttonRadius)
    else
        gfx.drawRoundRect(soloButtonX, buttonY, 16,16, buttonRadius)
    end
    gfx.drawText("s", soloButtonX+3, buttonY)

    if viewModel:isMuted(row) then
        gfx.fillRoundRect(muteButtonX, buttonY, 16,16, buttonRadius)
    else
        gfx.drawRoundRect(muteButtonX, buttonY, 16,16, buttonRadius)
    end
    gfx.drawText("m", muteButtonX + 3, buttonY)


    -- Notes
    gfx.setClipRect(x+trackControlsWidth, 0, 400-x-trackControlsWidth, 240)
    local stepOffset, noteY
    local currentStep = viewModel:getCurrentStep()
    local lastStepOffset = 0
    local simultaneous = 0
    for _, item in ipairs(viewModel:getVisibleNotes(row)) do
        stepOffset = (item.step - currentStep) * stepWidth
        if stepOffset == lastStepOffset then
            simultaneous = simultaneous + 1
        else
            simultaneous = 0
        end
        lastStepOffset = stepOffset
        noteY = y + gutter + item.velocity*4 + simultaneous * 4
        gfx.fillRect(x + trackControlsWidth + gutter + stepOffset, noteY, (item.length/ stepWidth),3)
    end

    gfx.popContext()
end

function View:draw()
    gfx.clear(gfx.kColorWhite)
    if listView:getSelectedRow() ~= viewModel.selectedIdx then
        listView:setSelectedRow(viewModel.selectedIdx)
        listView:scrollToRow(viewModel.selectedIdx)
    end

    -- progress

    gfx.drawRect(100, gutter, 200, 12)
    gfx.fillRect(
        100 + smallGutter, gutter + smallGutter,
        (200 - 2* smallGutter) * viewModel:getProgress(),
        12 - 2 * smallGutter)

    listView:drawInRect(0,20,400,220)
end
