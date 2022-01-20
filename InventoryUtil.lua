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
    local totalItems = 0

    for slot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do -- For every slot,
        if slot ~= INVSLOT_BODY and slot ~= INVSLOT_TABARD then -- If this isn't the shirt/tabard slot,
            local link = GetInventoryItemLink(unit, slot) -- Get the ID of the item in this slot
            if link then -- If we have an item in this slot,
                totalItems = totalItems + 1
                local itemName, _, _, _, _, _, _, _, itemEquipLoc = GetItemInfo(link) -- Get the item's ilvl and equip location
                local effectiveIlvl, _, _ = GetDetailedItemLevelInfo(link)
                totalIlvl = totalIlvl + effectiveIlvl -- Add it to the total

                --print("Item "..itemName.." effective level "..effectiveIlvl.." Current Total: "..totalIlvl)
            end
        end
    end

    return totalIlvl / totalItems -- Return the average
end