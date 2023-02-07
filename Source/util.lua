---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by ninovanhooff.
--- DateTime: 23/07/2022 12:48
---

local lume <const> = masterplayer.lume

local file <const> = playdate.file

function endsWith(str, ending)
    return ending == "" or str:sub(-#ending) == ending
end

function selectNext(tbl, current)
    local nextIndex = (lume.find(tbl, current) or 0) + 1
    if nextIndex > #tbl then
        nextIndex = 1
    end
    return tbl[nextIndex]
end

function selectPrevious(tbl, current)
    local prevIndex = (lume.find(tbl, current) or 0) - 1
    if prevIndex < 1 then
        prevIndex = #tbl
    end
    return tbl[prevIndex]
end

function selectNextEnum(enum, current)
    if current.id < enum.idEnd then
        return enum[current.id + 1]
    else
        return enum[enum.idStart]
    end
end

function selectPreviousEnum(enum, current)
    if current.id > enum.idStart then
        return enum[current.id - 1]
    else
        return enum[enum.idEnd]
    end
end

local function listFiles(path)
    if path then
        return file.listFiles(path)
    else
        return file.listFiles()
    end
end

--- provide null for all available data dirs
function listFilesRecursive(path)
    local result = {}
    for _, item in ipairs(listFiles(path)) do
        local itemPath = (path or "") .. item
        if file.isdir(itemPath) then
            result = lume.merge(
                result,
                listFilesRecursive(itemPath)
            )
        else
            table.insert(result, itemPath)
        end
    end
    return result
end
