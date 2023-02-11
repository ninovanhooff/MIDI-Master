local gfx <const>  = playdate.graphics
gfx.setFont(playdate.graphics.font.new("fonts/font-pedallica"))

import '../toyboxes/toyboxes.lua'
import "CoreLibs/object"
local lume <const> = masterplayer.lume
import "util"
import "enum"
import "model"
import "ViewModel"
import "View"

local datastore <const> = playdate.datastore

playdate.display.setRefreshRate(30)
local screenW <const> = playdate.display.getWidth()
local screenH <const> = playdate.display.getHeight()


masterplayer.addInstrument(com_ninovanhooff_masterplayer_choir_ah, "ChoirAh")
masterplayer.addInstrument(com_ninovanhooff_masterplayer_drums_electric, "Drums-E")

songPaths = lume.filter(
    listFilesRecursive(),
    function(filename)
        return endsWith(string.lower(filename), ".mid")
    end
)

if #songPaths < 1 then
    error("No songs found. Place your .mid files in the 'songs' folder inside the MIDI Master pdx" )
end

local config = datastore.read() or { currentSongPath = songPaths[1] }


local viewModel
local view
local messageRect <const> = playdate.geometry.rect.new(0, screenH - 20, screenW, 20)
local messageTimer
message = nil

local function getSongPath()
    return config.currentSongPath
end

local function setSongPath(newPath)
    config.currentSongPath = newPath
    datastore.write(config)
end

local function initNextSong()
    if viewModel then
        viewModel:finish()
    end
    setSongPath(selectNext(songPaths, getSongPath()))
    viewModel = ViewModel(getSongPath())
    view = View(viewModel)
end

local function initPreviousSong()
    if viewModel then
        viewModel:finish()
    end
    setSongPath(selectPrevious(songPaths, getSongPath()))
    viewModel = ViewModel(getSongPath())
    view = View(viewModel)
end

function playdate.update()
    viewModel:update()
    if viewModel.loadNextSong then
        initNextSong()
        return
    elseif viewModel.loadPreviousSong then
        initPreviousSong()
        return
    end
    view:draw()

    if message then
        showMessage()
    end

    playdate.timer:updateTimers()
end

function setMessage(text)
    message = text

end

function setMessage(text)
    message = text
    messageTimer = playdate.timer.performAfterDelay(2000, function()
        message = nil
    end)
end

function showMessage()
    gfx.pushContext()
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(messageRect)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(messageRect.x, messageRect.y, messageRect.right, messageRect.y)
    gfx.getFont():drawText(message, messageRect.x + 4, messageRect.y + 4)
    gfx.popContext()
end

function playdate.keyReleased(key)
    print("Released " .. key .. " key")

    if key == "z" then
        initNextSong()
    else
        viewModel:keyReleased(key)
    end
end

function playdate.crankDocked()
    viewModel:crankDocked()
end

function playdate.crankUndocked()
    viewModel:crankUndocked()
end

printTable(songPaths)
viewModel = ViewModel(getSongPath())
view = View(viewModel)

local menu <const> = playdate.getSystemMenu()
menu:addMenuItem("Save", function()
    viewModel:save()
end)
