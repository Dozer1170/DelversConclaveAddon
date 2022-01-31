---
--- Created by Gartetasa
--- DateTime: 01/12/2022 9:42 AM
---

-------------------------------- Constants --------------------------------------

local UNIT_INVENTORY_CHANGED = "UNIT_INVENTORY_CHANGED"
local UNIT_SPELLCAST_SUCCEEDED = "UNIT_SPELLCAST_SUCCEEDED"
local ADDON_LOADED = "ADDON_LOADED"
local INSPECT_READY = "INSPECT_READY"

-------------------------------- Variables ----------------------------------------

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

function f:UNIT_SPELLCAST_SUCCEEDED(unit, _, spellId)
    DC.unitSpellcastSucceeded(unit, spellId)
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
        print("-------------------------------------")
        DC.doAttendanceRecording()
        print("-------------------------------------")
    elseif msg == "printattendance" then
        print("-------------------------------------")
        DC.printAttendance()
        print("-------------------------------------")
    elseif msg == "clearspellcasts" then
        print("-------------------------------------")
        DC.clearSpellcasts()
        print("-------------------------------------")
    elseif msg == "printspellcasts" then
        print("-------------------------------------")
        DC.printSpellCastCount()
        print("-------------------------------------")
    else
        print("Provide an argument /dc heroiccheck|attendance|printattendance|printspellcasts")
    end
end

---------------------------------- Heroic Check ----------------------------------------------

function DC.doHeroicPlayerCheckOnUnit(unit)
    print("-------------------------------------")
    local name = GetUnitName(unit, false)
    print("Heroic Roster Check for "..name)
    DC.checkBuffs(unit)
    DC.checkAttendance(name)
    DC.checkItemLevel(unit)
    print("-------------------------------------")
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
    print("Recording attendance...")
    for i = 1, 40 do
        name, _, _, _, _, _, _, _, _, _, _ = GetRaidRosterInfo(i)
        if name ~= nil then
            if SVDC.attendance[name] then
                SVDC.attendance[name] = SVDC.attendance[name] + 1
            else
                SVDC.attendance[name] = 1
            end
            print(name..": "..SVDC.attendance[name])
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

DC.lastSpellcastUnitName = ""
DC.lastSpellcastSpellId = 0

function DC.unitSpellcastSucceeded(unit, spellId)
    guildName, _, _ = GetGuildInfo(unit);
    if guildName ~= "Delvers Conclave" then
        return
    end

    local unitName = UnitName(unit)
    -- Prevent duplicate entries, sometimes the same spell triggers this method twice
    if DC.lastSpellcastUnitName == unitName and DC.lastSpellcastSpellId == spellId then
        return
    else
        DC.lastSpellcastUnitName = unitName
        DC.lastSpellcastSpellId = spellId
    end

    local healthstone = 6262
    if spellId == healthstone then
        print(unitName.." used a healthstone")
        DC.increaseSpellCastCount(unitName, "Healthstone")
    end

    local spiritualHealingPotion = 307192
    local phialOfSerenityPurifySoul = 323436
    if spellId == spiritualHealingPotion or spellId == phialOfSerenityPurifySoul then
        print(unitName.." used a healing potion")
        DC.increaseSpellCastCount(unitName, "Healing Potion")
    end

    local agilityPot = 307159
    local strengthPot = 307164
    local intPot = 307162
    local phantomFirePot = 307495
    if spellId == agilityPot or spellId == strengthPot or spellId == intPot or spellId == phantomFirePot then
        print(unitName.." used a DPS pot")
        DC.increaseSpellCastCount(unitName, "DPS Pot")
    end

    local manaPot = 307193
    local spiritualClarityPot = 307161
    if spellId == manaPot or spellId == spiritualClarityPot then
        print(unitName.." used a mana pot")
        DC.increaseSpellCastCount(unitName, "Mana Pot")
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
    print("Spellcasts")
    local sortedArray = {}
    for n in pairs(SVDC.spellcasts) do table.insert(sortedArray, n) end
    table.sort(sortedArray)

    for i, unitName in ipairs(sortedArray) do
        local unitSpellcastStr = unitName..": "
        local castsTable = SVDC.spellcasts[unitName]
        for spellName, count in pairs(castsTable) do
            unitSpellcastStr = unitSpellcastStr..spellName.."["..count.."] "
        end
        print(unitSpellcastStr)
    end
end

function DC.clearSpellcasts()
    print "Clearing spellcasts"
    SVDC.spellcasts = {}
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

