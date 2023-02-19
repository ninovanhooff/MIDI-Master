local gfx <const>  = playdate.graphics
gfx.setFont(playdate.graphics.font.new("fonts/font-pedallica"))

import '../toyboxes/toyboxes.lua'
import "CoreLibs/object"
import "CoreLibs/crank"

local lume <const> = masterplayer.lume
import "util"
import "enum"
import "navigation/screen"
local navigator <const> = import "navigation/navigator"
import "model"
import "editor/EditorScreen"
import "fileselector/FileSelectorScreen"

local datastore <const> = playdate.datastore

playdate.display.setRefreshRate(30)
local screenW <const> = playdate.display.getWidth()
local screenH <const> = playdate.display.getHeight()


masterplayer.addInstrument(com_ninovanhooff_masterplayer_choir_ah, "ChoirAh")
masterplayer.addInstrument(com_ninovanhooff_masterplayer_drums_electric, "Drums-E")
masterplayer.addInstrument(com_ninovanhooff_masterplayer_drums_pd, "Drums-PD")

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

function getSongPath()
    return config.currentSongPath
end

function setSongPath(newPath)
    config.currentSongPath = newPath
    datastore.write(config)
end

function playdate.update()
    navigator:updateActiveScreen()

    if message then
        showMessage()
    end

    messageJustHidden = false
    playdate.timer:updateTimers()
end

function setMessage(text)
    message = text
end

function setMessage(text)
    message = text
    messageTimer = playdate.timer.performAfterDelay(2000, function()
        message = nil
        messageJustHidden = true
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

function playdate.crankDocked()
    viewModel:crankDocked()
end

function playdate.crankUndocked()
    viewModel:crankUndocked()
end

printTable(songPaths)

local menu <const> = playdate.getSystemMenu()
menu:addMenuItem("Save", function()
    viewModel:save()
end)

function playdate.gameWillPause() navigator:gameWillPause() end
function playdate.deviceWillLock() navigator:gameWillPause() end
function playdate.gameWillResume() navigator:gameWillResume() end
function playdate.deviceDidUnlock() navigator:gameWillResume() end

pushScreen(FileSelectorScreen("Open file"))
pushScreen(EditorScreen(getSongPath()))

-- should remain last line to ensure activeScreen and proper navigation structure
navigator:start()
