--[[ TableUtil — small helpers used by the data and config layers. ]]

local TableUtil = {}

function TableUtil.deepCopy(source)
	if type(source) ~= "table" then
		return source
	end
	local copy = {}
	for key, value in pairs(source) do
		copy[key] = TableUtil.deepCopy(value)
	end
	return copy
end

--- Fills in any key present in `template` but missing from `target`.
--- Returns true when something was added (used by save-data migrations).
function TableUtil.reconcile(target, template)
	local changed = false
	for key, value in pairs(template) do
		if target[key] == nil then
			target[key] = TableUtil.deepCopy(value)
			changed = true
		elseif type(value) == "table" and type(target[key]) == "table" then
			-- Arrays are player data (pets, quests); don't merge template rows in.
			if next(value) == nil or type(next(value)) == "string" then
				if TableUtil.reconcile(target[key], value) then
					changed = true
				end
			end
		end
	end
	return changed
end

function TableUtil.count(source)
	local n = 0
	for _ in pairs(source) do
		n += 1
	end
	return n
end

function TableUtil.keys(source)
	local out = {}
	for key in pairs(source) do
		table.insert(out, key)
	end
	return out
end

function TableUtil.shuffle(list, random)
	random = random or Random.new()
	for i = #list, 2, -1 do
		local j = random:NextInteger(1, i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

--- Stable ordered iteration over a dictionary, sorted by a comparator.
function TableUtil.sortedPairs(source, comparator)
	local keys = TableUtil.keys(source)
	table.sort(keys, comparator)
	local index = 0
	return function()
		index += 1
		local key = keys[index]
		if key ~= nil then
			return key, source[key]
		end
		return nil
	end
end

return TableUtil
