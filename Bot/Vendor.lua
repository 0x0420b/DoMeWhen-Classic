local DMW = DMW
DMW.Bot.Vendor = {}
local Vendor = DMW.Bot.Vendor
local Navigation = DMW.Bot.Navigation
local Grindbot = DMW.Bot.Grindbot
local Log = DMW.Bot.Log
local TaskDone = false

-- ETA: 2020
local ItemSaveList = {'Black Pearl', 'Golden Pearl'}

local slots = {
	"RangedSlot",
	"SecondaryHandSlot",
	"MainHandSlot",
	"FeetSlot",
	"LegsSlot",
	"HandsSlot",
	"WristSlot",
	"WaistSlot",
	"ChestSlot",
	"ShoulderSlot",
	"HeadSlot"
}

local Bools = {
    Interacted = false,
    Selling = false,
    BuyingFood = false,
    BuyingWater = false,
    Talking = false,
    Repairing = false
}

--//Global functions.
function SetDurabilityVendor()
    local Target = DMW.Player.Target
    if Target then
        DMW.Settings.profile.Grind.RepairVendorX, DMW.Settings.profile.Grind.RepairVendorY, DMW.Settings.profile.Grind.RepairVendorZ = Target.PosX, Target.PosY, Target.PosZ
        DMW.Settings.profile.Grind.RepairVendorName = Target.Name
        Log:DebugInfo('Repair vendor has been set.')
    else
        DMW.Settings.profile.Grind.RepairVendorX, DMW.Settings.profile.Grind.RepairVendorY, DMW.Settings.profile.Grind.RepairVendorZ = nil, nil, nil
        DMW.Settings.profile.Grind.RepairVendorName = ''
        Log:DebugInfo('Repair vendor has been cleared (No Target)')
    end
end

function SetFoodVendor()
    local Target = DMW.Player.Target
    if Target then
        DMW.Settings.profile.Grind.FoodVendorX, DMW.Settings.profile.Grind.FoodVendorY, DMW.Settings.profile.Grind.FoodVendorZ = Target.PosX, Target.PosY, Target.PosZ
        DMW.Settings.profile.Grind.FoodVendorName = Target.Name
        Log:DebugInfo('Food vendor has been set.')
    else
        DMW.Settings.profile.Grind.FoodVendorX, DMW.Settings.profile.Grind.FoodVendorY, DMW.Settings.profile.Grind.FoodVendorZ = nil, nil, nil
        DMW.Settings.profile.Grind.FoodVendorName = ''
        Log:DebugInfo('Food vendor has been cleared (No Target)')
    end
end
--Global functions//

function Vendor:TaskDone()
    return TaskDone
end

function Vendor:CanSell(maxrarity)
    for BagID = 0, 4 do
        for BagSlot = 1, GetContainerNumSlots(BagID) do
            CurrentItemLink = GetContainerItemLink(BagID, BagSlot)
            if CurrentItemLink then
                name, void, Rarity, void, void, itype, void, void, void, void, ItemPrice = GetItemInfo(CurrentItemLink)
                if  name ~= 'Golden Pearl' and name ~= 'Black Pearl' and Rarity <= maxrarity and itype ~= "Consumable" and itype ~= "Container" and ItemPrice > 0 then
                    return true
                end
            end
        end
    end
    return false
end

function Vendor:SellAll(maxrarity)
    for BagID = 0, 4 do
        for BagSlot = 1, GetContainerNumSlots(BagID) do
            CurrentItemLink = GetContainerItemLink(BagID, BagSlot)
            if CurrentItemLink then
                name, void, Rarity, void, void, itype, void, void, void, void, ItemPrice = GetItemInfo(CurrentItemLink)
                if name ~= 'Golden Pearl' and name ~= 'Black Pearl' and Rarity <= maxrarity and itype ~= "Consumable" and itype ~= "Container" and ItemPrice > 0 then
                    UseContainerItem(BagID, BagSlot)
                end
            end
        end
    end
end

function Vendor:BuyItemWithName(name, count)
    local LoopCount = 0
    if count > 20 then
        LoopCount = Round(count / 20)
    else
        LoopCount = 0
    end

    if LoopCount > 0 then
        for i=1,GetMerchantNumItems() do 
            local l=GetMerchantItemLink(i) 
            if l then
                if l:find(name) then
                    for d = 1, LoopCount do
                        BuyMerchantItem(i, 20)
                    end
                end 
            end
        end
        return true
    else
        for i=1,GetMerchantNumItems() do 
            local l=GetMerchantItemLink(i) 
            if l then
                if l:find(name) then
                    BuyMerchantItem(i, count)
                    return true
                end 
            end
        end
    end
end

function Vendor:GetVendor(vendorname)
    for _, Unit in pairs(DMW.Units) do
        if Unit.Name == vendorname then
            return Unit.Pointer
        end
    end
end

function Vendor:GetVendorOption()
    local _,one,_,two,_,three,_,four,_,five = GetGossipOptions()
    if one == "vendor" then
        return 1
    elseif two == "vendor" then
        return 2
    elseif three == "vendor" then
        return 3
    elseif four == "vendor" then
        return 4
    elseif five == "vendor" then
        return 5
    else
        --- If we did not get a valid option first time return a totally shit one so we can try again.
        return 999
    end
end

function Vendor:GetDurability()
    local totalDurability = 100

	for _, value in pairs(slots) do
		local slot = GetInventorySlotInfo(value)
		local current, max = GetInventoryItemDurability(slot)

		if current then
			if ((current / max) * 100) < totalDurability then
				totalDurability = (current / max) * 100
			end
		end
    end
    
    return totalDurability
end

function Vendor:DoTask()
    local RepairVendorX, RepairVendorY, RepairVendorZ = DMW.Settings.profile.Grind.RepairVendorX, DMW.Settings.profile.Grind.RepairVendorY, DMW.Settings.profile.Grind.RepairVendorZ
    local FoodVendorX, FoodVendorY, FoodVendorZ = DMW.Settings.profile.Grind.FoodVendorX, DMW.Settings.profile.Grind.FoodVendorY, DMW.Settings.profile.Grind.FoodVendorZ
    local FoodVendorName = DMW.Settings.profile.Grind.FoodVendorName
    local RepairVendorName = DMW.Settings.profile.Grind.RepairVendorName
    local BuyFood = DMW.Settings.profile.Grind.BuyFood
    local BuyWater = DMW.Settings.profile.Grind.BuyWater
    local RepairPercent = DMW.Settings.profile.Grind.RepairPercent
    local FoodName = DMW.Settings.profile.Grind.FoodName
    local WaterName = DMW.Settings.profile.Grind.WaterName
    local MaxRarity = DMW.Settings.profile.Grind.MaximumVendorRarity - 1
    local FoodCount = DMW.Settings.profile.Grind.FoodAmount
    local WaterCount = DMW.Settings.profile.Grind.WaterAmount

    local NeedWaterCount = WaterCount - GetItemCount(WaterName)
    local NeedFoodCount = FoodCount - GetItemCount(FoodName)

    -- These are actual unit objects.
    local RepairNPC = self:GetVendor(RepairVendorName)
    local FoodNPC = self:GetVendor(FoodVendorName)

    if RepairVendorName == '' then Log:DebugInfo('Set Repair Vendor With /DMW Repair') return end
    if (BuyFood or BuyWater) and FoodVendorName == '' then Log:DebugInfo('Set Food Vendor with /DMW Food') return end

    if self:CanSell(MaxRarity) or self:GetDurability() < RepairPercent then
        -- Go sell and repair at repair vendor if either we have something to sell or we are below durability threshold
        if GetDistanceBetweenPositions(DMW.Player.PosX, DMW.Player.PosY, DMW.Player.PosZ, RepairVendorX, RepairVendorY, RepairVendorZ) >= 5 then
            -- Walk to vendor if we arent close.
            Navigation:MoveTo(RepairVendorX, RepairVendorY, RepairVendorZ)
            return
        else
            -- We are close to vendor, do shit.
            if MerchantFrame:IsVisible() and (self:CanSell(MaxRarity) or self:GetDurability() <= RepairPercent) and not Bools.Selling then
                if self:GetDurability() < 100 and not Bools.Repairing then RepairAllItems() Bools.Repairing = true C_Timer.After(0.5, function() Bools.Repairing = false end) end
                self:SellAll(MaxRarity) Bools.Selling = true
                C_Timer.After(0.5, function() Bools.Selling = false end)
            end

            if GossipFrame:IsVisible() and not Bools.Talking then
                SelectGossipOption(self:GetVendorOption()) Bools.Talking = true
                C_Timer.After(2, function() Bools.Talking = false GossipFrameCloseButton:Click() end)
            end

            if not MerchantFrame:IsVisible() and not GossipFrame:IsVisible() and not Bools.Interacted and RepairNPC and not DMW.Player.Moving then
                InteractUnit(RepairNPC) Bools.Interacted = true
                C_Timer.After(1, function() Bools.Interacted = false end)
            end
        end
        return
    end

    if BuyFood and NeedFoodCount >= 10 then
        -- We need to buy food
        if GetDistanceBetweenPositions(DMW.Player.PosX, DMW.Player.PosY, DMW.Player.PosZ, FoodVendorX, FoodVendorY, FoodVendorZ) >= 5 then
            -- Walk to vendor if we arent close.
            Navigation:MoveTo(FoodVendorX, FoodVendorY, FoodVendorZ)
            return
        else
            -- We are close to vendor, do shit.
            if MerchantFrame:IsVisible() and NeedFoodCount >= 10 and not Bools.BuyingFood then
                self:BuyItemWithName(FoodName, NeedFoodCount) Bools.BuyingFood = true C_Timer.After(15, function() Bools.BuyingFood = false end)
            end

            if GossipFrame:IsVisible() and not Bools.Talking then
                SelectGossipOption(self:GetVendorOption()) Bools.Talking = true
                C_Timer.After(2, function() Bools.Talking = false GossipFrameCloseButton:Click() end)
            end

            if not MerchantFrame:IsVisible() and not GossipFrame:IsVisible() and not Bools.Interacted and FoodNPC and not DMW.Player.Moving then
                InteractUnit(FoodNPC) Bools.Interacted = true
                C_Timer.After(1, function() Bools.Interacted = false end)
            end
        end
        return
    end

    if BuyWater and NeedWaterCount >= 10 then
        -- We need to buy water
        if GetDistanceBetweenPositions(DMW.Player.PosX, DMW.Player.PosY, DMW.Player.PosZ, FoodVendorX, FoodVendorY, FoodVendorZ) >= 5 then
            -- Walk to vendor if we arent close.
            Navigation:MoveTo(FoodVendorX, FoodVendorY, FoodVendorZ)
            return
        else
            -- We are close to vendor, do shit.
            if MerchantFrame:IsVisible() and NeedWaterCount >= 10 and not Bools.BuyingWater then
                self:BuyItemWithName(WaterName, NeedWaterCount) Bools.BuyingWater = true C_Timer.After(15, function() Bools.Buying = falseWater end)
            end

            if GossipFrame:IsVisible() and not Bools.Talking then
                SelectGossipOption(self:GetVendorOption()) Bools.Talking = true
                C_Timer.After(2, function() Bools.Talking = false GossipFrameCloseButton:Click() end)
            end

            if not MerchantFrame:IsVisible() and not GossipFrame:IsVisible() and not Bools.Interacted and FoodNPC and not DMW.Player.Moving then
                InteractUnit(FoodNPC) Bools.Interacted = true
                C_Timer.After(1, function() Bools.Interacted = false end)
            end
        end
        return
    end

    -- If we reach this part then we have everything.
    if not TaskDone then Log:NormalInfo('Vendor run complete.') TaskDone = true end

end

