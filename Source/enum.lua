---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by ninovanhooff.
--- DateTime: 26/07/2022 22:03
--- Source: https://github.com/sulai/Lib-Pico8/blob/master/lang.lua

function enum(names, offset)
    offset=offset or 1
    local objects = {}
    local size=0
    for idr,name in pairs(names) do
        local id = idr + offset - 1
        local obj = {
            id=id,       -- id
            idr=idr,     -- 1-based relative id, without offset being added
            name=name    -- name of the object
        }
        objects[name] = obj
        objects[id] = obj
        size=size+1
    end
    objects.idStart = offset        -- start of the id range being used
    objects.idEnd = offset+size-1   -- end of the id range being used
    objects.size=size
    objects.all = function()
        local list = {}
        for _,name in pairs(names) do
            add(list,objects[name])
        end
        local i=0
        return function() i=i+1 if i<=#list then return list[i] end end
    end
    return objects
end

return enum
