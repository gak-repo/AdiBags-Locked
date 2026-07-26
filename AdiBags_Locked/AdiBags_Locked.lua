--[[
AdiBags_Outfutter - Adds Outfitter set filters to AdiBags.
Copyright 2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]]

-- AdiBags_Locked - Adds a custom 'Locked' filter to AdiBags.
-- Filter items into a custom 'Locked' section using click modifiers.
-- Interaction: STRICT Ctrl + Shift + Right-Click to toggle items.

local _, ns = ...

local addon = LibStub('AceAddon-3.0'):GetAddon('AdiBags')

-- Optimization: Pre-compile static English chat string pointers to prevent memory leaks
local CHAT_PREFIX = "|cff33ff99AdiBags_Locked:|r "
local MSG_LOCKED = CHAT_PREFIX .. "Added %s to Locked list."
local MSG_UNLOCKED = CHAT_PREFIX .. "Removed %s from Locked list."
local MSG_CLEARED = CHAT_PREFIX .. "All locked items cleared successfully."
local MSG_USAGE = CHAT_PREFIX .. "Usage: /abl clear or /adibagslocked clear to wipe your locked profile."

-----------------------------------------------------------
-- Filter Setup
-----------------------------------------------------------

local filter = addon:RegisterFilter("LockedFilter", 95, 'AceEvent-3.0')
filter.uiName = "Locked Items"
filter.uiDesc = "Filter items into a custom 'Locked' section using Ctrl+Shift+Right-Click."

function filter:OnInitialize()
	-- Optimized character profile storage mapping
	self.db = addon.db:RegisterNamespace('LockedFilter', {
		char = {
			lockedItems = { ['*'] = false },
		},
	})
	
	SLASH_ADIBAGSLOCKED1 = "/adibagslocked"
	SLASH_ADIBAGSLOCKED2 = "/abl"
	SlashCmdList["ADIBAGSLOCKED"] = function(msg)
		self:HandleSlashCommand(msg)
	end
end

function filter:OnEnable()
	self:HookItemClicks()
	addon:UpdateFilters()
end

function filter:OnDisable()
	addon:UpdateFilters()
end

-----------------------------------------------------------
-- GUI Options Integration (AceConfig-3.0)
-----------------------------------------------------------

-- AdiBags scans for this method to append modules onto its configuration grid.
function filter:GetOptions()
	return {
		-- Cleaned to leave only utility tools; master filter toggling is handled natively by AdiBags
		clearList = {
			type = 'execute',
			name = "Clear Locked Items",
			desc = "Completely purges your character's current locked list data.",
			order = 10,
			func = function()
				self.db.char.lockedItems = { ['*'] = false }
				print(MSG_CLEARED)
				addon:UpdateFilters()
			end,
		},
	}, addon:GetOptionHandler(self, true)
end

-----------------------------------------------------------
-- Filter Logic (O(1) Hash Table Lookup)
-----------------------------------------------------------

function filter:Filter(slotData)
	if not slotData.itemId then return end
	if self.db.char.lockedItems[slotData.itemId] then
		return "Locked"
	end
end

-----------------------------------------------------------
-- Interaction Handling (Strict Right Click Modifier Isolation)
-----------------------------------------------------------

function filter:ToggleItemLock(itemId)
	if not itemId then return end
	
	local _, itemLink = GetItemInfo(itemId)
	if not itemLink then itemLink = "Item [" .. itemId .. "]" end
	
	-- Toggle state in character table map
	local currentState = self.db.char.lockedItems[itemId]
	self.db.char.lockedItems[itemId] = not currentState
	
	if self.db.char.lockedItems[itemId] then
		print(string.format(MSG_LOCKED, itemLink))
	else
		print(string.format(MSG_UNLOCKED, itemLink))
	end
	
	addon:UpdateFilters()
end

function filter:HookItemClicks()
	if self.hooked then return end

	hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", function(self, button)
		-- Strict Modification Isolation: Ignore if NOT RightButton
		if button ~= "RightButton" then return end
		
		-- Explicit Check: Ctrl and Shift MUST be held down, Alt MUST NOT be held down
		if IsShiftKeyDown() and IsControlKeyDown() and not IsAltKeyDown() then
			local bag = self:GetParent():GetID()
			local slot = self:GetID()
			local itemId = GetContainerItemID(bag, slot)
			
			if itemId then
				filter:ToggleItemLock(itemId)
			end
		end
	end)

	self.hooked = true
end

-----------------------------------------------------------
-- Slash Commands
-----------------------------------------------------------

function filter:HandleSlashCommand(msg)
	local cmd = string.lower(msg or "")
	
	if cmd == "clear" or cmd == "reset" then
		self.db.char.lockedItems = { ['*'] = false }
		print(MSG_CLEARED)
		addon:UpdateFilters()
	else
		print(MSG_USAGE)
	end
end
