-- GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})


-- local UIAnim = require "widgets/uianim"

-- TUNING.WX78_MAXELECTRICCHARGE=12

-- TUNING.WX78_MOVESPEED_CHIPBOOSTS={0.00, 0.25, 0.40, 0.50, 0.55, 0.58, 0.60}


-- local OnUpgradeModulesListDirty = function(inst)
--     if inst._parent ~= nil then
--         local module1 = inst.upgrademodules[1]:value()
--         local module2 = inst.upgrademodules[2]:value()
--         local module3 = inst.upgrademodules[3]:value()
--         local module4 = inst.upgrademodules[4]:value()
--         local module5 = inst.upgrademodules[5]:value()
--         local module6 = inst.upgrademodules[6]:value()
--         local module7 = inst.upgrademodules[7]:value()
--         local module8 = inst.upgrademodules[8]:value()
--         local module9 = inst.upgrademodules[9]:value()
--         local module10 = inst.upgrademodules[10]:value()
--         local module11 = inst.upgrademodules[11]:value()
--         local module12 = inst.upgrademodules[12]:value()

--         if module1 == 0 and module2 == 0 and module3 == 0 and module4 == 0 and module5 == 0 and module6 == 0 and module7 == 0 and module8 == 0 and module9 == 0 and module10 == 0 and module11 == 0 and module12 == 0 then
--             inst._parent:PushEvent("upgrademoduleowner_popallmodules")
--         else
--             inst._parent:PushEvent("upgrademodulesdirty", {module1, module2, module3, module4, module5, module6, module7, module8, module9, module10, module11, module12})
--         end
--     end
-- end

-- AddPrefabPostInit("player_classified",function(inst)
-- 	for i=7,12,1 do
-- 		table.insert(inst.upgrademodules,net_smallbyte(inst.GUID, "upgrademodules.mods"..i, "upgrademoduleslistdirty"))
-- 	end

-- 	if not TheWorld.ismastersim then
-- 		inst.event_listeners["upgrademoduleslistdirty"]={}
-- 	    inst.event_listening["upgrademoduleslistdirty"]={}
-- 		inst:ListenForEvent("upgrademoduleslistdirty", OnUpgradeModulesListDirty)
-- 	end
-- end)

-- AddClassPostConstruct("widgets/upgrademodulesdisplay",function(self, ...)
--     for i = 1, 6 do
-- 	    local chip_object = self:AddChild(UIAnim())
-- 	    chip_object:GetAnimState():SetBank("status_wx")
-- 	    chip_object:GetAnimState():SetBuild("status_wx")
-- 	    chip_object:GetAnimState():AnimateWhilePaused(false)

-- 	    chip_object:GetAnimState():Hide("plug_on")
-- 	    chip_object._power_hidden = true

-- 	    chip_object:MoveToBack()
-- 	    chip_object:Hide()

-- 	    table.insert(self.chip_objectpool, chip_object)
--     end

--     for i,v in ipairs(self.chip_objectpool) do
--     	v:SetPosition(0,-60)
--     end

--     self.battery_frame:SetPosition(0,165)


-- end)

--  AddClassPostConstruct("widgets/secondarystatusdisplays",function(self, ...)     
--  	if self.upgrademodulesdisplay then
--  		self.upgrademodulesdisplay:SetPosition(self.column1,-200)
--  	end

--  end)

--  local function OnAllUpgradeModulesRemoved(inst)
--     SpawnPrefab("wx78_big_spark"):AlignToTarget(inst)

--     inst:PushEvent("upgrademoduleowner_popallmodules")

--     if inst.player_classified ~= nil then
--         for i=1,12,1 do
--         	inst.player_classified.upgrademodules[i]:set(0)
--         end
--     end
-- end

--  AddPrefabPostInit("wx78",function(inst)
--  	if TheWorld.ismastersim then
-- 	 	inst:DoTaskInTime(.1,function()
-- 	 		inst.components.upgrademoduleowner.onallmodulespopped = OnAllUpgradeModulesRemoved
-- 	 	end)
--  	end
--  end)





