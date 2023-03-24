--- A Screen contains all necessary code to present a part of the program fullscreen,
--- eg. a level select screen, or gameplay or game-over screen
class("Screen").extends()

--- Called every frame
function Screen:update()
    -- no-op, implemented in subclasses
end

--- Notify screen that it will be hidden.
--- It is not necessary to remove previously added menu items, because the menu will be cleared
--- Only called when it might be resumed later.
--- (ie. only when another screen is pushed over it; not when it is popped off the backstack)
function Screen:pause()
    -- no-op, implemented in subclasses
end

--- Notify screen that it will become visible to the user,
--- either for the first time or after it was paused
--- and subsequently brought back to the front of the backstack
--- This is a good place to add system menu items for this screen.
--- Called before update()
function Screen:resume()
    -- no-op, implemented in subclasses
end

--- Called when eg. the system menu appears or the device is locked
function Screen:gameWillPause()
    -- no-op, implemented in subclasses
end

--- Called when eg. the system menu disappears or the device is unlocked
function Screen:gameWillResume()
    -- no-op, implemented in subclasses
end

function Screen:crankDocked()
    -- no-op, implemented in subclasses
end

function Screen:crankUndocked()
    -- no-op, implemented in subclasses
end


--- Called when this screen is popped off the stack. It will never be resumed,
--- So this is a good place for freeing up RAM, cleanup, etc.
--- It is not necessary to remove previously added menu items, because the menu will be cleared
--- automatically
function Screen:destroy()
    -- no-op, implemented in subclasses
end

function Screen:debugDraw()
    -- no-op, implemented in subclasses
end
