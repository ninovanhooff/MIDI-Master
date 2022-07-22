import "midi"

local gfx = playdate.graphics

local sequence = loadMidi('europe_finalcountdown_60s.mid')
sequence:play()

gfx.setColor(gfx.kColorBlack)

function playdate.update()
    gfx.fillRect(0, 0, 400, 240)
    playdate.drawFPS(0,0)
end
