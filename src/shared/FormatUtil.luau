-- FormatUtil.luau
-- Shared formatting, color interpolation, and math helpers for Brainrot Trattoria.

local FormatUtil = {}

local SUFFIXES = {
	{ threshold = 1e15, suffix = "Q" },
	{ threshold = 1e12, suffix = "T" },
	{ threshold = 1e9, suffix = "B" },
	{ threshold = 1e6, suffix = "M" },
	{ threshold = 1e3, suffix = "K" },
}

function FormatUtil.formatNumber(amount: number): string
	if type(amount) ~= "number" or amount ~= amount then
		return "0"
	end
	local negative = amount < 0
	local absVal = math.abs(amount)

	for _, entry in ipairs(SUFFIXES) do
		if absVal >= entry.threshold then
			local scaled = absVal / entry.threshold
			local formatted: string
			if scaled >= 100 then
				formatted = string.format("%.0f%s", scaled, entry.suffix)
			elseif scaled >= 10 then
				formatted = string.format("%.1f%s", scaled, entry.suffix)
			else
				formatted = string.format("%.2f%s", scaled, entry.suffix)
			end
			formatted = string.gsub(formatted, "%.00([A-Z])$", "%1")
			formatted = string.gsub(formatted, "(%.[1-9])0([A-Z])$", "%1%2")
			return (negative and "-" or "") .. formatted
		end
	end

	return (negative and "-" or "") .. tostring(math.floor(absVal + 0.5))
end

function FormatUtil.formatCash(amount: number): string
	if amount < 0 then
		return "-$" .. FormatUtil.formatNumber(math.abs(amount))
	end
	return "$" .. FormatUtil.formatNumber(amount)
end

function FormatUtil.formatRate(amountPerSecond: number): string
	return FormatUtil.formatCash(amountPerSecond) .. "/s"
end

function FormatUtil.formatTimer(secondsRemaining: number): string
	local clamped = math.max(0, math.ceil(secondsRemaining))
	local mins = math.floor(clamped / 60)
	local secs = clamped % 60
	return string.format("%d:%02d", mins, secs)
end

function FormatUtil.lerpColor(a: Color3, b: Color3, alpha: number): Color3
	local t = math.clamp(alpha, 0, 1)
	return Color3.new(
		a.R + (b.R - a.R) * t,
		a.G + (b.G - a.G) * t,
		a.B + (b.B - a.B) * t
	)
end

function FormatUtil.getRainbowColor(clockSeconds: number, phaseOffset: number?): Color3
	local offset = phaseOffset or 0
	local hue = (clockSeconds * 0.38 + offset) % 1
	return Color3.fromHSV(hue, 0.85, 1)
end

function FormatUtil.commaInteger(n: number): string
	local s = tostring(math.floor(math.abs(n)))
	local formatted = s
	while true do
		local nextStr, count = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		formatted = nextStr
		if count == 0 then
			break
		end
	end
	if n < 0 then
		return "-" .. formatted
	end
	return formatted
end

return FormatUtil
