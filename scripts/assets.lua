local mod = mod_loader.mods[modApi.currentMod]
local resourcePath = mod.resourcePath

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