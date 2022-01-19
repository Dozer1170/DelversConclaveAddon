AuraUtils = {};

do
    function AuraUtils.FindAuraByName(auraName, unit, filter)
        print("Finding aura "..auraName.." on "..unit)
        for i=1,40 do
            name, rank, icon, count, debuffType, duration = UnitAura(unit, i, filter)
            if name == auraName then
                return name, rank, icon, count, debuffType, duration
            end
        end
    end
end

function AuraUtils.AuraExists(auraName, unit, filter)
    name, rank, icon, count, debuffType, duration = AuraUtils.FindAuraByName(auraName, unit, filter)
    if duration == nil then
        print("Aura "..auraName.." does not exist on "..unit)
        return false
    end

    return duration > 0
end