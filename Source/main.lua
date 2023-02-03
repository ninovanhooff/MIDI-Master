local gfx <const>  = playdate.graphics
gfx.setFont(playdate.graphics.font.new("fonts/font-pedallica"))

import "CoreLibs/object"
lume = import "lume"
import "util"
import "enum"
import "Instrument"
import "libs/master-player/midi"
import "model"
import "ViewModel"
import "View"

local datastore <const> = playdate.datastore

playdate.display.setRefreshRate(20)
local screenW <const> = playdate.display.getWidth()
local screenH <const> = playdate.display.getHeight()


songPaths = lume.filter(
    listFilesRecursive(),
    function(filename)
        return endsWith(string.lower(filename), ".mid")
    end
)

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

printTable(songPaths)
viewModel = ViewModel(getSongPath())
view = View(viewModel)

local menu <const> = playdate.getSystemMenu()
menu:addMenuItem("Save", function()
    viewModel:save()
end)
