--
-- AutomaticCutters
--
-- @author  TyKonKet
-- @date 22/03/2017
AutomaticCutters = {};
AutomaticCutters.name = "AutomaticCutters";
AutomaticCutters.specialization = {};
AutomaticCutters.specialization.title = "AutoCutter";
AutomaticCutters.specialization.name = "autoCutter";
-- vehicleTypeName = true (conveyorTrailerHireable = true)
AutomaticCutters.specialization.blackList = {};
AutomaticCutters.debug = true;

function AutomaticCutters:print(text, ...)
    local start = string.format("[%s(%s)] -> ", self.name, getDate("%H:%M:%S"));
    local ptext = string.format(text, ...);
    print(string.format("%s%s", start, ptext));
end

function AutomaticCutters:registerSpecialization()
    local specialization = SpecializationUtil.getSpecialization(self.specialization.name);
    for _, vehicleType in pairs(VehicleTypeUtil.vehicleTypes) do
        if vehicleType ~= nil then
            if specialization.prerequisitesPresent(vehicleType.specializations) and not self.specialization.blackList[vehicleType.name] then
                table.insert(vehicleType.specializations, specialization);
                self:print("%s added to %s", self.specialization.title, vehicleType.name);
            end
        end
    end
end

function AutomaticCutters:loadMap(name)
    if self.debug then
        addConsoleCommand("AAAACToggleDebug", "", "ACToggleDebug", self);
        addConsoleCommand("AAAPrintVehicleValue", "", "PrintVehicleValue", self);
    end
    AutomaticCutters:registerSpecialization();
end

function AutomaticCutters:deleteMap()
end

function AutomaticCutters:keyEvent(unicode, sym, modifier, isDown)
end

function AutomaticCutters:mouseEvent(posX, posY, isDown, isUp, button)
end

function AutomaticCutters:update(dt)
end

function AutomaticCutters:draw()
end

function AutomaticCutters.ACToggleDebug(self)
    self.debug = not self.debug;
    AutoCutter.debug = self.debug;
    return "ACToggleDebug = " .. tostring(self.debug);
end

function AutomaticCutters.PrintVehicleValue(self, p1)
    if g_currentMission.controlledVehicle == nil then
        return "controlledVehicle == nil";
    else
        self:print(g_currentMission.controlledVehicle[p1]);
    end
end

addModEventListener(AutomaticCutters);
