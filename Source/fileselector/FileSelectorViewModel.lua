local playdate <const> = playdate
local keyRepeatTimer <const> = playdate.timer.keyRepeatTimer
local getCrankTicks <const> = playdate.getCrankTicks
local justPressed <const> = playdate.buttonJustPressed
local justReleased <const> = playdate.buttonJustReleased
local buttonDown <const> = playdate.kButtonDown
local buttonUp <const> = playdate.kButtonUp
local buttonA <const> = playdate.kButtonA
local buttonB <const> = playdate.kButtonB
local abs <const> = math.abs
local clamp <const> = clamp

class("FileSelectorViewModel").extends()

function FileSelectorViewModel:init(title)
    FileSelectorViewModel.super.init(self)
    self.title = title
    self.entries = {}
    for i, item in ipairs(songPaths) do
        self.entries[i] = {
            path = item
        }
    end
    self.listOffset = 0 -- vertical position, for bumper effect
    self.selectedIdx = 1
    self.keyTimer = nil
    self.keyTimerRemover = self:createKeyTimerRemover()
end

function FileSelectorViewModel:createKeyTimerRemover()
    return function()
        if self.keyTimer then
            self.keyTimer:remove()
            self.keyTimer = nil
        end
    end
end

function FileSelectorViewModel:moveSelection(offset)
    if offset == 0 then return end

    local oldSelectedIdx = self.selectedIdx
    self.selectedIdx = clamp(oldSelectedIdx + offset, 1, #self.entries)

end

--- returns true when finished
function FileSelectorViewModel:update()
    -- clear bumpers by overdraw
    if abs(self.listOffset) > 1 then
        self.listOffset = self.listOffset/2
    else
        self.listOffset = 0
    end

    self:moveSelection(getCrankTicks(5))

    if justPressed(buttonDown) then
        local function timerCallback()
            self:moveSelection(1)
        end
        self.keyTimerRemover()
        self.keyTimer = keyRepeatTimer(timerCallback)
    elseif justPressed(buttonUp) then
        local function timerCallback()
            self:moveSelection(-1)
        end
        self.keyTimerRemover()
        self.keyTimer = keyRepeatTimer(timerCallback)
    elseif justReleased(buttonDown | buttonUp) then
        self:keyTimerRemover()
    elseif justPressed(buttonA) then
        self.aButtonPressedAtLeastOnce = true
    elseif justReleased(buttonA) and self.aButtonPressedAtLeastOnce then
        setSongPath(self:selectedEntry().path)
        -- todo start editor
    elseif justPressed(buttonB) then
        popScreen()
    end
end

function FileSelectorViewModel:selectedEntry()
    return self.entries[self.selectedIdx]
end


function FileSelectorViewModel:pause()
    self.newUnlock = nil
    self:keyTimerRemover()
end

function FileSelectorViewModel:gameWillPause()
    self:keyTimerRemover()
end

function FileSelectorViewModel:destroy()
    self:pause()
    if self.videoViewModel then
        self.videoViewModel:destroy()
    end
end
