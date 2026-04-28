----Custom Eyes
------V1
[[--
  _________            .__        __      ________                    __                
 /   _____/ ___________|__|______/  |_   /  _____/_____    _____     |__| ____    ____  
 \_____  \_/ ___\_  __ \  \____ \   __\ /   \  ___\__  \  /     \    |  |/    \  / ___\ 
 /        \  \___|  | \/  |  |_> >  |   \    \_\  \/ __ \|  Y Y  \   |  |   |  \/ /_/  >
/_______  /\___  >__|  |__|   __/|__|    \______  (____  /__|_|  /\__|  |___|  /\___  / 
        \/     \/         |__|                  \/     \/      \/\______|    \//_____/  
]]--

if getgenv().CustomEyesLib then return getgenv().CustomEyesLib end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Module = {
    ActiveEyes = {}
}

local CONST = {
    DEFAULT = {
        Entity = {
            Name = "Custom Eyes",
            Asset = "",
            HeightOffset = 3
        },
        Damage = {
            Enabled = true,
            Looking = {
                Enabled = true,
                Damage = 10,
                Range = 30,
                DamagePerSecond = 10
            },
            Bite = {
                Enabled = false,
                Damage = 15,
                Range = 40,
                Interval = 1
            },
            Lighter = {
                Enabled = false,
                SafeItem = "Lighter",
                CheckInterval = 0.5
            }
        },
        Gone = {
            OpeningTheDoor = true,
            A Few Seconds = {
                Enabled = false,
                Seconds = 10
            }
        },
        DEBUG = {
            OnSpawned = function() end,
            OnDamage = function() end,
            OnDeath = function() end,
            OnDespawned = function() end
        }
    }
}

local function ApplyConfigDefaults(config)
    local new = {}
    for key, value in next, CONST.DEFAULT do
        if config[key] ~= nil then
            new[key] = config[key]
        else
            new[key] = value
        end
    end
    return new
end

local function HasLighter()
    local char = LocalPlayer.Character
    if not char then return false end
    local tool = char:FindFirstChildOfClass("Tool")
    return tool and tool.Name == "Lighter"
end

local function LoadAsset(asset)
    if not asset or asset == "" then return nil end
    if string.match(asset, "^%d+$") then
        return game:GetObjects("rbxassetid://" .. asset)[1]
    elseif string.match(asset, "^https?://") then
        return game:GetObjects(asset)[1]
    end
    return nil
end

Module.Create = function(self, config)
    local newConfig = ApplyConfigDefaults(config)
    
    local eyeModel = LoadAsset(newConfig.Entity.Asset)
    if not eyeModel then
        eyeModel = Instance.new("Model")
        local part = Instance.new("Part")
        part.Name = "EyesPart"
        part.Size = Vector3.new(2.5, 2.5, 1)
        part.Anchored = true
        part.BrickColor = BrickColor.new("Really red")
        part.Transparency = 0.3
        part.Parent = eyeModel
        eyeModel.PrimaryPart = part
    end
    
    eyeModel.Name = newConfig.Entity.Name
    
    local eyeTable = {
        Model = eyeModel,
        Config = newConfig,
        Debug = CONST.DEFAULT.DEBUG,
        
        SetCallback = function(self, key, callback)
            if self.Debug[key] ~= nil then
                self.Debug[key] = callback
            end
        end,
        
        RunCallback = function(self, key, ...)
            if self.Debug[key] then
                self.Debug[key](...)
            end
        end,
        
        Run = function(self)
            Module:RunEye(self)
        end,
        
        Despawn = function(self)
            if self.Model and self.Model.Parent then
                self.Model:Destroy()
                local i = table.find(Module.ActiveEyes, self)
                if i then table.remove(Module.ActiveEyes, i) end
                self:RunCallback("OnDespawned")
            end
        end
    }
    
    return eyeTable
end

Module.RunEye = function(self, eye)
    table.insert(Module.ActiveEyes, eye)
    eye:RunCallback("OnSpawned")
    
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")
    local camera = workspace.CurrentCamera
    
    eye.Model:PivotTo(char.HumanoidRootPart.CFrame * CFrame.new(0, 0, 12)
    eye.Model.Parent = workspace
    
    local config = eye.Config
    local dead = false
    
    if config.Damage.Looking.Enabled then
        task.spawn(function()
            while eye.Model and eye.Model.Parent and not dead do
                task.wait(0.1)
                if humanoid.Health <= 0 then dead = true end
                
                local dist = (char.HumanoidRootPart.Position - eye.Model.PrimaryPart.Position).Magnitude
                if dist <= config.Damage.Looking.Range then
                    local screenPos, onScreen = camera:WorldToViewportPoint(eye.Model.PrimaryPart.Position)
                    if onScreen then
                        humanoid.Health = math.max(0, humanoid.Health - config.Damage.Looking.Damage)
                        eye:RunCallback("OnDamage", LocalPlayer, config.Damage.Looking.Damage, "Looking")
                        if humanoid.Health <= 0 then
                            dead = true
                            eye:RunCallback("OnDeath")
                        end
                    end
                end
            end
        end)
    end
    
    if config.Damage.Bite.Enabled then
        task.spawn(function()
            while eye.Model and eye.Model.Parent and not dead do
                task.wait(config.Damage.Bite.Interval or 1)
                if humanoid.Health <= 0 then dead = true end
                
                local safe = false
                if config.Damage.Lighter.Enabled then
                    safe = HasLighter()
                end
                
                if not safe then
                    local dist = (char.HumanoidRootPart.Position - eye.Model.PrimaryPart.Position).Magnitude
                    if dist <= config.Damage.Bite.Range then
                        humanoid.Health = math.max(0, humanoid.Health - config.Damage.Bite.Damage)
                        eye:RunCallback("OnDamage", LocalPlayer, config.Damage.Bite.Damage, "Bite")
                        if humanoid.Health <= 0 then
                            dead = true
                            eye:RunCallback("OnDeath")
                        end
                    end
                end
            end
        end)
    end
    
    if config.Gone.OpeningTheDoor then
        local latestRoom = workspace.CurrentRooms:FindFirstChild(tostring(game.ReplicatedStorage.GameData.LatestRoom.Value))
        if latestRoom and latestRoom:FindFirstChild("Door") then
            latestRoom.Door.ClientOpen.OnClientEvent:Wait()
            eye:Despawn()
        end
    end
    
    if config.Gone.AFewSeconds.Enabled then
        task.wait(config.Gone.AFewSeconds.Seconds)
        eye:Despawn()
    end
end

getgenv().CustomEyesLib = Module
return Module
