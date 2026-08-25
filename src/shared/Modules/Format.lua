--[[
	Format — human readable numbers and durations.
	Simulator numbers get astronomically large, so everything the player sees
	goes through here rather than tostring().
]]

local Format = {}

local SUFFIXES = {
	"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No",
	"Dc", "Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod", "Vg",
}

--- 1234 -> "1.23K", 5_400_000 -> "5.40M"
function Format.abbreviate(value)
	if type(value) ~= "number" or value ~= value then
		return "0"
	end

	local sign = value < 0 and "-" or ""
	value = math.abs(value)

	if value < 1000 then
		if value < 100 and value % 1 ~= 0 then
			return sign .. string.format("%.1f", value)
		end
		return sign .. string.format("%d", math.floor(value))
	end

	local index = math.floor(math.log(value, 1000))
	index = math.clamp(index, 1, #SUFFIXES - 1)

	local scaled = value / (1000 ^ index)
	-- Floating point can leave us at 1000.0 of the smaller unit; step up.
	if scaled >= 1000 and index < #SUFFIXES - 1 then
		index += 1
		scaled /= 1000
	end

	local suffix = SUFFIXES[index + 1]
	if scaled >= 100 then
		return string.format("%s%.0f%s", sign, scaled, suffix)
	elseif scaled >= 10 then
		return string.format("%s%.1f%s", sign, scaled, suffix)
	end
	return string.format("%s%.2f%s", sign, scaled, suffix)
end

--- 1234567 -> "1,234,567"
function Format.comma(value)
	local whole = string.format("%d", math.floor(math.abs(value)))
	local out = whole:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	out = out:gsub("^,", "")
	return (value < 0 and "-" or "") .. out
end

--- 3725 -> "1h 2m", 65 -> "1m 5s"
function Format.duration(seconds)
	seconds = math.max(0, math.floor(seconds))
	local days = math.floor(seconds / 86400)
	local hours = math.floor(seconds % 86400 / 3600)
	local minutes = math.floor(seconds % 3600 / 60)
	local secs = seconds % 60

	if days > 0 then
		return string.format("%dd %dh", days, hours)
	elseif hours > 0 then
		return string.format("%dh %dm", hours, minutes)
	elseif minutes > 0 then
		return string.format("%dm %ds", minutes, secs)
	end
	return string.format("%ds", secs)
end

--- 2.5 -> "x2.5"
function Format.multiplier(value)
	if value >= 100 then
		return "x" .. Format.abbreviate(value)
	elseif value % 1 == 0 then
		return string.format("x%d", value)
	end
	return string.format("x%.2f", value)
end

--- 0.235 -> "23.5%"
function Format.percent(fraction, decimals)
	return string.format("%." .. (decimals or 0) .. "f%%", fraction * 100)
end

--- Ordinal suffix for leaderboard ranks: 1 -> "1st"
function Format.ordinal(n)
	local mod100 = n % 100
	if mod100 >= 11 and mod100 <= 13 then
		return n .. "th"
	end
	local endings = { [1] = "st", [2] = "nd", [3] = "rd" }
	return n .. (endings[n % 10] or "th")
end

return Format
