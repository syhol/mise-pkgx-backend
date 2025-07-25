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

local function fetch_dependencies(tool)
	local strings = require("strings")
	local http = require("http")
	local url = "https://raw.githubusercontent.com/pkgxdev/pantry/main/projects/" .. tool .. "/package.yml"
	local response, err = http.get({ url = url })
	if not response then
		return {} -- treat as optional
	end
	local body = response.body or ""

	local deps = {}
	local in_deps = false
	local lines = strings.split(body, "\n")
	for _, line in pairs(lines) do
		if line:match("^dependencies:") then
			in_deps = true
		elseif in_deps then
			if not line:match("^%s") then
				break
			end
			local dep = line:match("^%s*([%w%.-/]+):")
			if dep then
				table.insert(deps, dep)
			end
		end
	end
	return deps
end

local function fetch_latest_version(tool, plat, arch)
	local strings = require("strings")
	local http = require("http")
	local url = "https://dist.pkgx.dev/" .. tool .. "/" .. plat .. "/" .. arch .. "/versions.txt"
	local response, err = http.get({ url = url })
	if not response then
		error("Could not fetch versions for " .. tool .. ": " .. err)
	end
	local body = response.body or ""
	local versions = {}
	for _, line in pairs(strings.split(body, "\n")) do
		if line ~= "" then
			table.insert(versions, line)
		end
	end
	return versions[#versions]
end

local function create_version_symlinks(base_path, version)
	local file = require("file")
	local full = "v" .. version
	local target = base_path .. "/" .. full

	-- major
	local major = version:match("^(%d+)")
	if major then
		file.symlink(target, base_path .. "/v" .. major)
	end

	-- major.minor
	local major_minor = version:match("^(%d+%.%d+)")
	if major_minor then
		file.symlink(target, base_path .. "/v" .. major_minor)
	end

	-- wildcard
	file.symlink(target, base_path .. "/v*")
end

function PLUGIN:BackendInstall(ctx)
	local http = require("http")
	local archiver = require("archiver")
	local cmd = require("cmd")

	local pkg = ctx.tool
	local ver = ctx.version
	local ipath = ctx.install_path
	local plat = detect_platform()
	local arch = detect_arch()
	local base = string.format("https://dist.pkgx.dev/%s/%s/%s", pkg, plat, arch)
	local tgz_url = string.format("%s/v%s.tar.gz", base, ver)

	local exists = cmd.exec("ls -lah " .. ipath .. "/" .. pkg .. " 1>/dev/null && printf true || printf false")
	if exists == "true" then
		return
	end

	-- Download archive
	local tmp_tgz = ipath .. "/pkgx_download.tar.gz"
	local download_error = http.download_file({
		url = tgz_url,
		headers = {
			["User-Agent"] = "mise-plugin",
		},
	}, tmp_tgz)
	if download_error then
		error("Download failed: " .. download_error)
	end

	-- Extract archive
	local extract_err = archiver.decompress(tmp_tgz, ipath)
	if extract_err then
		error("Extraction failed: " .. extract_err)
	end

	-- Clean up
	os.remove(tmp_tgz)

	-- Install dependencies
	print(pkg)
	local deps = fetch_dependencies(pkg)
	for _, dep in pairs(deps) do
		local dep_ver = fetch_latest_version(dep, plat, arch)
		PLUGIN:BackendInstall({ tool = dep, version = dep_ver, install_path = ctx.install_path })
	end
	create_version_symlinks(ipath .. "/" .. pkg, ver)

	return { success = true }
end
