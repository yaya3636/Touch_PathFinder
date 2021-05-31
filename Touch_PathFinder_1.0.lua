local AnkatouchDirectory = "E:\\Dofusbotting\\AnkaBotTouch"

local JSON = dofile("E:\\Dofusbotting\\Scripts\\Module\\JSON.lua")

local PF_Info = {}
PF_Info.loadedPath = {}

-- Ankabot Main func

function move()
    if map:currentMapId() == 80216576 then
        PF_Move()
        PF_LoadPath(80347649)
    elseif map:currentMapId() == 80347649 then
        PF_Move()
        PF_LoadPath(80216576)
    end

    return PF_Move()
end

function bank()

end

function phenix()

end

function stopped()

end

-- PathFinder

function PF_Move()
    if #PF_Info.loadedPath == 0 then
        Print("Aucun path chargée", "PF_Move", "warn")
        return {}
    end

    if PF_Info.dest == map:currentMapId() then
        Print("Arrivé a déstination !", "PathFinder")
        PF_Info.loadedPath = {}
        return {}
    else
        return PF_Info.loadedPath
    end
end

function PF_LoadPath(start, dest)
    if dest == nil then
        dest = start
        start = map:currentMapId()
    end

    if PF_Info.dest ~= dest then
        PF_Info.loadedPath = {}

        local path = {}
        local memoryObstacle = {}
        local startX, startY = PF_MapIdToPos(start)
        local destX, destY = PF_MapIdToPos(dest)
        local lastDir
        --Print(startX .. " " .. startY)
        --Print(destX .. " " .. destY)

        local function translateDir(dir)
            if dir == "leftNeighbourId" then
                return "left"
            elseif dir == "rightNeighbourId" then
                return "right"
            elseif dir == "topNeighbourId" then
                return "top"
            elseif dir == "bottomNeighbourId" then
                return "bottom"
            end
        end

        local function getNextDir(axe)
            if axe == "x" then
                if startX > destX then
                    return "leftNeighbourId"
                elseif startX < destX then
                    return "rightNeighbourId"
                end
            elseif axe == "y" then
                if startY > destY then
                    return "topNeighbourId"
                elseif startY < destY then
                    return "bottomNeighbourId"
                end
            end
        end

        local function prePush(mapInfo, nextDirX, nextDirY, axe)
            local nextMapX = ReadMapInfo(mapInfo[nextDirX])
            local nextMapY = ReadMapInfo(mapInfo[nextDirY])

            --Dump(mapInfo, 250)
            if axe == "x" then
                if mapInfo[nextDirX] ~= nil and nextMapX.outdoor then
                    PF_PushMap(start, translateDir(nextDirX))
                    return mapInfo[nextDirX]
                elseif mapInfo[nextDirY] ~= nil and nextMapY.outdoor then
                    PF_PushMap(start, translateDir(nextDirY))
                    return mapInfo[nextDirY]
                else
                    Print("Obstacle", "PF_LoadMove", "error")
                end
            else
                if mapInfo[nextDirY] ~= nil and nextMapY.outdoor then
                    PF_PushMap(start, translateDir(nextDirY))
                    return mapInfo[nextDirY]
                elseif mapInfo[nextDirX] ~= nil and nextMapX.outdoor then
                    PF_PushMap(start, translateDir(nextDirX))
                    return mapInfo[nextDirX]
                else
                    Print("Obstacle", "PF_LoadMove", "error")
                end 
            end

        end

        while start ~= dest do
            local mapInfo = ReadMapInfo(start)
            local nextDirX = getNextDir("x")
            local nextDirY = getNextDir("y")

            startX, startY = PF_MapIdToPos(start)

            if startX ~= destX and startY ~= destY then
                if Get_RandomNumber(0, 1) > 0 then -- x
                    start = prePush(mapInfo, nextDirX, nextDirY, "x")
                else -- y
                    start = prePush(mapInfo, nextDirX, nextDirY, "y")              
                end
            elseif startX ~= destX then
                start = prePush(mapInfo, nextDirX, nextDirY, "x")           
            elseif startY ~= destY then
                start = prePush(mapInfo, nextDirX, nextDirY, "y")               
            end
            Print(start)
        end

        Dump(PF_Info.loadedPath, 250)
    end
end

function PF_PushMap(map, dir)
    table.insert(PF_Info.loadedPath, { map = map, path = dir })
end

function PF_MapIdToPos(mapId)
    local mapInfo = ReadMapInfo(mapId)

    return mapInfo.posX, mapInfo.posY
end

-- Lecture map json

function ReadMapInfo(mapId)
    if mapId ~= nil then
        local file = io.open(AnkatouchDirectory.."\\PF_Maps\\"..mapId..".json", "r")
        local json_text = file:read("*all")
        file:close()
        return JSON.decode(json_text)
    end
    return nil
end


-- Utilitaire

function Get_RandomNumber(min, max)
    return json.parse(developer:getRequest("http://www.randomnumberapi.com/api/v1.0/random?min="..min.."&max="..max.."&count=1"))[1]
end

function Print(msg, header, msgType)
    local msg = tostring(msg)
    local prefabStr = ""

    if header ~= nil then
        prefabStr = "["..string.upper(header).."] "..msg
    else
        prefabStr = msg
    end

    if msgType == nil then
        global:printSuccess(prefabStr)
    elseif string.lower(msgType) == "warn" then
        global:printError("[WARNING]["..header.."] "..msg)
    elseif string.lower(msgType) == "error" then
        global:printError("[ERROR]["..header.."] "..msg)
        global:finishScript()
    end
end

function Dump(t, printDelay)
    local function dmp(t, l, k)
        if type (t) == "table" then
            Print(string.format("%sTable [\"%s\"] :", string.rep(" ", l * 4), tostring(k)), "Dump")
            for k, v in pairs(t) do
                dmp(v, l + 1, k)
            end
        else
            Print(string.format("%sVar : %s : %s", string.rep(" ", l * 4), tostring(k), tostring(t)), "Dump")
        end

        if printDelay ~= nil then 
            global:delay(printDelay)
        end
    end

    dmp(t, -1, "root")
    Print("Fin de la table", "Dump")
end

function OppositeDirection(dir)
    dir = dir or ""
    if string.lower(dir) == "left" then
        return "right"
    elseif string.lower(dir) == "right" then
        return "left"
    elseif string.lower(dir) == "top" then
        return "bottom"
    elseif string.lower(dir) == "bottom" then
        return "top"
    end
    return ""
end