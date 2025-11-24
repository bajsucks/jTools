local Haptics = {}

function Haptics.UIClick()
	local effect = Instance.new("HapticEffect")
	effect.Type = Enum.HapticEffectType.UIClick
	effect:Play()
end

function Haptics.UIHover()
	local effect = Instance.new("HapticEffect")
	effect.Type = Enum.HapticEffectType.UIHover
	effect:Play()
end

function Haptics.Notif()
	local effect = Instance.new("HapticEffect")
	effect.Type = Enum.HapticEffectType.UINotification
	effect:Play()
end

function Haptics.Hit() -- check if this actually does what I want it to do
	local effect = Instance.new("HapticEffect")
	effect.Type = Enum.HapticEffectType.Custom
	effect:SetWaveformKeys({
        FloatCurveKey.new(0, 0.2, Enum.KeyInterpolationMode.Linear),
        FloatCurveKey.new(0.1, 0.2, Enum.KeyInterpolationMode.Linear),
        FloatCurveKey.new(0.2, 0, Enum.KeyInterpolationMode.Linear)
    })
	effect:Play()
end

return Haptics
