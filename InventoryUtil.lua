InventoryUtil = {}

function InventoryUtil.GetItemInfo(unit, slotName)
    local slotID = GetInventorySlotInfo(slotName)
    local itemLink = GetInventoryItemLink(unit, slotID)
    return GetItemInfo(itemLink)
end

function InventoryUtil.ItemHasEnhancement(unit, slotName)
    itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
    itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expacID, setID, isCraftingReagent
        = GetItemInfo(unit, slotName)

    return true
end

function InventoryUtil.AverageItemLevel(unit)
    local totalIlvl = 0
    local mainHandEquipLoc, offHandEquipLoc

    for slot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do -- For every slot,
        if slot ~= INVSLOT_BODY and slot ~= INVSLOT_TABARD then -- If this isn't the shirt/tabard slot,
            local id = GetInventoryItemID(unit, slot) -- Get the ID of the item in this slot
            if id then -- If we have an item in this slot,
                local _, _, _, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(id) -- Get the item's ilvl and equip location
                totalIlvl = totalIlvl + itemLevel -- Add it to the total

                if slot == INVSLOT_MAINHAND then -- If this is the main or off hand, store the equip location for later use
                    mainHandEquipLoc = itemEquipLoc
                elseif slot == INVSLOT_OFFHAND then
                    offHandEquipLoc = itemEquipLoc
                end
            end
        end
    end

    local numSlots
    if mainHandEquipLoc and offHandEquipLoc then -- The unit has something in both hands, set numSlots to 17
        numSlots = 17
    else -- The unit either has something in one hand or nothing in both hands
        local equippedItemLoc = mainHandEquipLoc or offHandEquipLoc

        local _, class = UnitClass(unit)
        local SPECID_FURY = 72
        local isFury = class == "WARRIOR" and GetInspectSpecialization() == SPECID_FURY

        -- If the user is holding a one-hand weapon, a main-hand weapon or a two-hand weapon as Fury, set numSlots to 17; otherwise set it to 16
        numSlots = (
                equippedItemLoc == "INVTYPE_WEAPON" or
                        equippedItemLoc == "INVTYPE_WEAPONMAINHAND" or
                        (equippedItemLoc == "INVTYPE_2HWWEAPON" and isFury)
        ) and 17 or 16
    end

    return totalIlvl / numSlots -- Return the average
end