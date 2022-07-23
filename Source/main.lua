lume = import "lume"
import "util"
import "Instrument"
import "midi"
import "ViewModel"
import "View"

local gfx = playdate.graphics

playdate.display.setRefreshRate(50)
gfx.setFont(playdate.graphics.font.new("fonts/font-pedallica"))

local currentSongName
local viewModel
local view

songNames = lume.filter(
    playdate.file.listFiles("songs"),
    function(filename)
        print("yo filename", filename)
        return endsWith(string.lower(filename), ".mid")
    end
)

local function initNextSong()
    if viewModel then
        viewModel:destroy()
    end
    currentSongName = selectNext(songNames, currentSongName)
    viewModel = ViewModel(currentSongName)
    view = View(viewModel)
end

initNextSong()

function playdate.update()
    viewModel:update()
    view:draw()
    playdate.timer:updateTimers()
end

function playdate.keyReleased(key)
    print("Released " .. key .. " key")

    if key == "q" then
        initNextSong()
    else
        viewModel:keyReleased(key)
    end
end
