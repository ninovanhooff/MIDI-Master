import "midi"
import "ViewModel"
import "View"

local gfx = playdate.graphics

gfx.setFont(playdate.graphics.font.new("fonts/font-pedallica"))

local sequence = loadMidi('europe_finalcountdown_60s.mid')
sequence:play()

local viewModel = ViewModel(sequence)
local view = View(viewModel)

function playdate.update()
    viewModel:update()
    view:draw()
    playdate.timer:updateTimers()
end
