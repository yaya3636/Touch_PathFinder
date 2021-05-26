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

        local function getNextDir(axe)
            if axe == "x" then
                if startX > destX then
                    return "Left"
                else
                    return "Right"
                end
            elseif axe == "y" then
                if startY > destY then
                    return "Top"
                else
                    return "Bottom"
                end
            end
        end

        local function obstacleEncountered(neighbourMap)

            Print("Obstacle")

            for kDir, vMap in pairs(neighbourMap) do
                Print(kDir)
                Print(lastDir)
                if kDir ~= lastDir then
                    table.insert(memoryObstacle, { map = vMap, dir = kDir })
                    return kDir, vMap    
                end
            end

            Print("Pas de dir", "obstacleEncountered", "error")
        end

        local function findNextMove(start, dest)
            --Print("Start : "..start.." ["..startX..","..startY.."]")
            --Print("Dest : "..dest.." ["..destX..","..destY.."]")    

            if start == dest then
                Print("Fin du pathFinding", "PathFinder")
                PF_Info.loadedPath = path
                PF_Info.dest = dest
                Dump(path, 250)
                return
            end

            startX, startY = PF_MapIdToPos(start)

            local function getMove(axe, tMapInfo)
                local nextDirX = string.lower(getNextDir("x"))
                local nextDirY = string.lower(getNextDir("y"))
        
                if axe == "x" then
                    if nextDirX ~= OppositeDirection(lastDir) and tMapInfo.neighbourMap[nextDirX] ~= nil then
                        table.insert(path, { map = tostring(start), path = tostring(nextDirX) })
                        lastDir = nil
                        findNextMove(tMapInfo.neighbourMap[nextDirX], dest)
                    else
                        Print("neighbourMapX nil")
                        if tMapInfo.neighbourMap[nextDirY] ~= nil then
                            table.insert(path, { map = tostring(start), path = tostring(nextDirY) })
                            lastDir = nil
                            findNextMove(tMapInfo.neighbourMap[nextDirY], dest)    
                        else
                            Print("Obstacle sur le chemin le plus rapide X")
                            local nextDir, nextMap = obstacleEncountered(tMapInfo.neighbourMap)
                            table.insert(path, { map = tostring(start), path = tostring(nextDir) })
                            lastDir = nextDir
                            findNextMove(nextMap, dest)
                        end
                    end
                elseif axe == "y" then
                    if nextDirY ~= OppositeDirection(lastDir) and tMapInfo.neighbourMap[nextDirY] ~= nil then
                        table.insert(path, { map = tostring(start), path = tostring(nextDirY) })
                        lastDir = nil
                        findNextMove(tMapInfo.neighbourMap[nextDirY], dest)
                    else
                        Print("neighbourMapY nil")
                        if tMapInfo.neighbourMap[nextDirX] ~= nil then
                            table.insert(path, { map = tostring(start), path = tostring(nextDirX) })
                            lastDir = nil
                            findNextMove(tMapInfo.neighbourMap[nextDirX], dest)
                        else
                            Print("Obstacle sur le chemin le plus rapide Y")
                            local nextDir, nextMap = obstacleEncountered(tMapInfo.neighbourMap)
                            table.insert(path, { map = tostring(start), path = tostring(nextDir) })
                            lastDir = nextDir
                            findNextMove(nextMap, dest)
                        end
                    end
                end
            end
        
            for _, tArea in pairs(MAP_INFO) do
                for _, tSubArea in pairs(tArea) do
                    for kMapId, tMapInfo in pairs(tSubArea) do
                        if kMapId == tostring(start) then
                            if startX ~= destX and startY ~= destY then
                                local rnd = Get_RandomNumber(0,1)
                                if rnd > 0 then
                                    getMove("x", tMapInfo)
                                else
                                    getMove("y", tMapInfo)
                                end
                            elseif startX ~= destX then
                                getMove("x", tMapInfo)
                            elseif startY ~= destY then
                                getMove("y", tMapInfo)
                            end

                        end
                    end
                end
            end
        end

        findNextMove(start, dest)
    end
end

function PF_MapIdToPos(mapId)
    for _, tArea in pairs(MAP_INFO) do
        for _, tSubArea in pairs(tArea) do
            for kMapId, tMapInfo in pairs(tSubArea) do
                if kMapId == tostring(mapId) then
                    return tMapInfo.x, tMapInfo.y
                end
            end
        end
    end

    Print("Impossible de retourner une pos", "PF_MapIdToPos", "error")
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

MAP_INFO = {
    ["Incarnam"] = {
        ["Prairie"] = {
            ["80216064"] = {
                mapId = 80216064,
                pos = "0,-1",
                x = 0,
                y = -1,
                neighbourMap = {
                    ["left"] = nil,
                    ["right"] = 80216576,
                    ["top"] = nil,
                    ["bottom"] = 80216065
                }
            },
            ["80216576"] = {
                mapId = 80216576,
                pos = "1,-1",
                x = 1,
                y = -1,
                neighbourMap = {
                    ["left"] = 80216064,
                    ["right"] = 80217088,
                    ["top"] = nil,
                    ["bottom"] = 80216577
                }
            },
            ["80217088"] = {
                mapId = 80217088,
                pos = "2,-1",
                x = 2,
                y = -1,
                neighbourMap = {
                    ["left"] = 80216576,
                    ["right"] = nil,
                    ["top"] = nil,
                    ["bottom"] = 80217089
                }
            },
            ["80347649"] = {
                mapId = 80347649,
                pos = "-1,0",
                x = -1,
                y = 0,
                neighbourMap = {
                    ["left"] = nil,
                    ["right"] = nil,
                    ["top"] = nil,
                    ["bottom"] = 80347650
                }
            },
            ["80216065"] = {
                mapId = 80216065,
                pos = "0,0",
                x = 0,
                y = 0,
                neighbourMap = {
                    ["left"] = nil,
                    ["right"] = 80216577,
                    ["top"] = 80216064,
                    ["bottom"] = 80216066
                }
            },
            ["80216577"] = {
                mapId = 80216577,
                pos = "1,0",
                x = 1,
                y = 0,
                neighbourMap = {
                    ["left"] = 80216065,
                    ["right"] = 80217089,
                    ["top"] = 80216576,
                    ["bottom"] = 80216578
                }
            },
            ["80217089"] = {
                mapId = 80217089,
                pos = "2,0",
                x = 2,
                y = 0,
                neighbourMap = {
                    ["left"] = 80216577,
                    ["right"] = nil,
                    ["top"] = 80217088,
                    ["bottom"] = 80217090
                }
            },
            ["80347650"] = {
                mapId = 80347650,
                pos = "-1,1",
                x = -1,
                y = 1,
                neighbourMap = {
                    ["left"] = nil,
                    ["right"] = 80216066,
                    ["top"] = 80347649,
                    ["bottom"] = 80347651
                }
            },
            ["80216066"] = {
                mapId = 80216066,
                pos = "0,1",
                x = 0,
                y = 1,
                neighbourMap = {
                    ["left"] = 80347650,
                    ["right"] = 80216578,
                    ["top"] = 80216065,
                    ["bottom"] = 80216067
                }
            },
            ["80216578"] = {
                mapId = 80216578,
                pos = "1,1",
                x = 1,
                y = 1,
                neighbourMap = {
                    ["left"] = 80216066,
                    ["right"] = 80217090,
                    ["top"] = 80216577,
                    ["bottom"] = 80216579
                }
            },
            ["80217090"] = {
                mapId = 80217090,
                pos = "2,1",
                x = 2,
                y = 1,
                neighbourMap = {
                    ["left"] = 80216578,
                    ["right"] = 80217602,
                    ["top"] = 80217089,
                    ["bottom"] = 80217091
                }
            },
            ["80217602"] = {
                mapId = 80217602,
                pos = "3,1",
                x = 3,
                y = 1,
                neighbourMap = {
                    ["left"] = 80217090,
                    ["right"] = 80218114,
                    ["top"] = nil,
                    ["bottom"] = 80217603
                }
            },
            ["80347651"] = {
                mapId = 80347651,
                pos = "-1,2",
                x = -1,
                y = 2,
                neighbourMap = {
                    ["left"] = nil,
                    ["right"] = 80216067,
                    ["top"] = 80347650,
                    ["bottom"] = nil
                }
            },
            ["80216067"] = {
                mapId = 80216067,
                pos = "0,2",
                x = 0,
                y = 2,
                neighbourMap = {
                    ["left"] = 80347651,
                    ["right"] = 80216579,
                    ["top"] = 80216066,
                    ["bottom"] = 80216068
                }
            },
            ["80216579"] = {
                mapId = 80216579,
                pos = "1,2",
                x = 1,
                y = 2,
                neighbourMap = {
                    ["left"] = 80216067,
                    ["right"] = 80217091,
                    ["top"] = 80216578,
                    ["bottom"] = 80216580
                }
            },
            ["80217091"] = {
                mapId = 80217091,
                pos = "2,2",
                x = 2,
                y = 2,
                neighbourMap = {
                    ["left"] = 80216579,
                    ["right"] = 80217603,
                    ["top"] = 80217090,
                    ["bottom"] = 80217092
                }
            },
            ["80217603"] = {
                mapId = 80217603,
                pos = "3,2",
                x = 3,
                y = 2,
                neighbourMap = {
                    ["left"] = 80217091,
                    ["right"] = 80218115,
                    ["top"] = 80217602,
                    ["bottom"] = 80217604
                }
            }
        }
    }
}