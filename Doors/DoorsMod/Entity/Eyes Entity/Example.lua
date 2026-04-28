local CustomEyes = loadstring(game:HttpGet("https://raw.githubusercontent.com/arkanzulfadliputra-oss/Mod-ScriptGaming/refs/heads/main/Doors/DoorsMod/Entity/Eyes%20Entity/Source.lua"))()

local eyes = CustomEyes:Create({
    Entity = {
        Name = "Eyes",
        Asset = "rbxassetid://16992473288"
    },
    Damage = {
        Looking = {
            Enabled = true,
            Damage = 10,
            Range = 30
        },
        Bite = {
            Enabled = false,
            Damage = 15,
            Range = 40,
            Interval = 1
        },
        Lighter = {
            Enabled = false,
            SafeItem = "Lighter"
        }
    },
    Gone = {
        OpeningTheDoor = true,
        A Few Seconds = {
            Enabled = false,
            Seconds = 10
        }
    }
})

eyes:SetCallback("OnSpawned", function()
    print("✅ Eyes Spawned!")
end)

eyes:SetCallback("OnDamage", function(player, damage, source)
    print("💔 take damage", damage, "from", source)
end)

eyes:SetCallback("OnDeath", function()
    print("💀 Player Dead!")
end)

eyes:Run()
