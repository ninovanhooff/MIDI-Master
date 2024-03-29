import "FileSelectorView"
import "FileSelectorViewModel"


class("FileSelectorScreen").extends(Screen)

local fileSelectorView, fileSelectorViewModel

function FileSelectorScreen:init(title, onFileSelected)
    FileSelectorScreen.super.init(self)
    
    fileSelectorViewModel = FileSelectorViewModel(title, onFileSelected)
    fileSelectorView = FileSelectorView(fileSelectorViewModel)
end

function FileSelectorScreen:pause()
    fileSelectorViewModel:pause()
end

function FileSelectorScreen:resume()
    fileSelectorView:resume()
end

function FileSelectorScreen:gameWillPause()
    fileSelectorViewModel:gameWillPause()
end

function FileSelectorScreen:deviceWillLock()
    fileSelectorViewModel:deviceWillLock()
end

function FileSelectorScreen:destroy()
    fileSelectorViewModel:destroy()
end

function FileSelectorScreen:update()
    fileSelectorViewModel:update()
    fileSelectorView:render(fileSelectorViewModel)
end

function FileSelectorScreen.createMidiPicker()
    return FileSelectorScreen(
        "Open file",
        function(selectedPath)
            clearNavigationStack()
            setSongPath(selectedPath)
            pushScreen(EditorScreen(selectedPath))
        end
    )
end
