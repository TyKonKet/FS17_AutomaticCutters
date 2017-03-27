--
-- AutomaticCutters
--
-- @author  TyKonKet
-- @date 22/03/2017
AutoCutter = {};
AutoCutter.name = "AutoCutter";
AutoCutter.debug = AutomaticCutters.debug;
AutoCutter.dir = g_currentModDirectory;

function AutoCutter.prerequisitesPresent(specializations)
    if SpecializationUtil.hasSpecialization(Cutter, specializations) then
        return true;
    else
        return false;
    end
end

function AutoCutter.initSpecialization()
end

function AutoCutter.print(txt1, txt2, txt3, txt4, txt5, txt6, txt7, txt8, txt9)
    if AutoCutter.debug then
        local args = {txt1, txt2, txt3, txt4, txt5, txt6, txt7, txt8, txt9};
        for i, v in ipairs(args) do
            if v then
                print("[" .. AutoCutter.name .. "] -> " .. tostring(v));
            end
        end
    end
end

function AutoCutter:preLoad(savegame)
    AutoCutter.print("AutoCutter:preLoad()");
    self.fruitAhead = false;
    self.extendedCutterTestAreas = {};
    self.doCheckSpeedLimit = Utils.overwrittenFunction(self.doCheckSpeedLimit, AutoCutter.doCheckSpeedLimit)
    self.automaticCutterEnabled = true;
end

function AutoCutter:load(savegame)
    AutoCutter.print(AutoCutter.name .. " loaded on " .. self.typeName);
end

function AutoCutter:postLoad(savegame)
    AutoCutter.print("AutoCutter:postLoad()");
    AutoCutter.loadSamples();
    AutoCutter.updateExtendedTestAreas(self);
    if savegame ~= nil and not savegame.resetVehicles then
        self.automaticCutterEnabled = Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key .. "#automaticCutterEnabled"), self.automaticCutterEnabled);
    end
    self.schemaOverlays = {};
    self.schemaOverlays.overlay = self.schemaOverlay.overlay;
    self.schemaOverlays.overlaySelected = self.schemaOverlay.overlaySelected;
    self.schemaOverlays.overlayAuto = Overlay:new("", Utils.getFilename("hud/implementSchema.png", AutoCutter.dir), 0, 0, 0.5 * g_currentMission.vehicleSchemaOverlayScaleX, 0.5 * g_currentMission.vehicleSchemaOverlayScaleY);
    self.schemaOverlays.overlaySelectedAuto = Overlay:new("", Utils.getFilename("hud/implementSchemaSelected.png", AutoCutter.dir), 0, 0, 0.5 * g_currentMission.vehicleSchemaOverlayScaleX, 0.5 * g_currentMission.vehicleSchemaOverlayScaleY);
    AutoCutter.setSchemaOverlay(self, self.automaticCutterEnabled);
end

function AutoCutter:getSaveAttributesAndNodes(nodeIdent)
    local attributes = string.format("automaticCutterEnabled=\"%s\"", self.automaticCutterEnabled);
    local nodes = nil;
    return attributes, nodes;
end

function AutoCutter:setSchemaOverlay(automaticCutterEnabled)
    if not automaticCutterEnabled then
        self.schemaOverlay.overlay = self.schemaOverlays.overlay;
        self.schemaOverlay.overlaySelected = self.schemaOverlays.overlaySelected;
    else
        self.schemaOverlay.overlay = self.schemaOverlays.overlayAuto;
        self.schemaOverlay.overlaySelected = self.schemaOverlays.overlaySelectedAuto;
    end
end

function AutoCutter:update(dt)
    if InputBinding.hasEvent(InputBinding.AC_TOGGLE, false) then
        self.automaticCutterEnabled = not self.automaticCutterEnabled;
        AutoCutter.setSchemaOverlay(self, self.automaticCutterEnabled);
    end
end

function AutoCutter:updateTick(dt)
    AutoCutter.updateExtendedTestAreas(self);
    local combine = self:getCombine();
    if self.reelStarted and combine:getLastSpeed() > 1 then
        local fruitAhead = false;
        if self.movingDirection == self.cutterMovingDirection then
            for k, testArea in pairs(self.extendedCutterTestAreas) do
                local fruitValue, total = AutoCutter.getFruitArea(self.currentInputFruitType, testArea.x, testArea.z, testArea.widthX, testArea.widthZ, testArea.heightX, testArea.heightZ, self.allowsForageGrowhtState)
                if fruitValue > 0 then
                    fruitAhead = true;
                    break;
                end
            end
        end
        if self.fruitAhead ~= fruitAhead then
            for cutter, implement in pairs(combine.attachedCutters) do
                if cutter == self and not self.isHired and self.automaticCutterEnabled then
                    combine:setJointMoveDown(implement.jointDescIndex, fruitAhead, true);
                    if fruitAhead then
                        AutoCutter.playSample(self, combine, AutoCutter.upSample);
                    else
                        AutoCutter.playSample(self, combine, AutoCutter.downSample);
                    end
                end
            end
            self.fruitAhead = fruitAhead;
        end
    end
    if self.oldSpeedLimit == nil then
        self.oldSpeedLimit = self.speedLimit;
    end
    if self.reelStarted and not self.isCutterSpeedLimitActive then
        self.speedLimit = self.oldSpeedLimit * 1.5;
    elseif self.isCutterSpeedLimitActive then
        self.speedLimit = self.oldSpeedLimit;
    end
end

function AutoCutter:draw()
    if AutoCutter.debug then
        for k, testArea in pairs(self.extendedCutterTestAreas) do
            if self.fruitAhead then
                DebugUtil.drawDebugParallelogram(testArea.x, testArea.z, testArea.widthX, testArea.widthZ, testArea.heightX, testArea.heightZ, 0.1, 0, 1, 0, 0.1);
            else
                DebugUtil.drawDebugParallelogram(testArea.x, testArea.z, testArea.widthX, testArea.widthZ, testArea.heightX, testArea.heightZ, 0.1, 1, 0, 0, 0.1);
            end
        end
    end
    if self.automaticCutterEnabled then
        g_currentMission:addHelpButtonText(g_i18n:getText("AC_DISABLE_AUTO_CUTTER"), InputBinding.AC_TOGGLE, nil, GS_PRIO_HIGH);
    else
        g_currentMission:addHelpButtonText(g_i18n:getText("AC_ENABLE_AUTO_CUTTER"), InputBinding.AC_TOGGLE, nil, GS_PRIO_HIGH);
    end
end

function AutoCutter:keyEvent(unicode, sym, modifier, isDown)
end

function AutoCutter:mouseEvent(posX, posY, isDown, isUp, button)
end

function AutoCutter:delete()
    if self.schemaOverlays.overlay ~= nil then
        self.schemaOverlays.overlay:delete();
    end
    if self.schemaOverlays.overlaySelected ~= nil then
        self.schemaOverlays.overlaySelected:delete();
    end
    if self.schemaOverlays.overlayAuto ~= nil then
        self.schemaOverlays.overlayAuto:delete();
    end
    if self.schemaOverlays.overlaySelectedAuto ~= nil then
        self.schemaOverlays.overlaySelectedAuto:delete();
    end
    if AutoCutter.downSample ~= nil then
        delete(AutoCutter.downSample);
        AutoCutter.downSample = nil;
    end
    if AutoCutter.upSample ~= nil then
        delete(AutoCutter.upSample);
        AutoCutter.upSample = nil;
    end
end

function AutoCutter:updateExtendedTestAreas()
    for k, testArea in pairs(self.cutterTestAreas) do
        local sx, sy, sz = getTranslation(testArea.start);
        local wx, wy, wz = getTranslation(testArea.width);
        local hx, hy, hz = getTranslation(testArea.height);
        
        setTranslation(testArea.start, sx + wx / 3, sy, sz - hz * 3);
        setTranslation(testArea.width, wx / 3, wy, wz);
        setTranslation(testArea.height, hx, hy, hz * 5);
        
        local x, _, z = getWorldTranslation(testArea.start);
        local x1, _, z1 = getWorldTranslation(testArea.width);
        local x2, _, z2 = getWorldTranslation(testArea.height);
        
        setTranslation(testArea.start, sx, sy, sz);
        setTranslation(testArea.width, wx, wy, wz);
        setTranslation(testArea.height, hx, hy, hz);
        
        local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(nil, x, z, x1, z1, x2, z2);
        self.extendedCutterTestAreas[k] = {};
        self.extendedCutterTestAreas[k].x = x;
        self.extendedCutterTestAreas[k].z = z;
        self.extendedCutterTestAreas[k].widthX = widthX;
        self.extendedCutterTestAreas[k].widthZ = widthZ;
        self.extendedCutterTestAreas[k].heightX = heightX;
        self.extendedCutterTestAreas[k].heightZ = heightZ;
    end
end

function AutoCutter.getFruitArea(fruitId, x, z, widthX, widthZ, heightX, heightZ, useMinForageState)
    local fruit = g_currentMission.fruits[fruitId];
    if fruit == nil or fruit.id == 0 then
        return 0, 0;
    end
    local id = fruit.id;
    local desc = FruitUtil.fruitIndexToDesc[fruitId];
    local minState = desc.minHarvestingGrowthState;
    if useMinForageState then
        minState = desc.minForageGrowthState;
    end
    setDensityReturnValueShift(id, -1);
    setDensityCompareParams(id, "between", minState + 1, desc.maxHarvestingGrowthState + 1);
    local ret, total = getDensityParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, 0, g_currentMission.numFruitStateChannels);
    setDensityCompareParams(id, "greater", -1);
    setDensityReturnValueShift(id, 0);
    return ret, total, growthState;
end

function AutoCutter:doCheckSpeedLimit(superFunc)
    local parent = false;
    if superFunc ~= nil then
        parent = superFunc(self);
    end
    return parent or self.reelStarted;
end

function AutoCutter.loadSamples()
    if AutoCutter.downSample == nil then
        local fileName = Utils.getFilename("sounds/cutter_down.wav", AutoCutter.dir);
        AutoCutter.downSample = createSample(fileName);
        loadSample(AutoCutter.downSample, fileName, false);
    end
    if AutoCutter.upSample == nil then
        local fileName = Utils.getFilename("sounds/cutter_up.wav", AutoCutter.dir);
        AutoCutter.upSample = createSample(fileName);
        loadSample(AutoCutter.upSample, fileName, false);
    end
end

function AutoCutter:playSample(combine, sample)
    if combine.isEntered then
        local v = 0.7;
        if combine:getIsIndoorCameraActive() then
            v = 1;
        end
        playSample(sample, 1, v, 0);
    end
end
