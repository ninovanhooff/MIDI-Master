lume = import "lume"
import "Instrument"
import "midi"
import "ViewModel"
import "View"

local gfx = playdate.graphics

playdate.display.setRefreshRate(50)
gfx.setFont(playdate.graphics.font.new("fonts/font-pedallica"))

local viewModel = ViewModel('europe_finalcountdown_60s.mid')
local view = View(viewModel)

function playdate.update()
    viewModel:update()
    view:draw()
    playdate.timer:updateTimers()
end

function playdate.keyReleased(key)
    print("Released " .. key .. " key")
    viewModel:keyReleased(key)
end
