--!optimize 2
--!strict

local function EqualObjects(ValueA: any, ValueB: any)
	if ValueA == nil then
		return ValueB == nil
	elseif ValueB == nil then
		return ValueA == nil
	end

	local TypeOf = typeof(ValueA)
	if TypeOf ~= typeof(ValueB) then
		return false
	end

	if TypeOf == "table" then
		for Key, Value in ValueA do
			if Value ~= ValueB[Key] then
				return false
			end
		end

		for Key, Value in ValueB do
			if Value ~= ValueA[Key] then
				return false
			end
		end

		return true
	end

	return false
end

return EqualObjects
