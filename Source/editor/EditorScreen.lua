import "EditorView"
import "EditorViewModel"

local getRefreshRate <const> = playdate.display.getRefreshRate
local currentTime <const> = playdate.sound.getCurrentTime

class("EditorScreen").extends(Screen)

function EditorScreen:init(songPath)
    EditorScreen.super.init(self)

    self.estimatedLoad = 0.5
    self.editorViewModel = EditorViewModel(songPath)
    self.editorView = EditorView(self.editorViewModel)
end

function EditorScreen:resume()
    self.editorViewModel:resume()
    self.editorView:resume()
end

function EditorScreen:gameWillPause()
    self.editorViewModel:gameWillPause()
end

function EditorScreen:crankDocked()
    self.editorViewModel:crankDocked()
end

function EditorScreen:crankUndocked()
    self.editorViewModel:crankUndocked()
end

function EditorScreen:destroy()
    self.editorViewModel:destroy()
end

function EditorScreen:update()
    local startTime = currentTime()
    if not self.editorViewModel.loaded then
        self.editorView:drawLoading(self.editorViewModel.songPath)
        coroutine.yield() -- flush screen updates
        self.editorViewModel:load()
        self.editorView:songLoaded()
    end
    self.editorViewModel:update()
    self.editorView:draw(self.editorViewModel, self.estimatedLoad)
    local elapsedMillis = (currentTime() - startTime)*1000
    local targetMillis = 1000 / getRefreshRate()
    self.estimatedLoad = elapsedMillis / targetMillis
end
