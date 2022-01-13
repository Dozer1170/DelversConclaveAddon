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

        print("Could not find aura on unit")
    end
end

function AuraUtils.AuraExists(auraName, unit, filter)
    name, rank, icon, count, debuffType, duration = AuraUtils.FindAuraByName(auraName, unit, filter)

    return duration > 0
end