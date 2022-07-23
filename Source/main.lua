lume = import "lume"
import "util"
import "Instrument"
import "midi"
import "ViewModel"
import "View"

local gfx = playdate.graphics

playdate.display.setRefreshRate(50)
gfx.setFont(playdate.graphics.font.new("fonts/font-pedallica"))

local currentSongPath
local viewModel
local view

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
    playdate.timer:updateTimers()
end

function playdate.keyReleased(key)
    print("Released " .. key .. " key")

    if key == "z" then
        initNextSong()
    else
        viewModel:keyReleased(key)
    end
end
