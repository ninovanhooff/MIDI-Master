import "CoreLibs/object"
lume = import "lume"
import "util"
import "enum"
import "Instrument"
import "midi"
import "model"
import "ViewModel"
import "View"

local gfx = playdate.graphics

playdate.display.setRefreshRate(50)
local screenW <const> = playdate.display.getWidth()
local screenH <const> = playdate.display.getHeight()

gfx.setFont(playdate.graphics.font.new("fonts/font-pedallica"))

local currentSongPath
local viewModel
local view
local messageRect <const> = playdate.geometry.rect.new(0, screenH - 20, screenW, 20)
local messageTimer
message = nil

songPaths = lume.filter(
    listFilesRecursive(),
    function(filename)
        return endsWith(string.lower(filename), ".mid")
    end
)

printTable(songPaths)

local function initNextSong()
    if viewModel then
        viewModel:finish()
    end
    currentSongPath = selectNext(songPaths, currentSongPath)
    viewModel = ViewModel(currentSongPath)
    view = View(viewModel)
end

initNextSong()

function playdate.update()
    viewModel:update()
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
