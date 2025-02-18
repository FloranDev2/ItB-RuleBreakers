local mod = mod_loader.mods[modApi.currentMod]
local resourcePath = mod.resourcePath
local mechPath = resourcePath .."img/mechs/"

------------------
--- TRAIT ICON ---
------------------
modApi:appendAsset("img/combat/icons/icon_grid_mech_trait.png", resourcePath.."img/combat/icons/icon_grid_mech_trait.png")
	Location["combat/icons/icon_grid_mech_trait.png"] = Point(-12, 8)

modApi:appendAsset("img/combat/icons/icon_sawblade_trait.png", resourcePath.."img/combat/icons/icon_sawblade_trait.png")
	Location["combat/icons/icon_sawblade_trait.png"] = Point(-12, 8)


---------------------
--- WEAPONS ICONS ---
---------------------
modApi:appendAsset("img/weapons/truelch_sawblade_launcher.png", resourcePath.."img/weapons/truelch_sawblade_launcher.png")
modApi:appendAsset("img/weapons/truelch_grid_shield.png",       resourcePath.."img/weapons/truelch_grid_shield.png")
modApi:appendAsset("img/weapons/truelch_grid_discharge.png",    resourcePath.."img/weapons/truelch_grid_discharge.png")
modApi:appendAsset("img/weapons/truelch_rift_inducer.png",      resourcePath.."img/weapons/truelch_rift_inducer.png")


-------------------
--- DAMAGE MARK ---
-------------------
modApi:appendAsset("img/combat/icons/icon_swap_impossible.png", resourcePath.."img/combat/icons/icon_swap_impossible.png")
	Location["combat/icons/icon_swap_impossible.png"] = Point(-10, 16)


-------------
--- ANIMS ---
-------------
modApi:appendAsset("img/effects/truelch_anim_sawblade.png", resourcePath.."img/effects/truelch_anim_sawblade.png")
	Location["effects/truelch_anim_sawblade.png"] = Point(0, 0)

ANIMS.truelch_anim_sawblade = Animation:new{
	Image = "effects/truelch_anim_sawblade.png",
	PosX = -17,
	PosY = -5,
	Time = 0.08,
	NumFrames = 1,
}

modApi:appendAsset("img/effects/truelch_anim_sawblade_A.png", resourcePath.."img/effects/truelch_anim_sawblade_A.png")
	Location["effects/truelch_anim_sawblade_A.png"] = Point(0, 0)

ANIMS.truelch_anim_sawblade_A = Animation:new{
	Image = "effects/truelch_anim_sawblade_A.png",
	PosX = -17,
	PosY = -5,
	Time = 0.08,
	NumFrames = 1,
}

modApi:appendAsset("img/effects/truelch_anim_grid_protecc.png", resourcePath.."img/effects/truelch_anim_grid_protecc.png")
	Location["effects/truelch_anim_grid_protecc.png"] = Point(0, 0)

ANIMS.truelch_anim_grid_protecc = Animation:new{
	Image = "effects/truelch_anim_grid_protecc.png",
	PosX = -17,
	PosY = -12,
	Time = 0.08,
	NumFrames = 10,
}


-------------------
--- PROJECTILES ---
-------------------
modApi:appendAsset("img/effects/truelch_sawblade_proj_R.png", resourcePath.."img/effects/truelch_sawblade_proj_R.png")
modApi:appendAsset("img/effects/truelch_sawblade_proj_U.png", resourcePath.."img/effects/truelch_sawblade_proj_U.png")


-------------------------
--- ARTILLERY SHOTUPS ---
-------------------------
modApi:appendAsset("img/effects/truelch_shotup_sawblade.png", resourcePath.."img/effects/truelch_shotup_sawblade.png")

--Deployables (sawblades)
local files = {
	"truelch_sawblade_pawn.png",
	"truelch_sawblade_pawn_a.png",
	"truelch_sawblade_pawn_death.png",
	"truelch_sawblade_pawn_ns.png",

	"truelch_sawblade_A_pawn.png",
	"truelch_sawblade_A_pawn_a.png",
	"truelch_sawblade_A_pawn_death.png",
	"truelch_sawblade_A_pawn_ns.png",
}

local depPath = resourcePath.."img/sawblades/"
for _, file in ipairs(files) do
	modApi:appendAsset("img/units/player/"..file, depPath..file)
end

local a = ANIMS
a.truelch_sawblade =    a.MechUnit:new{ Image = "units/player/truelch_sawblade_pawn.png",       PosX = -11, PosY = 12 }
a.truelch_sawbladea =   a.MechUnit:new{ Image = "units/player/truelch_sawblade_pawn_a.png",     PosX = -11, PosY = 12, NumFrames = 4 }
a.truelch_sawbladed =   a.MechUnit:new{ Image = "units/player/truelch_sawblade_pawn_death.png", PosX = -11, PosY = 12, NumFrames = 1, Loop = false, Time = 0.14 }
a.truelch_sawblade_ns = a.MechIcon:new{ Image = "units/player/truelch_sawblade_pawn_ns.png" }

a.truelch_sawblade_A =    a.MechUnit:new{ Image = "units/player/truelch_sawblade_A_pawn.png",       PosX = -11, PosY = 12 }
a.truelch_sawblade_Aa =   a.MechUnit:new{ Image = "units/player/truelch_sawblade_A_pawn_a.png",     PosX = -11, PosY = 12, NumFrames = 4 }
a.truelch_sawblade_Ad =   a.MechUnit:new{ Image = "units/player/truelch_sawblade_A_pawn_death.png", PosX = -11, PosY = 12, NumFrames = 1, Loop = false, Time = 0.14 }
a.truelch_sawblade_A_ns = a.MechIcon:new{ Image = "units/player/truelch_sawblade_A_pawn_ns.png" }


-------------
--- MECHS ---
-------------
--Sawblade Mech
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
a.mech_sawbladea =        a.MechUnit:new{Image = "units/player/mech_sawblade_a.png",        PosX = -18, PosY =  -7, NumFrames = 4 }
a.mech_sawbladew =        a.MechUnit:new{Image = "units/player/mech_sawblade_w.png",        PosX = -20, PosY =   4 }
a.mech_sawblade_broken =  a.MechUnit:new{Image = "units/player/mech_sawblade_broken.png",   PosX = -20, PosY =  -5 }
a.mech_sawbladew_broken = a.MechUnit:new{Image = "units/player/mech_sawblade_w_broken.png", PosX = -20, PosY =  -5 }
a.mech_sawblade_ns =      a.MechIcon:new{Image = "units/player/mech_sawblade_ns.png" }

--Grid Mech
local files = {
	"mech_grid.png",
	"mech_grid_a.png",
	"mech_grid_w.png",
	"mech_grid_w_broken.png",
	"mech_grid_broken.png",
	"mech_grid_ns.png",
	"mech_grid_h.png"
}

for _, file in ipairs(files) do
	modApi:appendAsset("img/units/player/"..file, mechPath..file)
end

local a = ANIMS
a.mech_grid =         a.MechUnit:new{Image = "units/player/mech_grid.png",          PosX = -20, PosY =  -5 }
a.mech_grida =        a.MechUnit:new{Image = "units/player/mech_grid_a.png",        PosX = -20, PosY = -25, NumFrames = 4 }
a.mech_gridw =        a.MechUnit:new{Image = "units/player/mech_grid_w.png",        PosX = -20, PosY =   4 }
a.mech_grid_broken =  a.MechUnit:new{Image = "units/player/mech_grid_broken.png",   PosX = -20, PosY =  -5 }
a.mech_gridw_broken = a.MechUnit:new{Image = "units/player/mech_grid_w_broken.png", PosX = -20, PosY =  -5 }
a.mech_grid_ns =      a.MechIcon:new{Image = "units/player/mech_grid_ns.png" }

--Dislocation Mech
local files = {
	"mech_dislocation.png",
	"mech_dislocation_a.png",
	"mech_dislocation_w.png",
	"mech_dislocation_w_broken.png",
	"mech_dislocation_broken.png",
	"mech_dislocation_ns.png",
	"mech_dislocation_h.png"
}

for _, file in ipairs(files) do
	modApi:appendAsset("img/units/player/"..file, mechPath..file)
end

local a = ANIMS
a.mech_dislocation =         a.MechUnit:new{Image = "units/player/mech_dislocation.png",          PosX = -17, PosY =  -5 }
a.mech_dislocationa =        a.MechUnit:new{Image = "units/player/mech_dislocation_a.png",        PosX = -17, PosY =  -4, NumFrames = 4 }
a.mech_dislocationw =        a.MechUnit:new{Image = "units/player/mech_dislocation_w.png",        PosX = -17, PosY =   4 }
a.mech_dislocation_broken =  a.MechUnit:new{Image = "units/player/mech_dislocation_broken.png",   PosX = -17, PosY =  -5 }
a.mech_dislocationw_broken = a.MechUnit:new{Image = "units/player/mech_dislocation_w_broken.png", PosX = -17, PosY =  -5 }
a.mech_dislocation_ns =      a.MechIcon:new{Image = "units/player/mech_dislocation_ns.png" }