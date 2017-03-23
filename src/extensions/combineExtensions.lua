--
-- AutomaticCutters
--
-- @author  TyKonKet
-- @date 22/03/2017
function Combine:startThreshing()
    if self.numAttachedCutters > 0 then
        for cutter, implement in pairs(self.attachedCutters) do
            cutter:onStartReel();
        end
        if self.threshingStartAnimation ~= nil and self.playAnimation ~= nil then
            self:playAnimation(self.threshingStartAnimation, self.threshingStartAnimationSpeedScale, self:getAnimationTime(self.threshingStartAnimation), true);
        end
        
        if self.isClient then
            SoundUtil.stopSample(self.sampleThreshingStop, true);
            if self:getIsActiveForSound() then
                SoundUtil.playSample(self.sampleThreshingStart, 1, 0, nil);
            end
        end
    end
end
