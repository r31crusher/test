-- Doors (PlaceId 6516141723 / 6839171747)

return function(section)
    local elements = getgenv()._astroElements
    local Players        = game:GetService("Players")
    local RS             = game:GetService("ReplicatedStorage")
    local RunSvc         = game:GetService("RunService")
    local TweenSvc       = game:GetService("TweenService")
    local SoundSvc       = game:GetService("SoundService")
    local Lighting       = game:GetService("Lighting")
    local PathSvc        = game:GetService("PathfindingService")
    local VirtualUser    = game:GetService("VirtualUser")
    local HttpService    = game:GetService("HttpService")
    local LocalPlayer    = Players.LocalPlayer

    -- ── Exploit globals (graceful fallback) ───────────────────────────────────
    local env = getgenv()
    local function checkfn(name) return type(env[name]) == "function" end
    local function ForceFirePrompt(p)
        if checkfn("fireproximityprompt") then fireproximityprompt(p)
        else p:TriggerPrompt(LocalPlayer) end
    end
    local function FireTouchInterest(a, b, c)
        if checkfn("firetouchinterest") then firetouchinterest(a, b, c) end
    end
    local function IsNetworkOwner(p)
        if checkfn("isnetworkowner") then return isnetworkowner(p) end
        return false
    end

    -- ── ReplicatedStorage paths (exact from reference) ────────────────────────
    local RemotesFolder = RS:FindFirstChild("RemotesFolder")
    local LiveModifiers = RS:FindFirstChild("LiveModifiers") or Instance.new("Folder")
    local FloorReplicated = RS:FindFirstChild("FloorReplicated") or Instance.new("Folder")
    local CurrentRooms  = workspace:FindFirstChild("CurrentRooms")
    local GameData      = RS:WaitForChild("GameData")
    local Floor         = GameData:WaitForChild("Floor").Value
    local LatestRoom    = GameData:WaitForChild("LatestRoom")

    if not RemotesFolder then
        if RS:FindFirstChild("EntityInfo") then
            RemotesFolder = RS:FindFirstChild("EntityInfo")
        elseif RS:FindFirstChild("Bricks") then
            RemotesFolder = RS:FindFirstChild("Bricks")
        end
    end
    if not RemotesFolder then RemotesFolder = RS end

    if Floor == "Hotel" and RemotesFolder.Name == "Bricks" then
        Floor = "OldHotel"
    end

    local ClientModules
    if RS:FindFirstChild("ModulesClient") then
        ClientModules = RS.ModulesClient
    else
        ClientModules = RS:FindFirstChild("ClientModules")
    end

    -- ── Entity table (exact from reference) ───────────────────────────────────
    local Entities = {
        ["RushMoving"]      = { Alias = "Rush" },
        ["AmbushMoving"]    = { Alias = "Ambush" },
        ["Eyes"]            = { Alias = "Eyes" },
        ["Lookman"]         = { Alias = "Eyes" },
        ["BackdoorRush"]    = { Alias = "Blitz" },
        ["BackdoorLookman"] = { Alias = "Lookman" },
        ["Groundskeeper"]   = { Alias = "Groundskeeper" },
        ["A60"]             = { Alias = "A-60" },
        ["A120"]            = { Alias = "A-120" },
        ["GloombatSwarm"]   = { Alias = "Gloombat Swarm" },
        ["GlitchRush"]      = { Alias = "RNIUSHCG==" },
        ["GlitchAmbush"]    = { Alias = "AR0xMBUSH" },
        ["MonumentEntity"]  = { Alias = "Monument" },
        ["JeffTheKiller"]   = { Alias = "Jeff the Killer" },
        ["CustomEntity"]    = { Alias = "Custom Entity" },
        ["FrozenAmbush"]    = { Alias = "Frozen Ambush" },
        ["SallyMoving"]     = { Alias = "Sally" },
    }

    local EntityDistances = {
        ["RushMoving"] = 85, ["AmbushMoving"] = 150, ["A60"] = 125,
        ["A120"] = 85, ["GlitchRush"] = 90, ["GlitchAmbush"] = 175,
        ["BackdoorRush"] = 85, ["CustomEntity"] = 85,
    }

    local ItemNames = {
        ["Lighter"]="Lighter",["Flashlight"]="Flashlight",["Lockpick"]="Lockpicks",
        ["Vitamins"]="Vitamins",["Bandage"]="Bandage",["StarVial"]="Starlight Vial",
        ["StarBottle"]="Starlight Bottle",["StarJug"]="Starlight Barrel",
        ["Shakelight"]="Gummy Flashlight",["Straplight"]="Straplight",
        ["Bulklight"]="Spotlight",["Battery"]="Battery",["Candle"]="Candle",
        ["Crucifix"]="Crucifix",["CrucifixWall"]="Crucifix",["Glowsticks"]="Glowstick",
        ["SkeletonKey"]="Skeleton Key",["Candy"]="Candy",["ShieldMini"]="Mini Shield Potion",
        ["ShieldBig"]="Big Shield Potion",["BandagePack"]="Bandage Pack",
        ["BatteryPack"]="Battery Pack",["RiftCandle"]="Moonlight Candle",
        ["LaserPointer"]="Laser Pointer",["HolyGrenade"]="Holy Hand Grenade",
        ["Shears"]="Shears",["Smoothie"]="Smoothie",["Cheese"]="Cheese",
        ["Bread"]="Bread",["AlarmClock"]="Alarm Clock",["RiftSmoothie"]="Moonlight Smoothie",
        ["GweenSoda"]="Gween Soda",["GlitchCube"]="Glitch Fragment",["Scanner"]="Tablet",
        ["Bomb"]="Bomb",["Knockbomb"]="Knockbomb",["Nanner"]="Nanner",
        ["BigBomb"]="Big Bomb",["SnakeBox"]="Hiding Box",["GoldGun"]="Golden Gun",
        ["StopSign"]="Stop Sign",["TipJar"]="Tip Jar",["Lantern"]="Lantern",
        ["IronKey"]="Iron Key",["LotusPetal"]="Lotus Petal",["Compass"]="Compass",
        ["LotusPetalPickup"]="Lotus Petal",["LanternLitItem"]="Lantern",
        ["KeyIron"]="Iron Key",["IronKeyForCrypt"]="Iron Key",["LotusHolder"]="Lotus Petal",
        ["Multitool"]="Multitool",["RiftJar"]="Rift Jar",["AloeVera"]="Aloe Vera",
        ["Donut"]="Donut",["Lotus"]="Lotus",["BoxingGloves"]="Boxing Gloves",
    }

    -- ── Object/state tables ───────────────────────────────────────────────────
    local Objects = {
        Prompts={}, Objectives={}, Doors={}, HidingSpots={}, Entities={},
        SeekObstructions={}, Items={}, Chests={}, Currency={}, Ladders={},
        Obstructions={}, JumpscareModules={}, SeekHighlights={},
        EyestalkHighlights={}, SeekNodes={}, SeekDuckBoards={}, SeekBridges={},
        EventTriggers={},
    }
    local Globals = { AnticheatDisabled = false, SelfKilled = false }
    local Connections = {}
    local FakePrompts = {}
    local Modules = {}
    local FakeEvents = {
        Screech = Instance.new("RemoteEvent"),
        Shade   = Instance.new("RemoteEvent"),
        A90     = Instance.new("RemoteEvent"),
        Surge   = Instance.new("RemoteEvent"),
    }
    FakeEvents.Screech.Name  = "Screech"
    FakeEvents.Shade.Name    = "ShadeResult"
    FakeEvents.A90.Name      = "A90"
    FakeEvents.Surge.Name    = "SurgeRemote"

    FakeEvents.Screech_Real  = RemotesFolder:WaitForChild("Screech")
    FakeEvents.Shade_Real    = RemotesFolder:WaitForChild("ShadeResult")
    FakeEvents.A90_Real      = RemotesFolder:FindFirstChild("A90")
    FakeEvents.Surge_Real    = RemotesFolder:FindFirstChild("SurgeRemote")

    -- ── Toggle state vars ─────────────────────────────────────────────────────
    local _speed=false; local _speedAmt=0
    local _fly=false;   local _flySpeed=20
    local _noclip=false
    local _posSpoof=false
    local _crouchSpoof=false
    local _doorReach=false
    local _autoCloset=false
    local _autoClosetIgnore={}
    local _autoInteract=false
    local _autoBreaker=false
    local _infiniteJumps=false
    local _jumpEnable=false
    local _slideEnable=false
    local _promptReach=1
    local _instantPrompt=false
    local _promptClip=false
    local _removeScreech=false
    local _removeHalt=false
    local _removeA90=false
    local _removeDread=false
    local _noScreechDmg=false
    local _noHaltDmg=false
    local _noA90Dmg=false
    local _noSurgeDmg=false
    local _bypassGiggle=false
    local _bypassDupe=false
    local _bypassEyes=false
    local _bypassLookman=false
    local _bypassGloombat=false
    local _bypassSeekObstruct=false
    local _bypassVacuum=false
    local _bypassKillbrick=false
    local _bypassSeekWall=false
    local _bypassSnare=false
    local _bypassBanana=false
    local _bypassJeff=false
    local _disableAnticheat=false
    local _velocityManip=false
    local _infiniteItems=false
    local _disableGlitchJS=false
    local _disableTimothyJS=false
    local _disableVoidJS=false
    local _disableHideVignette=false
    local _disableEntityJS=false
    local _disableFiredamp=false
    local _removeFog=false
    local _espEntity=false
    local _espDoor=false
    local _espHide=false
    local _espItem=false
    local _espChest=false
    local _espObjective=false
    local _espCurrency=false
    local _espPlayer=false
    local _espLadder=false
    local _removeClosetDelay=false
    local _removeAccel=false

    -- ── Character locals ──────────────────────────────────────────────────────
    local Character, Humanoid, RootPart, Camera
    local Collision, CollisionClone, CollisionPart, CollisionPartClone
    local Main_Game
    local OldJump, OldSlide = false, false
    local OriginalC1
    local CustomPhysics
    local PartProperties = {}
    local ManipulateBody = Instance.new("BodyVelocity")
    ManipulateBody.MaxForce = Vector3.new(9e9,9e9,9e9)
    local FlyBody = Instance.new("BodyVelocity")
    FlyBody.MaxForce = Vector3.new(9e9,9e9,9e9)

    -- ── Fog tracking ──────────────────────────────────────────────────────────
    Globals.OldFog = Lighting.FogEnd
    Globals.FogInstances = {}
    for _, obj in Lighting:GetChildren() do
        if obj:IsA("Atmosphere") then
            obj:SetAttribute("Density_Old", obj.Density)
            table.insert(Globals.FogInstances, obj)
        end
    end

    -- ── ESP (BillboardGui-based) ───────────────────────────────────────────────
    local espBills = {}
    local function makeLabel(obj, text, color)
        if espBills[obj] then return end
        local part = (obj.ClassName == "Model" and obj.PrimaryPart) or
                     (obj:IsA("BasePart") and obj) or
                     obj:FindFirstChildWhichIsA("BasePart")
        if not part then return end
        local bb = Instance.new("BillboardGui")
        bb.Name = "_doorsESP"
        bb.Size = UDim2.new(0,120,0,32)
        bb.StudsOffset = Vector3.new(0,4,0)
        bb.AlwaysOnTop = true
        bb.Adornee = part
        bb.Parent = game.CoreGui
        local lbl = Instance.new("TextLabel",bb)
        lbl.Size = UDim2.new(1,0,1,0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 13
        lbl.TextColor3 = color or Color3.fromRGB(255,255,255)
        lbl.TextStrokeTransparency = 0
        lbl.Text = text
        espBills[obj] = { bb=bb, lbl=lbl, part=part }
    end
    local function removeLabel(obj)
        if espBills[obj] then espBills[obj].bb:Destroy(); espBills[obj]=nil end
    end

    local espRenderConn
    local function startESPLoop()
        if espRenderConn then return end
        espRenderConn = RunSvc.RenderStepped:Connect(function()
            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            for obj, data in pairs(espBills) do
                if not obj.Parent then
                    data.bb:Destroy(); espBills[obj]=nil
                elseif data.part and data.part.Parent then
                    local d = myHRP and math.floor((data.part.Position - myHRP.Position).Magnitude) or 0
                    if not string.find(data.lbl.Text, "%[") then
                        -- static label, no dist suffix needed unless we want it
                    else
                        local base = data.lbl.Text:gsub("%s*%[%d+m%]","")
                        data.lbl.Text = base .. " [" .. d .. "m]"
                    end
                end
            end
        end)
    end
    startESPLoop()

    -- ── Helper: GetNearestEntity (exact from reference) ───────────────────────
    local function GetNearestEntity(CheckDisabled, List)
        local Nearest = { Distance=math.huge, Object=nil }
        for _, entity in workspace:GetChildren() do
            if entity and EntityDistances[entity.Name] and entity.PrimaryPart then
                local ed = Entities[entity.Name]
                if (not List or not List[ed.Alias]) then
                    local dist = LocalPlayer:DistanceFromCharacter(entity.PrimaryPart.Position)
                    if dist < EntityDistances[entity.Name] and dist < Nearest.Distance then
                        if (not CheckDisabled) or entity:GetAttribute("Inactive") ~= true then
                            Nearest.Distance = dist
                            Nearest.Object   = entity
                        end
                    end
                end
            end
        end
        return Nearest.Object
    end

    -- ── Helper: GetNearestHidingSpot (exact from reference) ──────────────────
    local function GetNearestHidingSpot()
        local Nearest = { Distance=math.huge, Object=nil }
        for _, obj in Objects.HidingSpots do
            if obj.PrimaryPart and obj:FindFirstChild("HidePrompt") then
                local dist = LocalPlayer:DistanceFromCharacter(obj.PrimaryPart.Position)
                if dist < obj.HidePrompt.MaxActivationDistance and dist < Nearest.Distance then
                    local char = Character
                    if char:FindFirstChild("LastHideSpot") and char.LastHideSpot.Value ~= obj and
                       (Floor=="Mines" or Floor=="Ripple" or Floor=="Party") or
                       not char:FindFirstChild("LastHideSpot") then
                        Nearest.Distance = dist
                        Nearest.Object   = obj
                    end
                end
            end
        end
        return Nearest.Object
    end

    -- ── Helper: IsCrouching ───────────────────────────────────────────────────
    local function IsCrouching()
        if Floor == "Fools" or Floor == "OldHotel" then
            return Character and Character:GetAttribute("Crouching") or false
        else
            return CollisionPart and CollisionPart.CollisionGroup == "PlayerCrouching" or false
        end
    end

    -- ── Helper: GetCurrentSpeed ───────────────────────────────────────────────
    local function GetCurrentSpeed()
        local s = 15
        if Character then
            s = s + (Character:GetAttribute("SpeedBoost") or 0)
            s = s + (Character:GetAttribute("SpeedBoostBehind") or 0)
            s = s + (Character:GetAttribute("SpeedBoostExtra") or 0)
            s = s + (Floor == "Party" and 10 or 0)
        end
        s = s + (LiveModifiers:FindFirstChild("PlayerFast") and 3 or 0)
        s = s + (LiveModifiers:FindFirstChild("PlayerFaster") and 6 or 0)
        s = s + (LiveModifiers:FindFirstChild("PlayerFastest") and 20 or 0)
        s = s - (LiveModifiers:FindFirstChild("PlayerSlow") and 3 or 0)
        return s
    end

    -- ── Helper: GetFlyVelocity ────────────────────────────────────────────────
    local function GetFlyVelocity()
        if Humanoid.MoveDirection == Vector3.zero then return Vector3.zero end
        local v = (Camera.CFrame * CFrame.new(
            (CFrame.new(Camera.CFrame.p, Camera.CFrame.p + Vector3.new(
                Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z
            )):VectorToObjectSpace(Humanoid.MoveDirection))
        )).Position - Camera.CFrame.Position
        return v == Vector3.zero and v or v.Unit
    end

    -- ── HidingSpot transparency helper (exact from reference) ─────────────────
    local function HandleHidingTransparency(model)
        local parts = {}
        for _, p in model:GetDescendants() do
            if p:IsA("BasePart") then
                p:SetAttribute("Transparency_Old", p.Transparency)
                table.insert(parts, p)
            end
            if p.Name == "HiddenPlayer" then
                local conn = p:GetPropertyChangedSignal("Value"):Connect(function()
                    for _, p2 in parts do
                        TweenSvc:Create(p2, TweenInfo.new(0.25,Enum.EasingStyle.Linear), {
                            Transparency = (p.Value == Character and 0.5 or p2:GetAttribute("Transparency_Old"))
                        }):Play()
                    end
                end)
                table.insert(Connections, conn)
                model.Destroying:Once(function()
                    conn:Disconnect()
                    local pos = table.find(Connections, conn)
                    if pos then table.remove(Connections, pos) end
                end)
            end
        end
    end

    -- ── ESP label helpers per category ────────────────────────────────────────
    local C = {
        entity    = Color3.fromRGB(255,0,0),
        door      = Color3.fromRGB(0,200,255),
        hiding    = Color3.fromRGB(255,170,0),
        item      = Color3.fromRGB(170,0,255),
        chest     = Color3.fromRGB(255,255,0),
        currency  = Color3.fromRGB(255,220,0),
        objective = Color3.fromRGB(0,255,0),
        ladder    = Color3.fromRGB(255,255,255),
        player    = Color3.fromRGB(255,255,255),
    }
    local espFlags = {}  -- [obj] = category string

    local function addESP(obj, text, category)
        makeLabel(obj, text .. " [0m]", C[category] or C.entity)
        espFlags[obj] = category
    end
    local function remESP(obj)
        removeLabel(obj)
        espFlags[obj] = nil
    end

    -- ── Object handler (ported from reference HandleObject) ───────────────────
    local AllowedInstances = {
        Lava=true,GoldPile=true,KeyObtain=true,KeyObtainFake=true,FuseObtain=true,
        MinesGenerator=true,JeffTheKiller=true,Snare=true,FakeDoor=true,DoorFake=true,
        SideroomSpace=true,ChestBox=true,ChestBoxLocked=true,Chest_Vine=true,
        Locker_Small_Locked=true,Toolbox=true,Toolbox_Locked=true,Wardrobe=true,
        ["Wardrobe-FOOLS26"]=true,Toolshed=true,Toolshed_Small=true,Bed=true,
        MinesAnchor=true,Double_Bed=true,RetroWardrobe=true,Backdoor_Wardrobe=true,
        Rooms_Locker=true,Rooms_Locker_Fridge=true,Locker_Large=true,FigureRig=true,
        FigureRagdoll=true,TimerLever=true,Ladder=true,CircularVent=true,Dumpster=true,
        TriggerEventCollision=true,GrumbleRig=true,GiggleCeiling=true,
        ElectricalKeyObtain=true,LibraryHintPaper=true,WaterPump=true,
        LeverForGate=true,GloomPile=true,SeekFloodline=true,Door=true,
        Green_Herb=true,MouseHole=true,BananaPeel=true,ThingToOpen=true,
        MovingDoor=true,StardustPickup=true,Hole=true,Groundskeeper=true,
        GardenGateButton=true,LotusPetalPickup=true,VineGuillotine=true,
        LiveEntityBramble=true,ElevatorBreaker=true,DuckBoard=true,Padlock=true,
        LiveHintBook=true,LiveBreakerPolePickup=true,MinesGateButton=true,
        ScaryWall=true,Seek_Arm=true,ChandelierObstruction=true,
        EyestalkEndCutscene=true,Drakobloxxer=true,PickupItem=true,
    }

    local function HandleObject(object)
        if not AllowedInstances[object.Name] and object.ClassName ~= "ProximityPrompt"
           and object.Parent ~= CurrentRooms and not ItemNames[object.Name] then
            return
        end

        if object.Name ~= "TriggerEventCollision" then
            task.wait(math.random(20,40)/100)
        end

        -- tag with parent room
        for _, room in CurrentRooms:GetChildren() do
            if object:IsDescendantOf(room) then
                object:SetAttribute("ParentRoom", tonumber(room.Name))
                break
            end
        end

        if object.ClassName == "ProximityPrompt" then
            object:SetAttribute("MaxActivationDistance_Old", object.MaxActivationDistance)
            object:SetAttribute("HoldDuration_Old", object.HoldDuration)
            object:SetAttribute("RequiresLineOfSight_Old", object.RequiresLineOfSight)
            object.MaxActivationDistance = object.MaxActivationDistance * _promptReach
            if _instantPrompt then object.HoldDuration = 0 end
            if _promptClip then object.RequiresLineOfSight = false end
            table.insert(Objects.Prompts, object)
            return
        end

        if object.Name == "KeyObtain" then
            task.wait(0.5)
            if object.Parent then
                if _espObjective then addESP(object,"Door Key","objective") end
                table.insert(Objects.Objectives, object)
            end
        elseif object.Name == "ElectricalKeyObtain" then
            task.wait(0.5)
            if object.Parent then
                if _espObjective then addESP(object,"Electrical Key","objective") end
                table.insert(Objects.Objectives, object)
            end
        elseif object.Name == "KeyObtainFake" then
            task.wait(0.5)
            if object.Parent then
                if _espEntity then addESP(object,"Fake Key","entity") end
                table.insert(Objects.Entities, object)
            end
        elseif object.Name == "TimerLever" then
            task.wait(0.5)
            if object.Parent then
                local addTime = (object.TakeTimer.TextLabel.Text == "01:00" and 60 or 30)
                object:SetAttribute("AddTime", addTime)
                if _espObjective then addESP(object,"Time Lever [+"..addTime.."s]","objective") end
                table.insert(Objects.Objectives, object)
            end
        elseif object.Name == "LiveHintBook" then
            if _espObjective then addESP(object,"Hint Book","objective") end
            table.insert(Objects.Objectives, object)
        elseif object.Name == "LiveBreakerPolePickup" then
            if _espObjective then addESP(object,"Fuse Breaker","objective") end
            table.insert(Objects.Objectives, object)
        elseif object.Name == "LibraryHintPaper" or object.Name == "PickupItem" then
            if _espObjective then addESP(object,"Hint Paper","objective") end
            table.insert(Objects.Objectives, object)
        elseif object.Name == "MinesAnchor" then
            if _espObjective then addESP(object,"Anchor","objective") end
            table.insert(Objects.Objectives, object)
        elseif object.Name == "WaterPump" then
            if _espObjective and object:FindFirstChild("Wheel") then
                addESP(object.Wheel,"Water Pump","objective")
            end
            table.insert(Objects.Objectives, object)
        elseif object.Name == "LeverForGate" then
            if _espObjective then addESP(object,"Gate Lever","objective") end
            table.insert(Objects.Objectives, object)
        elseif object.Name == "VineGuillotine" then
            if _espObjective and object:FindFirstChild("Lever") then
                addESP(object.Lever,"Vine Lever","objective")
            end
            table.insert(Objects.Objectives, object)
        elseif object.Name == "MinesGenerator" then
            task.wait(0.75)
            if object.Parent then
                if _espObjective then addESP(object,"Generator","objective") end
                table.insert(Objects.Objectives, object)
            end
        elseif object.Name == "FuseObtain" then
            if _espObjective then addESP(object,"Generator Fuse","objective") end
            table.insert(Objects.Objectives, object)
        elseif object.Name == "MinesGateButton" or object.Name == "GardenGateButton" then
            if _espObjective then addESP(object,"Gate Button","objective") end
            table.insert(Objects.Objectives, object)
        elseif object.Name == "Ladder" then
            if _espLadder then addESP(object,"Ladder","ladder") end
            table.insert(Objects.Ladders, object)
        elseif object.Name == "Door" and object.Parent and tonumber(object.Parent.Name) then
            -- door reach + door ESP (exact from reference)
            local doorParts = {}
            for _, ch in object:GetChildren() do
                if ch.Name == "Door" and ch:IsA("BasePart") then
                    table.insert(doorParts, ch)
                end
            end

            local espTarget
            if #doorParts == 2 then
                local m = Instance.new("Model", object)
                m.Name = "HighlightModel"
                Instance.new("Humanoid", m).Name = "HighlightHumanoid"
                m:SetAttribute("ParentRoom", tonumber(object.Parent.Name))
                for _, dp in doorParts do
                    local hp = Instance.new("Part", m)
                    hp.Transparency = 0.99; hp.Size = dp.Size
                    hp.CanCollide = false; hp.CFrame = dp.CFrame
                    hp.Name = "HighlightPart"
                    hp:SetAttribute("ParentRoom", tonumber(object.Parent.Name))
                    local wc = Instance.new("WeldConstraint", hp)
                    wc.Part0 = hp; wc.Part1 = dp; wc.Enabled = true
                    hp.Parent = m
                end
                espTarget = m
                table.insert(Objects.Doors, m)
            else
                local root = object:WaitForChild("Door", 9e9)
                local hp = Instance.new("Part", object)
                hp.Transparency = 0.99; hp.Size = root.Size
                hp.CanCollide = false; hp.CFrame = root.CFrame
                hp.Name = "HighlightPart"
                hp:SetAttribute("ParentRoom", tonumber(object.Parent.Name))
                local wc = Instance.new("WeldConstraint", hp)
                wc.Part0 = hp; wc.Part1 = root; wc.Enabled = true
                Instance.new("Humanoid", object).Name = "HighlightHumanoid"
                espTarget = hp
                table.insert(Objects.Doors, hp)
            end

            if _espDoor and espTarget then addESP(espTarget,"Door","door") end

            -- door reach loop
            local lastFire = tick()
            local conn = RunSvc.Heartbeat:Connect(function()
                if object:FindFirstChild("Door") and object:FindFirstChild("ClientOpen") then
                    local dist = LocalPlayer:DistanceFromCharacter(object.Door.Position)
                    if dist < 150 and tick()-lastFire > 0.05 and _doorReach then
                        object.ClientOpen:FireServer()
                        lastFire = tick()
                    end
                end
            end)
            pcall(function()
                object:WaitForChild("Door").Open.Played:Once(function() conn:Disconnect() end)
            end)
            table.insert(Connections, conn)

        elseif object.Name == "DuckBoard" then
            table.insert(Objects.SeekDuckBoards, object)
        elseif object.Name == "Wardrobe" or object.Name == "Backdoor_Wardrobe" or
               object.Name == "Toolshed" or object.Name == "RetroWardrobe" or
               object.Name == "Wardrobe-FOOLS26" then
            if _espHide then addESP(object,"Closet","hiding") end
            HandleHidingTransparency(object)
            table.insert(Objects.HidingSpots, object)
        elseif object.Name == "Locker_Large" or object.Name == "Rooms_Locker" or
               object.Name == "Rooms_Locker_Fridge" then
            if _espHide then addESP(object,"Locker","hiding") end
            HandleHidingTransparency(object)
            table.insert(Objects.HidingSpots, object)
        elseif object.Name == "Bed" then
            if _espHide then addESP(object,"Bed","hiding") end
            HandleHidingTransparency(object)
            table.insert(Objects.HidingSpots, object)
        elseif object.Name == "Double_Bed" then
            if _espHide then addESP(object,"Double Bed","hiding") end
            HandleHidingTransparency(object)
            table.insert(Objects.HidingSpots, object)
        elseif object.Name == "CircularVent" then
            if _espHide then addESP(object,"Vent","hiding") end
            HandleHidingTransparency(object)
            table.insert(Objects.HidingSpots, object)
        elseif object.Name == "Dumpster" then
            if _espHide then addESP(object,"Dumpster","hiding") end
            HandleHidingTransparency(object)
            table.insert(Objects.HidingSpots, object)
        elseif object.Name == "Lava" then
            if _bypassKillbrick then object.CanTouch = false end
            table.insert(Objects.Obstructions, object)
        elseif object.Name == "ScaryWall" then
            for _, p in object:GetDescendants() do
                if p:IsA("BasePart") then
                    p.CanTouch = not _bypassSeekWall
                    p.CanCollide = not _bypassSeekWall
                end
            end
            table.insert(Objects.Obstructions, object)
        elseif object.Name == "ThingToOpen" and (Floor=="Fools" or Floor=="OldHotel") then
            object:SetAttribute("OriginalPosition", object:GetPivot())
            if _bypassSeekWall then object:PivotTo(CFrame.new(-10000,-10000,-10000)) end
            table.insert(Objects.Obstructions, object)
        elseif object.Name == "MovingDoor" and (Floor=="Fools" or Floor=="OldHotel") then
            object:SetAttribute("OriginalPosition", object:GetPivot())
            table.insert(Objects.Obstructions, object)
        elseif object.Name == "ChestBox" or object.Name == "ChestBoxLocked" then
            if _espChest then
                addESP(object, object:GetAttribute("Locked") and "Locked Chest" or "Chest", "chest")
            end
            table.insert(Objects.Chests, object)
        elseif object.Name == "Toolbox" or object.Name == "Toolbox_Locked" then
            if _espChest then
                addESP(object, object:GetAttribute("Locked") and "Locked Toolbox" or "Toolbox", "chest")
            end
            table.insert(Objects.Chests, object)
        elseif object.Name == "Chest_Vine" then
            if _espChest then addESP(object,"Vine Chest","chest") end
            table.insert(Objects.Chests, object)
        elseif object.Name == "Toolshed_Small" then
            if _espChest then addESP(object,"Toolshed","chest") end
            table.insert(Objects.Chests, object)
        elseif object.Name == "Locker_Small_Locked" then
            if _espChest then addESP(object,"Locked Item Locker","chest") end
            table.insert(Objects.Chests, object)
        elseif object.Name == "MouseHole" then
            if _espChest then addESP(object,"Mouse","chest") end
            table.insert(Objects.Chests, object)
        elseif ItemNames[object.Name] and object:FindFirstChild("ModulePrompt") then
            if _espItem then addESP(object, ItemNames[object.Name], "item") end
            table.insert(Objects.Items, object)
        elseif object.Name == "Green_Herb" then
            if _espItem then addESP(object,"Green Herb","item") end
            table.insert(Objects.Items, object)
        elseif object.Name == "GoldPile" and object:GetAttribute("GoldValue") then
            if _espCurrency then
                addESP(object,"Gold Pile ["..object:GetAttribute("GoldValue").."]","currency")
            end
            table.insert(Objects.Currency, object)
        elseif object.Name == "StardustPickup" then
            if _espCurrency then addESP(object,"Stardust","currency") end
            table.insert(Objects.Currency, object)
        elseif object.Name == "GiggleCeiling" then
            if _espEntity then addESP(object,"Giggle","entity") end
            if _bypassGiggle then
                local hb = object:WaitForChild("Hitbox")
                if hb then hb.CanTouch = false end
            end
            table.insert(Objects.Entities, object)
        elseif object.Name == "GloomPile" then
            if _bypassGloombat then
                for _, p in object:GetDescendants() do
                    if p:IsA("BasePart") then p.CanTouch = false end
                end
            end
            if _espEntity then addESP(object,"Gloombat Eggs","entity") end
            table.insert(Objects.Entities, object)
        elseif object.Name == "TriggerEventCollision" and checkfn("firetouchinterest") then
            if (Floor=="Fools" or Floor=="OldHotel") then
                task.spawn(function()
                    while object:IsDescendantOf(game) do
                        for _, ch in object:GetChildren() do
                            if ch:IsA("BasePart") and RootPart then
                                FireTouchInterest(RootPart, ch, 0)
                                task.wait()
                                FireTouchInterest(RootPart, ch, 1)
                            end
                        end
                        task.wait()
                    end
                end)
            end
            table.insert(Objects.EventTriggers, object)
        elseif object.Name == "DoorFake" or object.Name == "FakeDoor" then
            if object.Parent and object:FindFirstChild("Hidden") then
                if _bypassDupe then
                    object:WaitForChild("Hidden").CanTouch = false
                    if object:FindFirstChild("Lock") and object.Lock:FindFirstChild("UnlockPrompt") then
                        object.Lock.UnlockPrompt.Enabled = false
                    end
                end
                table.insert(Objects.Entities, object)
            end
        elseif object.Name == "SideroomSpace" then
            if _bypassVacuum then
                object:WaitForChild("Collision").CanCollide = true
                object:WaitForChild("Collision").CanTouch = false
            end
            table.insert(Objects.Entities, object)
        elseif object.Name == "Snare" then
            if _espEntity then addESP(object,"Snare","entity") end
            if _bypassSnare and object:FindFirstChild("Hitbox") then
                object.Hitbox.CanTouch = false
            end
            table.insert(Objects.Entities, object)
        elseif object.Name == "Seek_Arm" or object.Name == "ChandelierObstruction" then
            for _, p in object:GetDescendants() do
                if p:IsA("BasePart") then
                    p.CanTouch = not _bypassSeekObstruct
                    table.insert(Objects.SeekObstructions, p)
                end
            end
        elseif object.Name == "SeekFloodline" then
            object.CanCollide = _bypassSeekObstruct
            table.insert(Objects.SeekObstructions, object)
        elseif object.Name == "BananaPeel" then
            if _bypassBanana then object.CanTouch = false end
            table.insert(Objects.Entities, object)
        elseif object.Name == "JeffTheKiller" then
            if _bypassJeff then
                task.wait(1)
                for _, p in object:GetDescendants() do
                    if p:IsA("BasePart") then p.CanCollide=false; p.CanTouch=false end
                end
                local hum = object:WaitForChild("Humanoid")
                if hum then hum.Health = 0 end
            end
        elseif object.Name == "GrumbleRig" then
            if _espEntity then addESP(object,"Grumble","entity") end
            table.insert(Objects.Entities, object)
        elseif object.Name == "Drakobloxxer" then
            if _espEntity then addESP(object,"Drakobloxxer","entity") end
            table.insert(Objects.Entities, object)
        elseif object.Name == "LiveEntityBramble" then
            if _espEntity then addESP(object,"Bramble","entity") end
            table.insert(Objects.Entities, object)
        elseif object.Name == "Groundskeeper" then
            if _espEntity then addESP(object,"Groundskeeper","entity") end
            table.insert(Objects.Entities, object)
        elseif object.Name == "Figure" or object.Name == "FigureRig" or object.Name == "FigureRagdoll" then
            if _espEntity then addESP(object,"Figure","entity") end
            table.insert(Objects.Entities, object)
        elseif object.Name == "EyestalkEndCutscene" then
            object.Name = "_EyestalkEndCutscene"
        end
    end

    -- ── Entity spawns (workspace.ChildAdded, exact from reference) ────────────
    table.insert(Connections, workspace.ChildAdded:Connect(function(entity)
        if Entities[entity.Name] then
            local ed = Entities[entity.Name]
            while not entity.PrimaryPart do
                for _, ch in entity:GetChildren() do
                    if ch:IsA("BasePart") then entity.PrimaryPart = ch end
                end
                task.wait()
            end
            task.wait(0.1)

            if LocalPlayer:DistanceFromCharacter(entity.PrimaryPart.Position) < 10000 then
                if entity.Name ~= "GloombatSwarm" then
                    if _espEntity then addESP(entity, ed.Alias, "entity") end
                    table.insert(Objects.Entities, entity)
                end
                if entity.Name == "Lookman" then
                    CurrentRooms.ChildAdded:Wait()
                    task.wait(3)
                    entity:Destroy()
                end
            end
        end
    end))

    -- ── CurrentRooms DescendantAdded (exact from reference) ───────────────────
    table.insert(Connections, CurrentRooms.DescendantAdded:Connect(function(obj)
        task.spawn(HandleObject, obj)
    end))

    -- existing objects in current rooms
    task.spawn(function()
        for _, obj in CurrentRooms:GetDescendants() do
            task.spawn(HandleObject, obj)
        end
    end)

    -- ── Cleaner loop ──────────────────────────────────────────────────────────
    local lastClean = tick()
    table.insert(Connections, RunSvc.Heartbeat:Connect(function()
        if tick()-lastClean > 0.5 then
            for _, arr in Objects do
                for i = #arr, 1, -1 do
                    local obj = arr[i]
                    if obj == nil or not obj:IsDescendantOf(workspace) then
                        if obj then remESP(obj) end
                        table.remove(arr, i)
                    end
                end
            end
            lastClean = tick()
        end
    end))

    -- ── hookmetamethod (Crouch spoof + Eyes bypass) ────────────────────────────
    local MainHook
    if checkfn("hookmetamethod") and checkfn("newcclosure") and checkfn("getnamecallmethod") then
        MainHook = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local args = {...}
            local method = getnamecallmethod()
            if self.Name == "Crouch" and method == "FireServer" and (_crouchSpoof or _posSpoof) then
                args[1] = true
            end
            if self.Name == "MotorReplication" and method == "FireServer" and
               ((_bypassEyes and Globals.IsEyes) or (_bypassLookman and Globals.IsLookman)) then
                if Floor == "Fools" or Floor == "OldHotel" then
                    args[1]=0; args[2]=-65; args[3]=0; args[4]=false
                else
                    args[1] = -650
                end
            end
            return MainHook(self, table.unpack(args))
        end))
    end

    -- ── HandleCharacter (faithful port from reference) ────────────────────────
    local function HandleCharacter(newChar)
        -- disconnect per-character connections
        local charConns = {
            "MainHandler","JumpHandler","SlideHandler","LibraryCodeHandler1",
            "LibraryCodeHandler2","OxygenConnection","AnimationHandler",
            "AutoHideConnection","LagbackFixer","AutoReviveHandler","SHMFixer",
            "AnticheatDisabler","AnticheatEnableDetector1","AnticheatEnableDetector2",
            "AutoSteerMinecartDuckHandler","AutoSolveAnchorsConnection",
            "InfiniteJumpsConnection1","InfiniteJumpsConnection2","FootstepHandler",
        }
        for _, name in charConns do
            if Connections[name] then Connections[name]:Disconnect(); Connections[name]=nil end
        end

        while LocalPlayer:DistanceFromCharacter(workspace.CurrentCamera.CFrame.Position) > 5 do
            task.wait()
        end
        task.wait()

        Character     = newChar
        Humanoid      = newChar:WaitForChild("Humanoid", 9e9)
        RootPart      = newChar:FindFirstChild("HumanoidRootPart")
        Camera        = workspace.CurrentCamera

        Globals.MainUI = LocalPlayer.PlayerGui:FindFirstChild("MainUI")

        Collision = newChar:WaitForChild("Collision")
        CollisionPart = newChar:FindFirstChild("CollisionPart") or newChar:FindFirstChild("Collision")

        CollisionClone = Collision:Clone()
        CollisionClone.Parent = newChar
        CollisionClone.Name = "CollisionClone"
        CollisionClone.Massless = true

        CollisionPartClone = CollisionPart:Clone()
        CollisionPartClone.Parent = newChar
        CollisionPartClone.Name = "CollisionPartClone"
        CollisionPartClone.CanCollide = false
        CollisionPartClone.Massless = true
        if CollisionPartClone:FindFirstChild("CollisionCrouch") then
            CollisionPartClone.CollisionCrouch:Destroy()
        end

        newChar:SetAttribute("SpeedBoost",0)
        newChar:SetAttribute("SpeedBoostBehind",0)
        newChar:SetAttribute("SpeedBoostExtra",0)

        OldJump  = newChar:GetAttribute("CanJump")
        OldSlide = newChar:GetAttribute("CanSlide")
        if _jumpEnable  then newChar:SetAttribute("CanJump",true) end
        if _slideEnable then newChar:SetAttribute("CanSlide",true) end

        -- Modules (exact paths from reference)
        if ClientModules then
            pcall(function()
                local em = ClientModules.EntityModules
                Modules.Glitch = em.Glitch
                Modules.Shade  = em.Shade
                Modules.Void   = em:FindFirstChild("Void")
            end)
        end
        if Globals.MainUI then
            pcall(function()
                local rl = Globals.MainUI.Initiator.Main_Game.RemoteListener
                local ui = rl.Modules
                Modules.A90             = ui:FindFirstChild("A90")
                Modules.Screech         = ui.Screech
                Modules.Dread           = ui:FindFirstChild("Dread")
                Modules.SpiderJumpscare = ui.SpiderJumpscare
            end)
        end

        -- reapply module renames if toggles were on before respawn
        pcall(function()
            if _removeScreech and Modules.Screech then Modules.Screech.Name = "Screech_Disabled" end
            if _removeHalt   and Modules.Shade   then Modules.Shade.Name   = "Shade_Disabled"   end
            if _removeA90    and Modules.A90      then Modules.A90.Name     = "A90_Disabled"     end
            if _removeDread  and Modules.Dread    then Modules.Dread.Name   = "Dread_Disabled"   end
            if _disableGlitchJS  and Modules.Glitch         then Modules.Glitch.Name         = "Glitch_Disabled"         end
            if _disableTimothyJS and Modules.SpiderJumpscare then Modules.SpiderJumpscare.Name = "SpiderJumpscare_Disabled" end
            if _disableVoidJS    and Modules.Void            then Modules.Void.Name           = "Void_Disabled"           end
        end)

        if _removeAccel and RootPart then
            CustomPhysics = PhysicalProperties.new(100,
                RootPart.CustomPhysicalProperties.Friction,
                RootPart.CustomPhysicalProperties.Elasticity,
                RootPart.CustomPhysicalProperties.FrictionWeight,
                RootPart.CustomPhysicalProperties.ElasticityWeight)
            for _, p in newChar:GetDescendants() do
                if p:IsA("BasePart") then
                    PartProperties[p] = p.CustomPhysicalProperties
                    p.CustomPhysicalProperties = CustomPhysics
                end
            end
        end

        OriginalC1 = newChar.LowerTorso and newChar.LowerTorso:FindFirstChild("Root") and
                     newChar.LowerTorso.Root.C1 or CFrame.new()

        ManipulateBody.Parent = nil
        FlyBody.Parent = nil

        -- ── Per-character connections ─────────────────────────────────────
        Connections.JumpHandler = newChar:GetAttributeChangedSignal("CanJump"):Connect(function()
            if _jumpEnable and newChar:GetAttribute("CanJump") ~= true then end
            if not _jumpEnable then OldJump = newChar:GetAttribute("CanJump") end
            if _jumpEnable then newChar:SetAttribute("CanJump",true) end
        end)

        Connections.SlideHandler = newChar:GetAttributeChangedSignal("CanSlide"):Connect(function()
            if not _slideEnable then OldSlide = newChar:GetAttribute("CanSlide") end
            if _slideEnable then newChar:SetAttribute("CanSlide",true) end
        end)

        Connections.InfiniteJumpsConnection1 = game:GetService("UserInputService").InputBegan:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.Space and _infiniteJumps then
                Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)

        local lastAutoHide = tick()
        Connections.AutoHideConnection = RunSvc.Heartbeat:Connect(function()
            if _autoCloset and tick()-lastAutoHide > 0.05 then
                local entity = GetNearestEntity(true, _autoClosetIgnore)
                if entity then
                    local closet = GetNearestHidingSpot()
                    if Character:GetAttribute("Hiding") ~= true and closet then
                        ForceFirePrompt(closet.HidePrompt)
                    end
                elseif Character:GetAttribute("Hiding") == true then
                    pcall(function() RemotesFolder.CamLock:FireServer() end)
                end
                lastAutoHide = tick()
            end
        end)

        Connections.SHMFixer = RootPart:GetPropertyChangedSignal("Anchored"):Connect(function()
            task.wait()
            if Floor == "Fools" and RootPart.Anchored and Character:GetAttribute("Hiding") ~= true then
                RootPart.Anchored = false
            end
        end)

        Connections.AnticheatDisabler = newChar:GetAttributeChangedSignal("Climbing"):Connect(function()
            if newChar:GetAttribute("Climbing") == true and _disableAnticheat and not Globals.AnticheatDisabled then
                task.wait(0.25)
                newChar:SetAttribute("Climbing", false)
                Globals.AnticheatDisabled = true
            end
        end)

        Connections.AnticheatEnableDetector1 = RemotesFolder:WaitForChild("Cutscene").OnClientEvent:Connect(function(name)
            if Globals.AnticheatDisabled and not string.find(name,"SewerSeek") then
                Globals.AnticheatDisabled = false
            end
        end)

        Connections.AnticheatEnableDetector2 = RemotesFolder:WaitForChild("UseEnemyModule").OnClientEvent:Connect(function(mod)
            if (mod=="Void" or mod=="Glitch") and Globals.AnticheatDisabled then
                Globals.AnticheatDisabled = false
                LocalPlayer:SetAttribute("CurrentRoom", LatestRoom.Value)
            end
        end)

        Connections.FootstepHandler = newChar.ChildAdded:Connect(function(obj)
            if obj:IsA("Sound") and obj.Name == "Sound" then
                obj.Volume = 0
            end
        end)

        Connections.LagbackFixer = CollisionPart:GetPropertyChangedSignal("Anchored"):Connect(function()
            if CollisionPartClone and CollisionPart.Anchored and not newChar:GetAttribute("Hiding") then
                Globals.Lagging = true
                CollisionPartClone.Massless = true
                task.wait(1)
                Globals.Lagging = false
            end
        end)

        -- ── Main RenderStepped loop (exact from reference) ─────────────────
        Connections.MainHandler = RunSvc.RenderStepped:Connect(function()
            if _speed then
                Humanoid.WalkSpeed = GetCurrentSpeed() + _speedAmt
            end

            if Globals.Lagging or _speedAmt <= 6 and _flySpeed <= 21 then
                CollisionPartClone.Massless = true
            end

            Globals.IsEyes    = workspace:FindFirstChild("Eyes")   or workspace:FindFirstChild("Lookman") and true or false
            Globals.IsLookman = workspace:FindFirstChild("BackdoorLookman") and true or false

            if _removeFog then
                Lighting.FogEnd = 10000000
                for _, atm in Globals.FogInstances do
                    if atm and atm.Parent then atm.Density = 0 end
                end
            end

            if not Camera:FindFirstChild("MinecartRig") and Floor ~= "Fools" and Floor ~= "OldHotel" then
                RootPart.CanCollide = false
            end
            for _, p in newChar:GetChildren() do
                if p:IsA("BasePart") then p.CanCollide = false end
            end

            if Floor == "OldHotel" or Floor == "Fools" then
                Collision.Position = RootPart.Position + Vector3.new(0, (_posSpoof and GetNearestEntity() and (Floor=="OldHotel" and 200 or -5) or 0), 0)
                Collision.CanCollide = false
                if Floor == "Fools" then
                    pcall(function() Collision.CollisionCrouch.CanCollide = false end)
                    pcall(function() CollisionClone.CollisionCrouch.CanCollide = false end)
                end
                RootPart.CanCollide = not (_noclip or _velocityManip)
            else
                Collision.CanCollide = false
                pcall(function()
                    if Collision:FindFirstChild("CollisionCrouch") then
                        Collision.CollisionCrouch.CanCollide = false
                    end
                end)
                if CollisionClone:FindFirstChild("CollisionCrouch") then
                    CollisionClone.CanCollide = not (_noclip or _velocityManip or IsCrouching())
                    CollisionClone.CollisionCrouch.CanCollide = not (_noclip or _velocityManip or not IsCrouching())
                else
                    RootPart.CanCollide = not (_noclip or _velocityManip)
                end

                if newChar:FindFirstChild("LowerTorso") and newChar.LowerTorso:FindFirstChild("Root") then
                    newChar.LowerTorso.Root.C1 = OriginalC1 * CFrame.new(0, _posSpoof and -2.146 or 0, 0)
                end

                Collision.Position = RootPart.Position + Vector3.new(0, _posSpoof and 2.128 or 0.18, 0)
                CollisionPart.Position = RootPart.Position + Vector3.new(0, _posSpoof and 2.128 or 0.18, 0)
                pcall(function()
                    if Collision:FindFirstChild("CollisionCrouch") and CollisionClone:FindFirstChild("CollisionCrouch") then
                        Collision.CollisionCrouch.Position = RootPart.Position + Vector3.new(0, _posSpoof and 1.128 or -0.982, 0)
                        CollisionClone.CollisionCrouch.CollisionGroup = Collision.CollisionCrouch.CollisionGroup
                    end
                    if CollisionClone:FindFirstChild("CollisionCrouch") then
                        CollisionClone.CollisionCrouch.Position = RootPart.Position + Vector3.new(0, _posSpoof and 0.55 or -0.982, 0)
                    end
                end)
            end

            CollisionClone.CollisionGroup = Collision.CollisionGroup
            CollisionClone.Position = RootPart.Position + Vector3.new(0, _posSpoof and 1.55 or 0.18, 0)

            if _velocityManip then
                ManipulateBody.Parent = RootPart
                ManipulateBody.Velocity = RootPart.CFrame.LookVector * 2.25
            else
                ManipulateBody.Parent = nil
            end

            if _fly then
                FlyBody.Parent = RootPart
                FlyBody.Velocity = GetFlyVelocity() * _flySpeed
            else
                FlyBody.Parent = nil
            end

            if (_bypassEyes and Globals.IsEyes and not MainHook) or
               (_bypassLookman and Globals.IsLookman and not MainHook) then
                if Floor == "Fools" or Floor == "OldHotel" then
                    RemotesFolder.MotorReplication:FireServer(0, -65, 0, false)
                else
                    RemotesFolder.MotorReplication:FireServer(-650)
                end
            end

            -- send crouch on high speed/fly if no hook (from reference)
            if RemotesFolder:FindFirstChild("Crouch") and not MainHook then
                if (_speed and _speedAmt > 6 and Floor ~= "Fools" and Floor ~= "OldHotel") or
                   (_fly and _flySpeed > 21 and Floor ~= "Fools" and Floor ~= "OldHotel") then
                    local crouching = IsCrouching()
                    if _crouchSpoof or _posSpoof then crouching = true end
                    RemotesFolder.Crouch:FireServer(crouching, true)
                end
                if not MainHook and (_crouchSpoof or _posSpoof) then
                    RemotesFolder.Crouch:FireServer(true)
                end
            end

            if _removeClosetDelay and Humanoid.MoveDirection ~= Vector3.zero and
               (CollisionPart.Anchored or RootPart.Anchored) and
               newChar:GetAttribute("AnimatingClient") ~= true and
               newChar:GetAttribute("Hiding") == true then
                pcall(function() RemotesFolder.CamLock:FireServer() end)
            end
        end)

        -- position spoof offset on spawn
        task.wait(1)
        if _posSpoof and Floor ~= "Fools" and Floor ~= "OldHotel" then
            RootPart.CFrame = RootPart.CFrame * CFrame.new(0,-2.146,0)
            Humanoid.HipHeight = 0.25
            pcall(function() RemotesFolder.Crouch:FireServer(true) end)
        end
    end

    -- startup and respawn
    if LocalPlayer.Character then
        task.spawn(function() HandleCharacter(LocalPlayer.Character) end)
    end
    table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function(c)
        if Connections.MainHandler then Connections.MainHandler:Disconnect() end
        task.wait(0.5)
        HandleCharacter(c)
    end))

    -- ── Idle kick ─────────────────────────────────────────────────────────────
    local _disableIdle = false
    table.insert(Connections, LocalPlayer.Idled:Connect(function()
        if _disableIdle then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end))

    -- ── Fog handler ───────────────────────────────────────────────────────────
    table.insert(Connections, Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
        if Lighting.FogEnd ~= 10000000 then Globals.OldFog = Lighting.FogEnd end
        if _removeFog then Lighting.FogEnd = 10000000 end
    end))
    table.insert(Connections, Lighting.DescendantAdded:Connect(function(obj)
        if obj:IsA("Atmosphere") then
            obj:SetAttribute("Density_Old", obj.Density)
            if _removeFog then obj.Density = 0 end
            local c = obj:GetPropertyChangedSignal("Density"):Connect(function()
                if obj.Density ~= 0 then obj:SetAttribute("Density_Old", obj.Density) end
                if _removeFog then obj.Density = 0 end
            end)
            obj.Destroying:Once(function() c:Disconnect() end)
            table.insert(Connections, c)
            table.insert(Globals.FogInstances, obj)
        end
    end))

    -- ── Auto breaker box ──────────────────────────────────────────────────────
    table.insert(Connections, RunSvc.Heartbeat:Connect(function()
        if _autoBreaker and CurrentRooms:FindFirstChild("ElevatorBreaker", true) then
            pcall(function() RemotesFolder.EBF:FireServer() end)
        end
    end))

    -- ── FloorReplicated module handler ────────────────────────────────────────
    table.insert(Connections, FloorReplicated.DescendantAdded:Connect(function(obj)
        if obj.Name == "GlitchScreech" then
            Modules.GlitchScreech = obj
            if _removeScreech then obj.Name = "GlitchScreech_Disabled" end
        end
        if string.find(obj.Name,"Jumpscare") and obj:IsA("ModuleScript") and
           not string.find(obj.Name,"Eyestalk") and not string.find(obj.Name,"Groundskeeper") and
           not string.find(obj.Name,"Monument") then
            obj:SetAttribute("OriginalName", obj.Name)
            if _disableEntityJS then obj.Name = obj.Name .. "_Disabled" end
            table.insert(Objects.JumpscareModules, obj)
        end
    end))

    -- ══════════════════════════════════════════════════════════════════════════
    -- CONFIG (pre-declare so button/toggle callbacks capture the right slots)
    -- ══════════════════════════════════════════════════════════════════════════
    local CFG_FILE  = "astro/doors/config.json"
    local META_FILE = "astro/doors/meta.json"
    local readMeta, writeMeta, cfgEnsureDirs, saveConfig, loadConfig, silentLoadConfig

    -- ══════════════════════════════════════════════════════════════════════════
    -- SUB-TAB SYSTEM
    -- ══════════════════════════════════════════════════════════════════════════
    local function makeSubSection(parent)
        local f = Instance.new("Frame", parent)
        f.Size = UDim2.new(1, 0, 0, 0)
        f.BackgroundTransparency = 1
        f.Visible = false
        local lay = Instance.new("UIListLayout", f)
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        lay.Padding = UDim.new(0, 8)
        lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            f.Size = UDim2.new(1, 0, 0, lay.AbsoluteContentSize.Y)
        end)
        return f
    end

    local tabBar = Instance.new("Frame", section)
    tabBar.Size = UDim2.new(1, 0, 0, 32)
    tabBar.BackgroundTransparency = 1
    local tabBarLayout = Instance.new("UIListLayout", tabBar)
    tabBarLayout.FillDirection = Enum.FillDirection.Horizontal
    tabBarLayout.Padding = UDim.new(0, 5)

    local sMove   = makeSubSection(section)
    local sSelf   = makeSubSection(section)
    local sBypass = makeSubSection(section)
    local sVisual = makeSubSection(section)
    local sMisc   = makeSubSection(section)

    local activeSubSection, activeSubBtn

    local function makeSubTabBtn(label, sub)
        local btn = Instance.new("TextButton", tabBar)
        btn.Size = UDim2.new(1/5, -4, 1, 0)
        btn.BackgroundColor3 = Color3.fromRGB(15, 13, 26)
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 12
        btn.TextColor3 = Color3.fromRGB(170, 160, 210)
        btn.Text = label
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.MouseButton1Click:Connect(function()
            if activeSubSection then
                activeSubSection.Visible = false
                activeSubBtn.BackgroundColor3 = Color3.fromRGB(15, 13, 26)
                activeSubBtn.TextColor3 = Color3.fromRGB(170, 160, 210)
            end
            sub.Visible = true
            btn.BackgroundColor3 = Color3.fromRGB(38, 28, 75)
            btn.TextColor3 = Color3.fromRGB(210, 195, 255)
            activeSubSection = sub
            activeSubBtn = btn
        end)
        return btn
    end

    local btnMove   = makeSubTabBtn("Move",   sMove)
    local btnSelf   = makeSubTabBtn("Self",   sSelf)
    local btnBypass = makeSubTabBtn("Bypass", sBypass)
    local btnVisual = makeSubTabBtn("Visual", sVisual)
    local btnMisc   = makeSubTabBtn("Misc",   sMisc)

    sMove.Visible = true
    btnMove.BackgroundColor3 = Color3.fromRGB(38, 28, 75)
    btnMove.TextColor3 = Color3.fromRGB(210, 195, 255)
    activeSubSection = sMove
    activeSubBtn = btnMove

    -- ── Move ──────────────────────────────────────────────────────────────────
    local setSpeed    = elements:Toggle("Speed Boost", sMove, function(v) _speed = v
        if not v and Humanoid then Humanoid.WalkSpeed = GetCurrentSpeed() end
    end)
    local setSpeedAmt = elements:Slider("Speed Amount", sMove, 0, 85, 0, function(v) _speedAmt = v end)

    local setFly    = elements:Toggle("Fly", sMove, function(v) _fly = v
        if not v and FlyBody then FlyBody.Parent = nil end
    end)
    local setFlySpd = elements:Slider("Fly Speed", sMove, 0, 100, 20, function(v) _flySpeed = v end)

    local setNoclip = elements:Toggle("Noclip", sMove, function(v) _noclip = v end)

    local setJumpEnable = elements:Toggle("Enable Jumping", sMove, function(v)
        _jumpEnable = v
        if Character then Character:SetAttribute("CanJump", v and true or OldJump) end
    end)

    local setSlideEnable = elements:Toggle("Enable Sliding", sMove, function(v)
        _slideEnable = v
        if Character then Character:SetAttribute("CanSlide", v and true or OldSlide) end
    end)

    local setInfJumps = elements:Toggle("Infinite Jumps", sMove, function(v) _infiniteJumps = v end)

    local setPosSpoof = elements:Toggle("Position Spoof", sMove, function(v)
        _posSpoof = v
        if Character and RootPart and Humanoid and Floor ~= "Fools" and Floor ~= "OldHotel" then
            if v then
                RootPart.CFrame = RootPart.CFrame * CFrame.new(0,-2.146,0)
                Humanoid.HipHeight = 0.25
                pcall(function() RemotesFolder.Crouch:FireServer(true) end)
            else
                RootPart.CFrame = RootPart.CFrame * CFrame.new(0,2.146,0)
                Humanoid.HipHeight = 2.396
            end
        end
    end)

    local setCrouchSpoof = elements:Toggle("Crouch Spoof", sMove, function(v)
        _crouchSpoof = v
        if RemotesFolder:FindFirstChild("Crouch") then
            pcall(function() RemotesFolder.Crouch:FireServer(v and true or IsCrouching()) end)
        end
    end)

    local setVelocityManip  = elements:Toggle("Velocity Manipulation", sMove, function(v) _velocityManip = v end)

    local setRemoveAccel = elements:Toggle("Remove Acceleration", sMove, function(v)
        _removeAccel = v
        if Character then
            for _, p in Character:GetDescendants() do
                if p:IsA("BasePart") then
                    p.CustomPhysicalProperties = v and CustomPhysics or PartProperties[p]
                end
            end
        end
    end)

    local setRemoveClosetDelay = elements:Toggle("Remove Closet Delay", sMove, function(v) _removeClosetDelay = v end)

    -- ── Self ──────────────────────────────────────────────────────────────────
    local setDoorReach   = elements:Toggle("Door Reach",       sSelf, function(v) _doorReach   = v end)
    local setAutoCloset  = elements:Toggle("Auto Closet",      sSelf, function(v) _autoCloset  = v end)
    local setAutoBreaker = elements:Toggle("Auto Breaker Box", sSelf, function(v) _autoBreaker = v end)
    local setAutoInteract= elements:Toggle("Auto Interact",    sSelf, function(v) _autoInteract= v end)
    local setDisableIdle = elements:Toggle("Disable Idle Kick",sSelf, function(v) _disableIdle = v end)

    local setPromptReach = elements:Slider("Prompt Reach Multiplier", sSelf, 1, 10, 1, function(v)
        _promptReach = v
        for _, p in Objects.Prompts do
            if p and p.Parent then
                p.MaxActivationDistance = (p:GetAttribute("MaxActivationDistance_Old") or p.MaxActivationDistance) * v
            end
        end
    end)

    local setInstantPrompt = elements:Toggle("Instant Prompts", sSelf, function(v)
        _instantPrompt = v
        for _, p in Objects.Prompts do
            if p and p.Parent then
                p.HoldDuration = v and 0 or (p:GetAttribute("HoldDuration_Old") or p.HoldDuration)
            end
        end
    end)

    local setPromptClip = elements:Toggle("Prompt Clip (no LoS)", sSelf, function(v)
        _promptClip = v
        for _, p in Objects.Prompts do
            if p and p.Parent then
                p.RequiresLineOfSight = v and false or (p:GetAttribute("RequiresLineOfSight_Old") or p.RequiresLineOfSight)
            end
        end
    end)

    -- ── Bypass ────────────────────────────────────────────────────────────────
    local setBypassEyes = elements:Toggle("Bypass Eyes", sBypass, function(v)
        _bypassEyes = v
        if v and Globals.IsEyes then
            if Floor == "Fools" or Floor == "OldHotel" then
                pcall(function() RemotesFolder.MotorReplication:FireServer(0,-75,0,false) end)
            else
                pcall(function() RemotesFolder.MotorReplication:FireServer(-650) end)
            end
        end
    end)

    local setBypassLookman = elements:Toggle("Bypass Lookman", sBypass, function(v)
        _bypassLookman = v
        if v and Globals.IsLookman then
            if Floor == "Fools" or Floor == "OldHotel" then
                pcall(function() RemotesFolder.MotorReplication:FireServer(0,-75,0,false) end)
            else
                pcall(function() RemotesFolder.MotorReplication:FireServer(-650) end)
            end
        end
    end)

    local setBypassGiggle = elements:Toggle("Bypass Giggle", sBypass, function(v)
        _bypassGiggle = v
        for _, obj in Objects.Entities do
            if obj.Name == "GiggleCeiling" and obj:FindFirstChild("Hitbox") then
                obj.Hitbox.CanTouch = not v
            end
        end
    end)

    local setBypassDupe = elements:Toggle("Bypass Dupe", sBypass, function(v)
        _bypassDupe = v
        for _, obj in Objects.Entities do
            if obj.Name == "DoorFake" or obj.Name == "FakeDoor" then
                pcall(function()
                    obj:WaitForChild("Hidden").CanTouch = not v
                    if obj:FindFirstChild("Lock") then
                        obj.Lock.UnlockPrompt.Enabled = not v
                    end
                end)
            end
        end
    end)

    local setBypassGloombat = elements:Toggle("Bypass Gloombat Eggs", sBypass, function(v)
        _bypassGloombat = v
        for _, obj in Objects.Entities do
            for _, p in obj:GetDescendants() do
                if p:IsA("BasePart") then p.CanTouch = not v end
            end
        end
    end)

    local setBypassSeekObstruct = elements:Toggle("Bypass Seek Obstructions", sBypass, function(v)
        _bypassSeekObstruct = v
        for _, p in Objects.SeekObstructions do
            p.CanTouch = not v
            if p.Name == "SeekFloodline" then p.CanCollide = v end
        end
        for _, b in Objects.SeekBridges do
            b.CanCollide = v; b.Transparency = v and 0 or 1
        end
    end)

    local setBypassVacuum = elements:Toggle("Bypass Vacuum", sBypass, function(v)
        _bypassVacuum = v
        for _, obj in Objects.Entities do
            if obj.Name == "SideroomSpace" then
                pcall(function()
                    obj:WaitForChild("Collision").CanCollide = v
                    obj:WaitForChild("Collision").CanTouch = not v
                end)
            end
        end
    end)

    local setBypassKillbrick = elements:Toggle("Bypass Killbricks (Lava)", sBypass, function(v)
        _bypassKillbrick = v
        for _, obj in Objects.Obstructions do
            if obj.Name == "Lava" then obj.CanTouch = not v end
        end
    end)

    local setBypassSeekWall = elements:Toggle("Bypass Seeking Wall", sBypass, function(v)
        _bypassSeekWall = v
        for _, obj in Objects.Obstructions do
            if obj.Name == "ScaryWall" then
                for _, p in obj:GetDescendants() do
                    if p:IsA("BasePart") then p.CanTouch=not v; p.CanCollide=not v end
                end
            end
        end
    end)

    local setBypassSnare = elements:Toggle("Bypass Snare", sBypass, function(v)
        _bypassSnare = v
        for _, obj in Objects.Entities do
            if obj.Name == "Snare" and obj:FindFirstChild("Hitbox") then
                obj.Hitbox.CanTouch = not v
            end
        end
    end)

    local setBypassBanana = elements:Toggle("Bypass Banana", sBypass, function(v)
        _bypassBanana = v
        for _, obj in Objects.Entities do
            if obj.Name == "BananaPeel" then obj.CanTouch = not v end
        end
    end)

    local setBypassJeff = elements:Toggle("Bypass Jeff", sBypass, function(v)
        _bypassJeff = v
        for _, obj in Objects.Entities do
            if obj.Name == "JeffTheKiller" then
                for _, p in obj:GetDescendants() do
                    if p:IsA("BasePart") then p.CanCollide=not v; p.CanTouch=not v end
                end
                pcall(function() obj:WaitForChild("Humanoid").Health = 0 end)
            end
        end
    end)

    local setDisableAnticheat = elements:Toggle("Disable Anticheat", sBypass, function(v) _disableAnticheat = v end)

    local setNoScreechDmg = elements:Toggle("No Screech Damage", sBypass, function(v)
        _noScreechDmg = v
        if v then
            FakeEvents.Screech.Parent = RemotesFolder
            FakeEvents.Screech_Real.Parent = nil
        else
            FakeEvents.Screech_Real.Parent = RemotesFolder
            FakeEvents.Screech.Parent = nil
        end
    end)

    local setNoHaltDmg = elements:Toggle("No Halt Damage", sBypass, function(v)
        _noHaltDmg = v
        if v then
            FakeEvents.Shade.Parent = RemotesFolder
            FakeEvents.Shade_Real.Parent = nil
        else
            FakeEvents.Shade_Real.Parent = RemotesFolder
            FakeEvents.Shade.Parent = nil
        end
    end)

    local setNoA90Dmg = elements:Toggle("No A-90 Damage", sBypass, function(v)
        _noA90Dmg = v
        if FakeEvents.A90_Real then
            if v then FakeEvents.A90.Parent=RemotesFolder; FakeEvents.A90_Real.Parent=nil
            else FakeEvents.A90_Real.Parent=RemotesFolder; FakeEvents.A90.Parent=nil end
        end
    end)

    local setNoSurgeDmg = elements:Toggle("No Surge Damage", sBypass, function(v)
        _noSurgeDmg = v
        if FakeEvents.Surge_Real then
            if v then FakeEvents.Surge.Parent=RemotesFolder; FakeEvents.Surge_Real.Parent=nil
            else FakeEvents.Surge_Real.Parent=RemotesFolder; FakeEvents.Surge.Parent=nil end
        end
    end)

    local setRemoveScreech = elements:Toggle("Remove Screech", sBypass, function(v)
        _removeScreech = v
        pcall(function()
            Modules.Screech.Name = v and "Screech_Disabled" or "Screech"
            if Modules.GlitchScreech then
                Modules.GlitchScreech.Name = v and "GlitchScreech_Disabled" or "GlitchScreech"
            end
        end)
    end)

    local setRemoveHalt = elements:Toggle("Remove Halt", sBypass, function(v)
        _removeHalt = v
        pcall(function() Modules.Shade.Name = v and "Shade_Disabled" or "Shade" end)
    end)

    local setRemoveA90 = elements:Toggle("Remove A-90", sBypass, function(v)
        _removeA90 = v
        pcall(function() if Modules.A90 then Modules.A90.Name = v and "A90_Disabled" or "A90" end end)
    end)

    local setRemoveDread = elements:Toggle("Remove Dread", sBypass, function(v)
        _removeDread = v
        pcall(function() if Modules.Dread then Modules.Dread.Name = v and "Dread_Disabled" or "Dread" end end)
    end)

    -- ── Visual ────────────────────────────────────────────────────────────────
    local setRemoveFog = elements:Toggle("Remove Camera Fog", sVisual, function(v)
        _removeFog = v
        Lighting.FogEnd = v and 10000000 or Globals.OldFog
        for _, obj in Globals.FogInstances do
            if obj and obj.Parent then
                obj.Density = v and 0 or (obj:GetAttribute("Density_Old") or 0)
            end
        end
    end)

    local setDisableGlitchJS = elements:Toggle("Disable Glitch Jumpscare", sVisual, function(v)
        _disableGlitchJS = v
        pcall(function() Modules.Glitch.Name = v and "Glitch_Disabled" or "Glitch" end)
    end)

    local setDisableTimothyJS = elements:Toggle("Disable Timothy Jumpscare", sVisual, function(v)
        _disableTimothyJS = v
        pcall(function() Modules.SpiderJumpscare.Name = v and "SpiderJumpscare_Disabled" or "SpiderJumpscare" end)
    end)

    local setDisableVoidJS = elements:Toggle("Disable Void Jumpscare", sVisual, function(v)
        _disableVoidJS = v
        pcall(function() if Modules.Void then Modules.Void.Name = v and "Void_Disabled" or "Void" end end)
    end)

    local setDisableEntityJS = elements:Toggle("Disable Entity Jumpscares", sVisual, function(v)
        _disableEntityJS = v
        pcall(function()
            local js = Globals.MainUI.Initiator.Main_Game.RemoteListener:FindFirstChild("Jumpscares")
                    or Globals.MainUI.Initiator.Main_Game.RemoteListener:FindFirstChild("Jumpscares_Disabled")
            if js then js.Name = v and "Jumpscares_Disabled" or "Jumpscares" end
        end)
        for _, obj in Objects.JumpscareModules do
            local orig = obj:GetAttribute("OriginalName") or obj.Name
            obj.Name = v and orig.."_Disabled" or orig
        end
    end)

    local setDisableHideVignette = elements:Toggle("Disable Hide Vignette", sVisual, function(v)
        _disableHideVignette = v
        pcall(function()
            local vig = Globals.MainUI:FindFirstChild("HideVignette")
                     or Globals.MainUI.MainFrame:FindFirstChild("HideVignette")
            if vig then vig.Image = v and "Disabled" or "rbxassetid://6100076320" end
        end)
    end)

    local setEspEntity = elements:Toggle("Entity ESP", sVisual, function(v)
        _espEntity = v
        if v then
            for _, obj in Objects.Entities do
                local label = Entities[obj.Name] and Entities[obj.Name].Alias or obj.Name
                addESP(obj, label, "entity")
            end
        else
            for _, obj in Objects.Entities do remESP(obj) end
        end
    end)

    local setEspDoor = elements:Toggle("Door ESP", sVisual, function(v)
        _espDoor = v
        if v then for _, obj in Objects.Doors do addESP(obj,"Door","door") end
        else      for _, obj in Objects.Doors do remESP(obj) end end
    end)

    local setEspHide = elements:Toggle("Hiding Spot ESP", sVisual, function(v)
        _espHide = v
        local names = {Wardrobe="Closet",Backdoor_Wardrobe="Closet",Toolshed="Closet",
                       RetroWardrobe="Closet",["Wardrobe-FOOLS26"]="Closet",
                       Locker_Large="Locker",Rooms_Locker="Locker",Rooms_Locker_Fridge="Locker",
                       Bed="Bed",Double_Bed="Double Bed",CircularVent="Vent",Dumpster="Dumpster"}
        if v then for _, obj in Objects.HidingSpots do addESP(obj, names[obj.Name] or obj.Name, "hiding") end
        else     for _, obj in Objects.HidingSpots do remESP(obj) end end
    end)

    local setEspItem = elements:Toggle("Item ESP", sVisual, function(v)
        _espItem = v
        if v then
            for _, obj in Objects.Items do
                addESP(obj, ItemNames[obj.Name] or obj.Name, "item")
            end
        else for _, obj in Objects.Items do remESP(obj) end end
    end)

    local setEspChest = elements:Toggle("Chest ESP", sVisual, function(v)
        _espChest = v
        if v then
            local labels = {ChestBox="Chest",ChestBoxLocked="Locked Chest",Chest_Vine="Vine Chest",
                            Toolbox="Toolbox",Toolbox_Locked="Locked Toolbox",Toolshed_Small="Toolshed",
                            Locker_Small_Locked="Locked Item Locker",MouseHole="Mouse"}
            for _, obj in Objects.Chests do addESP(obj, labels[obj.Name] or obj.Name, "chest") end
        else for _, obj in Objects.Chests do remESP(obj) end end
    end)

    local setEspObjective = elements:Toggle("Objective ESP", sVisual, function(v)
        _espObjective = v
        if v then for _, obj in Objects.Objectives do addESP(obj, obj.Name, "objective") end
        else      for _, obj in Objects.Objectives do remESP(obj) end end
    end)

    local setEspCurrency = elements:Toggle("Currency ESP", sVisual, function(v)
        _espCurrency = v
        if v then
            for _, obj in Objects.Currency do
                local label = obj.Name == "GoldPile" and "Gold Pile ["..tostring(obj:GetAttribute("GoldValue")).."]" or "Stardust"
                addESP(obj, label, "currency")
            end
        else for _, obj in Objects.Currency do remESP(obj) end end
    end)

    local setEspLadder = elements:Toggle("Ladder ESP", sVisual, function(v)
        _espLadder = v
        if v then for _, obj in Objects.Ladders do addESP(obj,"Ladder","ladder") end
        else      for _, obj in Objects.Ladders do remESP(obj) end end
    end)

    local setEspPlayer = elements:Toggle("Player ESP", sVisual, function(v)
        _espPlayer = v
        if v then
            for _, p in Players:GetPlayers() do
                if p ~= LocalPlayer and p.Character then
                    addESP(p.Character, p.Name, "player")
                end
            end
        else
            for _, p in Players:GetPlayers() do
                if p.Character then remESP(p.Character) end
            end
        end
    end)

    -- ── Misc ──────────────────────────────────────────────────────────────────
    elements:Button("Revive Self", sMisc, function()
        pcall(function() RemotesFolder.Revive:FireServer() end)
    end)

    elements:Button("Play Again", sMisc, function()
        pcall(function() RemotesFolder.PlayAgain:FireServer() end)
    end)

    elements:Button("Return to Lobby", sMisc, function()
        pcall(function() RemotesFolder.Lobby:FireServer() end)
    end)

    -- ── Config (assign to pre-declared slots) ────────────────────────────────
    cfgEnsureDirs = function()
        if not isfolder("astro")       then makefolder("astro")       end
        if not isfolder("astro/doors") then makefolder("astro/doors") end
    end

    readMeta = function()
        if not isfile(META_FILE) then return {} end
        local ok, d = pcall(function() return HttpService:JSONDecode(readfile(META_FILE)) end)
        return (ok and type(d) == "table") and d or {}
    end

    writeMeta = function(tbl)
        cfgEnsureDirs()
        writefile(META_FILE, HttpService:JSONEncode(tbl))
    end

    saveConfig = function()
        cfgEnsureDirs()
        writefile(CFG_FILE, HttpService:JSONEncode({
            -- move
            speed=_speed, speedAmt=_speedAmt, fly=_fly, flySpeed=_flySpeed,
            noclip=_noclip, jumpEnable=_jumpEnable, slideEnable=_slideEnable,
            infJumps=_infiniteJumps, posSpoof=_posSpoof, crouchSpoof=_crouchSpoof,
            velocityManip=_velocityManip, removeAccel=_removeAccel,
            removeClosetDelay=_removeClosetDelay,
            -- self
            doorReach=_doorReach, autoCloset=_autoCloset, autoBreaker=_autoBreaker,
            autoInteract=_autoInteract, disableIdle=_disableIdle,
            promptReach=_promptReach, instantPrompt=_instantPrompt, promptClip=_promptClip,
            -- bypass
            bypassEyes=_bypassEyes, bypassLookman=_bypassLookman,
            bypassGiggle=_bypassGiggle, bypassDupe=_bypassDupe,
            bypassGloombat=_bypassGloombat, bypassSeekObstruct=_bypassSeekObstruct,
            bypassVacuum=_bypassVacuum, bypassKillbrick=_bypassKillbrick,
            bypassSeekWall=_bypassSeekWall, bypassSnare=_bypassSnare,
            bypassBanana=_bypassBanana, bypassJeff=_bypassJeff,
            disableAnticheat=_disableAnticheat,
            noScreechDmg=_noScreechDmg, noHaltDmg=_noHaltDmg,
            noA90Dmg=_noA90Dmg, noSurgeDmg=_noSurgeDmg,
            removeScreech=_removeScreech, removeHalt=_removeHalt,
            removeA90=_removeA90, removeDread=_removeDread,
            -- visual
            removeFog=_removeFog,
            disableGlitchJS=_disableGlitchJS, disableTimothyJS=_disableTimothyJS,
            disableVoidJS=_disableVoidJS, disableEntityJS=_disableEntityJS,
            disableHideVignette=_disableHideVignette,
            espEntity=_espEntity, espDoor=_espDoor, espHide=_espHide,
            espItem=_espItem, espChest=_espChest, espObjective=_espObjective,
            espCurrency=_espCurrency, espLadder=_espLadder, espPlayer=_espPlayer,
        }))
    end

    loadConfig = function()
        if not isfile(CFG_FILE) then return false end
        local ok, d = pcall(function() return HttpService:JSONDecode(readfile(CFG_FILE)) end)
        if not ok or type(d) ~= "table" then return false end
        -- sliders first (values, no side effects that need char)
        if d.speedAmt   then setSpeedAmt(d.speedAmt)     end
        if d.flySpeed   then setFlySpd(d.flySpeed)       end
        if d.promptReach then setPromptReach(d.promptReach) end
        -- toggles
        if d.speed         ~= nil then setSpeed(d.speed)                   end
        if d.fly           ~= nil then setFly(d.fly)                       end
        if d.noclip        ~= nil then setNoclip(d.noclip)                 end
        if d.jumpEnable    ~= nil then setJumpEnable(d.jumpEnable)         end
        if d.slideEnable   ~= nil then setSlideEnable(d.slideEnable)       end
        if d.infJumps      ~= nil then setInfJumps(d.infJumps)             end
        if d.posSpoof      ~= nil then setPosSpoof(d.posSpoof)             end
        if d.crouchSpoof   ~= nil then setCrouchSpoof(d.crouchSpoof)       end
        if d.velocityManip ~= nil then setVelocityManip(d.velocityManip)   end
        if d.removeAccel   ~= nil then setRemoveAccel(d.removeAccel)       end
        if d.removeClosetDelay ~= nil then setRemoveClosetDelay(d.removeClosetDelay) end
        if d.doorReach     ~= nil then setDoorReach(d.doorReach)           end
        if d.autoCloset    ~= nil then setAutoCloset(d.autoCloset)         end
        if d.autoBreaker   ~= nil then setAutoBreaker(d.autoBreaker)       end
        if d.autoInteract  ~= nil then setAutoInteract(d.autoInteract)     end
        if d.disableIdle   ~= nil then setDisableIdle(d.disableIdle)       end
        if d.instantPrompt ~= nil then setInstantPrompt(d.instantPrompt)   end
        if d.promptClip    ~= nil then setPromptClip(d.promptClip)         end
        if d.bypassEyes    ~= nil then setBypassEyes(d.bypassEyes)         end
        if d.bypassLookman ~= nil then setBypassLookman(d.bypassLookman)   end
        if d.bypassGiggle  ~= nil then setBypassGiggle(d.bypassGiggle)     end
        if d.bypassDupe    ~= nil then setBypassDupe(d.bypassDupe)         end
        if d.bypassGloombat ~= nil then setBypassGloombat(d.bypassGloombat) end
        if d.bypassSeekObstruct ~= nil then setBypassSeekObstruct(d.bypassSeekObstruct) end
        if d.bypassVacuum  ~= nil then setBypassVacuum(d.bypassVacuum)     end
        if d.bypassKillbrick ~= nil then setBypassKillbrick(d.bypassKillbrick) end
        if d.bypassSeekWall ~= nil then setBypassSeekWall(d.bypassSeekWall) end
        if d.bypassSnare   ~= nil then setBypassSnare(d.bypassSnare)       end
        if d.bypassBanana  ~= nil then setBypassBanana(d.bypassBanana)     end
        if d.bypassJeff    ~= nil then setBypassJeff(d.bypassJeff)         end
        if d.disableAnticheat ~= nil then setDisableAnticheat(d.disableAnticheat) end
        if d.noScreechDmg  ~= nil then setNoScreechDmg(d.noScreechDmg)   end
        if d.noHaltDmg     ~= nil then setNoHaltDmg(d.noHaltDmg)         end
        if d.noA90Dmg      ~= nil then setNoA90Dmg(d.noA90Dmg)           end
        if d.noSurgeDmg    ~= nil then setNoSurgeDmg(d.noSurgeDmg)       end
        if d.removeScreech ~= nil then setRemoveScreech(d.removeScreech) end
        if d.removeHalt    ~= nil then setRemoveHalt(d.removeHalt)       end
        if d.removeA90     ~= nil then setRemoveA90(d.removeA90)         end
        if d.removeDread   ~= nil then setRemoveDread(d.removeDread)     end
        if d.removeFog     ~= nil then setRemoveFog(d.removeFog)         end
        if d.disableGlitchJS   ~= nil then setDisableGlitchJS(d.disableGlitchJS)     end
        if d.disableTimothyJS  ~= nil then setDisableTimothyJS(d.disableTimothyJS)   end
        if d.disableVoidJS     ~= nil then setDisableVoidJS(d.disableVoidJS)         end
        if d.disableEntityJS   ~= nil then setDisableEntityJS(d.disableEntityJS)     end
        if d.disableHideVignette ~= nil then setDisableHideVignette(d.disableHideVignette) end
        if d.espEntity    ~= nil then setEspEntity(d.espEntity)     end
        if d.espDoor      ~= nil then setEspDoor(d.espDoor)         end
        if d.espHide      ~= nil then setEspHide(d.espHide)         end
        if d.espItem      ~= nil then setEspItem(d.espItem)         end
        if d.espChest     ~= nil then setEspChest(d.espChest)       end
        if d.espObjective ~= nil then setEspObjective(d.espObjective) end
        if d.espCurrency  ~= nil then setEspCurrency(d.espCurrency) end
        if d.espLadder    ~= nil then setEspLadder(d.espLadder)     end
        if d.espPlayer    ~= nil then setEspPlayer(d.espPlayer)     end
        return true
    end

    silentLoadConfig = function()
        if not isfile(CFG_FILE) then return false end
        local ok, d = pcall(function() return HttpService:JSONDecode(readfile(CFG_FILE)) end)
        if not ok or type(d) ~= "table" then return false end
        if d.speedAmt    then setSpeedAmt(d.speedAmt)       end
        if d.flySpeed    then setFlySpd(d.flySpeed)         end
        if d.promptReach then setPromptReach(d.promptReach) end
        return true
    end

    local _autoLoad = readMeta().autoLoad == true

    elements:Label("— Doors Config —", sMisc)
    elements:Button("Save Config",  sMisc, function() pcall(saveConfig)       end)
    elements:Button("Load Config",  sMisc, function() pcall(loadConfig)       end)
    elements:Button("Silent Load",  sMisc, function() pcall(silentLoadConfig) end)
    local setAutoLoad = elements:Toggle("Auto Load on Start", sMisc, function(v)
        _autoLoad = v
        local m = readMeta(); m.autoLoad = v
        pcall(writeMeta, m)
    end)
    setAutoLoad(_autoLoad)

    if _autoLoad then pcall(loadConfig) end

    -- ── Unload (faithful restore from reference) ──────────────────────────────
    section.AncestorRemoving:Connect(function()
        -- disconnect all connections
        for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
        for k, c in pairs(Connections) do
            if type(c) == "userdata" then pcall(function() c:Disconnect() end) end
        end

        -- restore real remotes
        FakeEvents.Screech.Parent = nil;   FakeEvents.Screech_Real.Parent = RemotesFolder
        FakeEvents.Shade.Parent   = nil;   FakeEvents.Shade_Real.Parent   = RemotesFolder
        if FakeEvents.A90_Real   then FakeEvents.A90.Parent=nil;   FakeEvents.A90_Real.Parent=RemotesFolder   end
        if FakeEvents.Surge_Real then FakeEvents.Surge.Parent=nil; FakeEvents.Surge_Real.Parent=RemotesFolder end

        -- restore modules
        pcall(function()
            Modules.Screech.Name         = "Screech"
            Modules.Glitch.Name          = "Glitch"
            Modules.Shade.Name           = "Shade"
            Modules.SpiderJumpscare.Name = "SpiderJumpscare"
            if Modules.A90    then Modules.A90.Name    = "A90"    end
            if Modules.Dread  then Modules.Dread.Name  = "Dread"  end
            if Modules.Void   then Modules.Void.Name   = "Void"   end
        end)

        -- restore entity hitboxes
        for _, obj in Objects.Entities do
            pcall(function()
                if obj.Name == "Snare" or obj.Name == "GiggleCeiling" then
                    obj:WaitForChild("Hitbox").CanTouch = true
                end
                if obj.Name == "GloomPile" then
                    for _, p in obj:GetDescendants() do
                        if p:IsA("BasePart") then p.CanTouch = true end
                    end
                end
                if obj.Name == "FakeDoor" or obj.Name == "DoorFake" then
                    obj:WaitForChild("Hidden").CanTouch = true
                    if obj:FindFirstChild("Lock") then obj.Lock.UnlockPrompt.Enabled = true end
                end
                if obj.Name == "SideroomSpace" then
                    obj:WaitForChild("Collision").CanCollide = false
                    obj:WaitForChild("Collision").CanTouch = true
                end
            end)
        end

        -- restore prompts
        for _, p in Objects.Prompts do
            pcall(function()
                if p and p.Parent then
                    p.HoldDuration = p:GetAttribute("HoldDuration_Old") or p.HoldDuration
                    p.RequiresLineOfSight = p:GetAttribute("RequiresLineOfSight_Old") or p.RequiresLineOfSight
                    p.MaxActivationDistance = p:GetAttribute("MaxActivationDistance_Old") or p.MaxActivationDistance
                end
            end)
        end

        -- restore fog
        for _, obj in Globals.FogInstances do
            pcall(function()
                if obj and obj.Parent then
                    obj.Density = obj:GetAttribute("Density_Old") or 0
                end
            end)
        end
        Lighting.FogEnd = Globals.OldFog

        -- restore hide vignette
        pcall(function()
            local vig = Globals.MainUI:FindFirstChild("HideVignette")
                     or Globals.MainUI.MainFrame:FindFirstChild("HideVignette")
            if vig then vig.Image = "rbxassetid://6100076320" end
        end)

        -- restore character
        pcall(function()
            if Character then
                Character:SetAttribute("CanJump",  OldJump)
                Character:SetAttribute("CanSlide", OldSlide)
            end
            if Humanoid then
                Humanoid.WalkSpeed = GetCurrentSpeed()
                Humanoid.HipHeight = 2.367
            end
            if RootPart then
                RootPart.CanCollide = true
                if Collision     then Collision.Position     = RootPart.Position + Vector3.new(0,0.18,0) end
                if CollisionPart then CollisionPart.Position = RootPart.Position + Vector3.new(0,0.18,0) end
                if Character and Character:FindFirstChild("LowerTorso") and Character.LowerTorso:FindFirstChild("Root") then
                    Character.LowerTorso.Root.C1 = OriginalC1
                end
            end
            if CollisionClone     then CollisionClone:Destroy()     end
            if CollisionPartClone then CollisionPartClone:Destroy() end
        end)

        ManipulateBody.Parent = nil
        FlyBody.Parent = nil

        -- clear ESP
        if espRenderConn then espRenderConn:Disconnect(); espRenderConn = nil end
        for obj, data in pairs(espBills) do data.bb:Destroy() end
        table.clear(espBills)

        if MainHook then
            pcall(function() hookmetamethod(game, "__namecall", MainHook) end)
        end
    end)
end
