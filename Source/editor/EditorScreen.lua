import "EditorView"
import "EditorViewModel"


class("EditorScreen").extends(Screen)

function EditorScreen:init(songPath)
    EditorScreen.super.init(self)
    
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
    if not self.editorViewModel.loaded then
        self.editorView:drawLoading(self.editorViewModel.songPath)
        coroutine.yield() -- flush screen updates
        self.editorViewModel:load()
    end
    self.editorViewModel:update()
    self.editorView:draw(self.editorViewModel)
end
