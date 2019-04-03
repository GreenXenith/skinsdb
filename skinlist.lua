local skins_dir_list = minetest.get_dir_list(skins.modpath.."/textures")

for _, fn in pairs(skins_dir_list) do
	local name, sort_id, assignment, is_preview, playername
	local nameparts = {
		fn:match("^%w+"),
		fn:gsub("^%w+_", ""):gsub("%.%w+$", ""),
		fn:match("%w+$"),
	}

	-- check allowed prefix and file extension
	if (nameparts[1] == 'player' or nameparts[1] == 'character') and
			nameparts[#nameparts]:lower() == 'png' then

		-- cut filename extension
		table.remove(nameparts, #nameparts)

		-- check preview suffix
		if nameparts[#nameparts] == 'preview' then
			is_preview = true
			table.remove(nameparts, #nameparts)
		end

		-- Build technically skin name
		name = table.concat(nameparts, '_')

		-- Handle metadata from file name
		if not is_preview then
			-- Get player name
			if nameparts[1] == "player" then
				playername = nameparts[2]
				table.remove(nameparts, 1)
				sort_id = 0
			else
				sort_id = 5000
			end

			-- Get sort index
			if tonumber(nameparts[#nameparts]) then
				sort_id = sort_id + nameparts[#nameparts]
			end
		end

		local skin_obj = skins.get(name) or skins.new(name)
		if is_preview then
			skin_obj:set_preview(fn)
		else
			skin_obj:set_texture(fn)
			skin_obj:set_meta("_sort_id", sort_id)
			if playername then
				skin_obj:set_meta("assignment", "player:"..playername)
				skin_obj:set_meta("playername", playername)
			end
			local file = io.open(skins.modpath.."/textures/"..fn, "r")
			skin_obj:set_meta("format", skins.get_skin_format(file))
			file:close()
			file = io.open(skins.modpath.."/meta/"..name..".txt", "r")
			if file then
				local data = string.split(file:read("*all"), "\n", 3)
				file:close()
				skin_obj:set_meta("name", data[1])
				skin_obj:set_meta("author", data[2])
				skin_obj:set_meta("license", data[3])
			else
				-- remove player / character prefix if further naming given
				if nameparts[2] and not tonumber(nameparts[2]) then
					table.remove(nameparts, 1)
				end
				skin_obj:set_meta("name", table.concat(nameparts, ' '))
			end
		end
	end
end

-- (obsolete) get skinlist. If assignment given ("mod:wardrobe" or "player:bell07") select skins matches the assignment. select_unassigned selects the skins without any assignment too
function skins.get_skinlist(assignment, select_unassigned)
	minetest.log("deprecated", "skins.get_skinlist() is deprecated. Use skins.get_skinlist_for_player() instead")
	local skinslist = {}
	for _, skin in pairs(skins.meta) do
		if not assignment or
				assignment == skin:get_meta("assignment") or
				(select_unassigned and skin:get_meta("assignment") == nil) then
			table.insert(skinslist, skin)
		end
	end
	table.sort(skinslist, function(a,b) return a:get_meta("_sort_id") < b:get_meta("_sort_id") end)
	return skinslist
end

-- Get skinlist for player. If no player given, public skins only selected
function skins.get_skinlist_for_player(playername)
	local skinslist = {}
	for _, skin in pairs(skins.meta) do
		if skin:is_applicable_for_player(playername) and skin:get_meta("in_inventory_list") ~= false then
			table.insert(skinslist, skin)
		end
	end
	table.sort(skinslist, function(a,b) return a:get_meta("_sort_id") < b:get_meta("_sort_id") end)
	return skinslist
end

-- Get skinlist selected by metadata
function skins.get_skinlist_with_meta(key, value)
	assert(key, "key parameter for skins.get_skinlist_with_meta() missed")
	local skinslist = {}
	for _, skin in pairs(skins.meta) do
		if skin:get_meta(key) == value then
			table.insert(skinslist, skin)
		end
	end
	table.sort(skinslist, function(a,b) return a:get_meta("_sort_id") < b:get_meta("_sort_id") end)
	return skinslist
end
