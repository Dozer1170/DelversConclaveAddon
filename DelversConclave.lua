---
--- Created by Gartetasa
--- DateTime: 01/12/2022 9:42 AM
---

-------------------------------- Constants --------------------------------------

local UNIT_INVENTORY_CHANGED = "UNIT_INVENTORY_CHANGED"
local UNIT_SPELLCAST_SUCCEEDED = "UNIT_SPELLCAST_SUCCEEDED"
local ADDON_LOADED = "ADDON_LOADED"
local INSPECT_READY = "INSPECT_READY"

-------------------------------- Globals ----------------------------------------

local SVDC -- Saved variable for saving attendance etc to disk
local DC = {}

----------------------------- Event Registration --------------------------------

local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
f:RegisterEvent(UNIT_INVENTORY_CHANGED)
f:RegisterEvent(UNIT_SPELLCAST_SUCCEEDED)
f:RegisterEvent(ADDON_LOADED)
f:RegisterEvent(INSPECT_READY)

function f:UNIT_INVENTORY_CHANGED(unit)
    DC.inventoryUpdated(unit)
end

function f:UNIT_SPELLCAST_SUCCEEDED(unit, spellName, _, _, spellId)
    DC.unitSpellcastSucceeded(unit, spellName, spellId)
end

function f:ADDON_LOADED()
    if SVDC == nil then
        SVDC = {}
        SVDC.attendance = {}
    end
end

function f:INSPECT_READY(guid)
    if DC.inspectUnit and UnitGUID(DC.inspectUnit) == guid then
        DC.doHeroicPlayerCheckOnUnit(DC.inspectUnit)
    end
end

----------------------------- Slash Commands -------------------------------------

SLASH_DC1 = "/dc"
SlashCmdList["dc"] = function(msg)
    local split = msg.split(' ')
    if split.length <= 1 then
        print("Delvers Conclave: Provide a subcommand (heroiccheck, attendance)")
    end

    local subcommand = split[1]
    if subcommand == "heroiccheck" then
        NotifyInspect("target")
        DC.inspectUnit = GetUnitName("target")
    end

    if subcommand == "attendance" then
        DC.doAttendanceRecording()
    end

    if subcommand == "printattendance" then
        DC.printAttendance()
    end
end

---------------------------------- Heroic Check ----------------------------------------------

function DC.doHeroicPlayerCheckOnUnit(unit)
    local name = GetUnitName(unit, false)

    local hasVeiledAugment = AuraUtil.AuraExists("Veiled Augment Rune", "target", nil)
    local hasFlask = AuraUtil.AuraExists("Spectral Flask of Power", "target", nil)
    local hasFood = AuraUtil.AuraExists("Well Fed", "target", nil)

    --local mainHandEnhanced = InventoryUtil.ItemHasEnhancement(unit, "MainHandSlot")
    local minILvlForHeroic = 226
    local averageItemLevel = InventoryUtil.AverageItemLevel(unit)

    print("Heroic Roster Check for "..name)
    print("Buffs: "..boolToYesNo(hasVeiledAugment and hasFlask and hasFood))
    print("Attendance: "..boolToYesNo(SVDC.attendance[name] ~= nil and SVDC.attendance[name] > 1))
    print("Item Level: "..boolToYesNo(averageItemLevel >= minILvlForHeroic))
end

----------------------------------- Attendance -----------------------------------------------

function DC.doAttendanceRecording()
    for i = 1, 40 do
        name, ... = GetRaidRosterInfo(i)
        if name ~= nil then
            if SVDC.attendance[name] then
                SVDC.attendance[name] = SVDC.attendance[name] + 1
            else
                SVDC.attendance[name] = 1
            end
        end
    end
end

function DC.printAttendance()
    for name, numAttendance in pairs(SVDC.attendance) do
        print(name..": "..numAttendance)
    end
end

--------------------------------------- Spellcasts -------------------------------------------

function DC.unitSpellcastSucceeded(unit, spellName, spellId)
    local unitName = UnitName(unit)
    if spellName == "Healthstone" then
        print(unitName.." used a healthstone")
    end

    local spiritualHealingPotion = 307192
    local phialOfSerenityPurifySoul = 323436
    if spellId == spiritualHealingPotion or spellId == phialOfSerenityPurifySoul then
        print(unitName.." used a healing potion")
    end

    local agilityPot = 307159
    local strengthPot = 307164
    local intPot = 307162
    local phantomFirePot = 307495
    if spellId == agilityPot or spellId == strengthPot or spellId == intPot or spellId == phantomFirePot then
        print(unitName.." used a DPS pot")
    end

    local manaPot = 307193
    local spiritualClarityPot = 307161
    if spellId == manaPot or spellId == spiritualClarityPot then
        print(unitName.." used a mana pot")
    end
end

---------------------------------- Inventory Updated -----------------------------------------

function DC.inventoryUpdated(unit)
    local unitName = UnitName(unit)
    print(unitName.." inventory changed")
end

--------------------------------------- Utils -------------------------------------------------

function DC.boolToYesNo(bool)
    if bool then
        return "YES"
    else
        return "NO"
    end
end

