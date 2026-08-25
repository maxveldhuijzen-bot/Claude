--[[
	Elements — terse Instance construction.

	create("Frame", { props }, { children }) sets properties, parents children,
	and assigns Parent last so the instance is only replicated once fully built.
]]

local Palette = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Modules.Palette)

local Elements = {}

function Elements.create(className, props, children)
	local instance = Instance.new(className)
	local parent = props and props.Parent

	if props then
		for key, value in pairs(props) do
			if key ~= "Parent" then
				instance[key] = value
			end
		end
	end

	if children then
		for _, child in ipairs(children) do
			if child then
				child.Parent = instance
			end
		end
	end

	if parent then
		instance.Parent = parent
	end

	return instance
end

local create = Elements.create

function Elements.corner(radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius or 10) })
end

function Elements.stroke(color, thickness, transparency)
	return create("UIStroke", {
		Color = color or Palette.stroke,
		Thickness = thickness or 1.5,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Elements.gradient(top, bottom, rotation)
	return create("UIGradient", {
		Color = ColorSequence.new(top, bottom),
		Rotation = rotation or 90,
	})
end

function Elements.padding(all, extra)
	local props = {
		PaddingTop = UDim.new(0, all),
		PaddingBottom = UDim.new(0, all),
		PaddingLeft = UDim.new(0, all),
		PaddingRight = UDim.new(0, all),
	}
	if extra then
		for key, value in pairs(extra) do
			props[key] = value
		end
	end
	return create("UIPadding", props)
end

function Elements.list(padding, direction, alignment)
	return create("UIListLayout", {
		Padding = UDim.new(0, padding or 8),
		FillDirection = direction or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = alignment or Enum.HorizontalAlignment.Center,
	})
end

function Elements.grid(cellSize, cellPadding)
	return create("UIGridLayout", {
		CellSize = cellSize,
		CellPadding = cellPadding or UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	})
end

function Elements.aspect(ratio)
	return create("UIAspectRatioConstraint", { AspectRatio = ratio })
end

function Elements.text(props)
	local defaults = {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextColor3 = Palette.text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		RichText = true,
	}
	for key, value in pairs(props) do
		defaults[key] = value
	end
	return create("TextLabel", defaults)
end

return Elements
