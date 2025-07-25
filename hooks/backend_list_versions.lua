local function detect_platform()
	local cmd = require("cmd")
	local uname = cmd.exec("uname -s")
	uname = uname:lower()
	if uname:find("linux") then
		return "linux"
	elseif uname:find("darwin") then
		return "darwin"
	else
		error("Unsupported OS: " .. uname)
	end
end

local function detect_arch()
	local cmd = require("cmd")
	local arch = cmd.exec("uname -m"):gsub("\n", "")
	arch = arch:lower()
	if arch == "x86_64" then
		return "x86-64"
	elseif arch == "arm64" or arch == "aarch64" then
		return "aarch64"
	else
		error("Unsupported arch: " .. arch)
	end
end

function PLUGIN:BackendListVersions(ctx)
	local http = require("http")
	local strings = require("strings")

	local pkg = ctx.tool
	local plat = detect_platform()
	local arch = detect_arch()
	local url = "https://dist.pkgx.dev/" .. pkg .. "/" .. plat .. "/" .. arch .. "/versions.txt"
	local res, err = http.get({
		url = url,
	})
	local body = res.body
	if not body then
		error("Failed to fetch versions: " .. err)
	end

	local versions = strings.split(body, "\n")
	local cleaned = {}
	for _, v in ipairs(versions) do
		if v ~= "" then
			table.insert(cleaned, v)
		end
	end

	return { versions = cleaned }
end
