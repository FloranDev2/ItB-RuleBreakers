local mod = mod_loader.mods[modApi.currentMod]
local resourcePath = mod.resourcePath
local mechPath = resourcePath .."img/mechs/"

--Trait icon
modApi:appendAsset("img/combat/icons/icon_grid_mech_trait.png", resourcePath.."img/combat/icons/icon_grid_mech_trait.png")
	Location["combat/icons/icon_grid_mech_trait.png"] = Point(-12, 8)

modApi:appendAsset("img/combat/icons/icon_sawblade_trait.png", resourcePath.."img/combat/icons/icon_sawblade_trait.png")
	Location["combat/icons/icon_sawblade_trait.png"] = Point(-12, 8)

--Weapons icons
modApi:appendAsset("img/weapons/truelch_sawblade_launcher.png", resourcePath.."img/weapons/truelch_sawblade_launcher.png")
modApi:appendAsset("img/weapons/truelch_grid_shield.png",       resourcePath.."img/weapons/truelch_grid_shield.png")
modApi:appendAsset("img/weapons/truelch_grid_discharge.png",    resourcePath.."img/weapons/truelch_grid_discharge.png")
modApi:appendAsset("img/weapons/truelch_rift_inducer.png",      resourcePath.."img/weapons/truelch_rift_inducer.png")

--Damage mark
modApi:appendAsset("img/combat/icons/icon_resupply.png", resourcePath.."img/combat/icons/icon_resupply.png")
	Location["combat/icons/icon_resupply.png"] = Point(-10, 16)

--Mechs
local files = {
	"mech_sawblade.png",
	"mech_sawblade_a.png",
	"mech_sawblade_w.png",
	"mech_sawblade_w_broken.png",
	"mech_sawblade_broken.png",
	"mech_sawblade_ns.png",
	"mech_sawblade_h.png"
}

for _, file in ipairs(files) do
	modApi:appendAsset("img/units/player/"..file, mechPath..file)
end

local a = ANIMS
a.mech_sawblade =         a.MechUnit:new{Image = "units/player/mech_sawblade.png",          PosX = -20, PosY =  -5 }
a.mech_sawbladea =        a.MechUnit:new{Image = "units/player/mech_sawblade_a.png",        PosX = -20, PosY = -10, NumFrames = 4 }
a.mech_sawbladew =        a.MechUnit:new{Image = "units/player/mech_sawblade_w.png",        PosX = -20, PosY =   4 }
a.mech_sawblade_broken =  a.MechUnit:new{Image = "units/player/mech_sawblade_broken.png",   PosX = -20, PosY =  -5 }
a.mech_sawbladew_broken = a.MechUnit:new{Image = "units/player/mech_sawblade_w_broken.png", PosX = -20, PosY =  -5 }
a.mech_sawblade_ns =      a.MechIcon:new{Image = "units/player/mech_sawblade_ns.png" }