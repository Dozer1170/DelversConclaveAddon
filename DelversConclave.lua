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
        SVDC.spellcasts = {}
    end
end

function f:INSPECT_READY(guid)
    if DC.inspectUnit and UnitGUID(DC.inspectUnit) == guid then
        DC.doHeroicPlayerCheckOnUnit(DC.inspectUnit)
    end
end

----------------------------- Slash Commands -------------------------------------

SLASH_DC1 = "/dc"
SlashCmdList["DC"] = function(msg)
    if msg == "heroiccheck" then
        NotifyInspect("target")
        DC.inspectUnit = GetUnitName("target")
    elseif msg == "attendance" then
        DC.doAttendanceRecording()
    elseif msg == "printattendance" then
        DC.printAttendance()
    elseif msg == "printspellcasts" then
        DC.printSpellCastCount()
    else
        print("Provide an argument /dc heroiccheck|attendance|printattendance|printspellcasts")
    end
end

---------------------------------- Heroic Check ----------------------------------------------

function DC.doHeroicPlayerCheckOnUnit(unit)
    local name = GetUnitName(unit, false)
    print("Heroic Roster Check for "..name)
    DC.checkBuffs(unit)
    DC.checkAttendance(name)
    DC.checkItemLevel(unit)
end

function DC.checkBuffs(unit)
    --local mainHandEnhanced = InventoryUtil.ItemHasEnhancement(unit, "MainHandSlot")
    local hasVeiledAugment = AuraUtils.AuraExists("Veiled Augmentation", unit, "PLAYER|HELPFUL")
    local hasFlask = AuraUtils.AuraExists("Spectral Flask of Power", unit, "PLAYER|HELPFUL")
    local hasFood = AuraUtils.AuraExists("Well Fed", unit, "PLAYER|HELPFUL")
    local hasBuffs = hasVeiledAugment and hasFlask and hasFood
    print("Buffs: "..DC.boolToYesNo(hasBuffs))
    if (hasBuffs == false) then
        if (hasVeiledAugment == false) then
            print("  Missing Veiled Augment Rune")
        end
        if (hasFlask == false) then
            print("  Missing Flask")
        end
        if (hasFood == false) then
            print("  Missing Food")
        end
    end
end

function DC.checkAttendance(name)
    local requiredAttendance = 2
    local hasEnoughAttendance = SVDC.attendance[name] ~= nil and SVDC.attendance[name] >= requiredAttendance
    print("Attendance: "..DC.boolToYesNo(hasEnoughAttendance))
    if (hasEnoughAttendance == false) then
        local attendanceAmount = 0
        if (SVDC.attendance[name] ~= nil) then
            attendanceAmount = SVDC.attendance[name]
        end
        print("  Attendance Progress: "..attendanceAmount.."/"..requiredAttendance)
    end
end

function DC.checkItemLevel(unit)
    local minILvlForHeroic = 226
    local averageItemLevel = InventoryUtil.AverageItemLevel(unit)
    local hasHighEnoughItemLevel = averageItemLevel >= minILvlForHeroic
    print("Item Level: "..DC.boolToYesNo(hasHighEnoughItemLevel))
    if (hasHighEnoughItemLevel == false) then
        print("Average item level "..averageItemLevel.."/"..minILvlForHeroic)
    end
end

----------------------------------- Attendance -----------------------------------------------

function DC.doAttendanceRecording()
    for i = 1, 40 do
        name = GetRaidRosterInfo(i)
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
    print("Attendance")
    for name, numAttendance in pairs(SVDC.attendance) do
        print(name..": "..numAttendance)
    end
end

--------------------------------------- Spellcasts -------------------------------------------

function DC.unitSpellcastSucceeded(unit, spellName, spellId)
    local unitName = UnitName(unit)
    if spellName == "Healthstone" then
        print(unitName.." used a healthstone")
        DC.increaseSpellCastCount(unitName, spellName)
    end

    local spiritualHealingPotion = 307192
    local phialOfSerenityPurifySoul = 323436
    if spellId == spiritualHealingPotion or spellId == phialOfSerenityPurifySoul then
        print(unitName.." used a healing potion")
        DC.increaseSpellCastCount(unitName, spellName)
    end

    local agilityPot = 307159
    local strengthPot = 307164
    local intPot = 307162
    local phantomFirePot = 307495
    if spellId == agilityPot or spellId == strengthPot or spellId == intPot or spellId == phantomFirePot then
        print(unitName.." used a DPS pot")
        DC.increaseSpellCastCount(unitName, spellName)
    end

    local manaPot = 307193
    local spiritualClarityPot = 307161
    if spellId == manaPot or spellId == spiritualClarityPot then
        print(unitName.." used a mana pot")
        DC.increaseSpellCastCount(unitName, spellName)
    end
end

function DC.increaseSpellCastCount(unitName, spellName)
    if SVDC.spellcasts[unitName] == nil then
        SVDC.spellcasts[unitName] = {}
    end
    if SVDC.spellcasts[unitName][spellName] == nil then
        SVDC.spellcasts[unitName][spellName] = 0
    end

    SVDC.spellcasts[unitName][spellName] = SVDC.spellcasts[unitName][spellName] + 1
end

function DC.printSpellCastCount()
    for unitName, castsTable in pairs(SVDC.spellcasts) do
        local unitSpellcastStr = unitName..": "
        for spellName, count in pairs(castsTable) do
            unitSpellcastStr = unitSpellcastStr..spellName.."["..count.."] "
        end
        print(unitSpellcastStr)
    end
end

---------------------------------- Inventory Updated -----------------------------------------

function DC.inventoryUpdated(unit)
    local unitName = UnitName(unit)
end

--------------------------------------- Utils -------------------------------------------------

function DC.boolToYesNo(bool)
    if bool then
        return "YES"
    else
        return "NO"
    end
end

