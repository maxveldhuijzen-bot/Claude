--[[
	Codes — redeemable once per player.

	`coinsAsRebirthFraction` keeps a code useful whether it is redeemed on day
	one or at rebirth 30. Expired codes can stay in the table with active=false
	so the redeem UI can say "expired" instead of "invalid".
]]

return {
	RELEASE = {
		active = true,
		reward = { coinsAsRebirthFraction = 0.4, prisms = 2 },
		note = "Launch day, thanks for playing.",
	},
	AURAFARM = {
		active = true,
		reward = { coinsAsRebirthFraction = 0.25 },
	},
	PRISM = {
		active = true,
		reward = { prisms = 5 },
	},
	LUCKY = {
		active = true,
		reward = { boost = { id = "code_luck", name = "x2 Luck", luckMult = 2, duration = 1800 } },
	},
	SPEEDRUN = {
		active = true,
		reward = { boost = { id = "code_2x", name = "x2 Aura", auraMult = 2, duration = 1200 } },
	},
	UPDATE1 = {
		active = false,
		reward = { coinsAsRebirthFraction = 0.2 },
		note = "Expired.",
	},
}
