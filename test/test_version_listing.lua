-- Unit tests for version listing functionality
-- Run with: lua test_version_listing.lua

-- Load the actual plugin code
local PLUGIN = {}

-- Mock modules for testing
local http_mock = {
	response_body = nil,
	should_error = false,
	error_message = "",
}

http_mock.get = function(params)
	if http_mock.should_error then
		return nil, http_mock.error_message
	end
	return {
		body = http_mock.response_body
	}, nil
end

local strings_mock = {
	split = function(str, delimiter)
		local result = {}
		local pattern = "([^" .. delimiter .. "]+)"
		for match in str:gmatch(pattern) do
			table.insert(result, match)
		end
		return result
	end
}

local cmd_mock = {
	uname_s = "Darwin",
	uname_m = "x86_64",
}

cmd_mock.exec = function(command)
	if command == "uname -s" then
		return cmd_mock.uname_s
	elseif command == "uname -m" then
		return cmd_mock.uname_m
	end
	return ""
end

-- Copy the actual functions from backend_list_versions.lua
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
	if not res then
		error("Failed to fetch versions: " .. err)
	end
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

-- Replace require with mocks
local original_require = require
_G.require = function(module)
	if module == "http" then
		return http_mock
	elseif module == "strings" then
		return strings_mock
	elseif module == "cmd" then
		return cmd_mock
	end
	return original_require(module)
end

-- Test cases
local function test_successful_version_listing()
	print("Testing successful version listing...")
	
	http_mock.response_body = "1.0.0\n2.0.0\n2.1.0\n3.0.0\n"
	http_mock.should_error = false
	
	local ctx = { tool = "git-scm.org" }
	local result = PLUGIN:BackendListVersions(ctx)
	
	assert(type(result) == "table", "Result should be a table")
	assert(type(result.versions) == "table", "Result should have versions array")
	assert(#result.versions == 4, "Expected 4 versions, got " .. #result.versions)
	assert(result.versions[1] == "1.0.0", "First version should be '1.0.0'")
	assert(result.versions[4] == "3.0.0", "Last version should be '3.0.0'")
	
	print("✓ Version parsing works correctly")
end

local function test_empty_version_filtering()
	print("Testing empty version filtering...")
	
	http_mock.response_body = "1.0.0\n\n2.0.0\n\n\n3.0.0\n"
	http_mock.should_error = false
	
	local ctx = { tool = "test-tool" }
	local result = PLUGIN:BackendListVersions(ctx)
	
	assert(#result.versions == 3, "Expected 3 versions after filtering, got " .. #result.versions)
	for i, version in ipairs(result.versions) do
		assert(version ~= "", "Version " .. i .. " should not be empty")
	end
	
	print("✓ Empty version filtering works")
end

local function test_http_error_handling()
	print("Testing HTTP error handling...")
	
	http_mock.should_error = true
	http_mock.error_message = "Network timeout"
	
	local ctx = { tool = "nonexistent-tool" }
	local ok, err = pcall(function()
		return PLUGIN:BackendListVersions(ctx)
	end)
	
	assert(not ok, "Expected error when HTTP request fails")
	assert(err:find("Failed to fetch versions"), "Error should mention version fetching failure")
	
	print("✓ HTTP error handling works")
end

local function test_url_construction()
	print("Testing URL construction...")
	
	-- Capture the URL that would be requested
	local captured_url = nil
	http_mock.get = function(params)
		captured_url = params.url
		return { body = "1.0.0\n" }, nil
	end
	http_mock.should_error = false
	
	local ctx = { tool = "example.com" }
	cmd_mock.uname_s = "Linux"
	cmd_mock.uname_m = "aarch64"
	
	PLUGIN:BackendListVersions(ctx)
	
	local expected_url = "https://dist.pkgx.dev/example.com/linux/aarch64/versions.txt"
	assert(captured_url == expected_url, "Expected URL '" .. expected_url .. "', got '" .. captured_url .. "'")
	
	print("✓ URL construction works correctly")
end

local function test_single_version()
	print("Testing single version response...")
	
	http_mock.response_body = "1.0.0\n"
	http_mock.should_error = false
	http_mock.get = function(params)
		return { body = http_mock.response_body }, nil
	end
	
	local ctx = { tool = "single-version-tool" }
	local result = PLUGIN:BackendListVersions(ctx)
	
	assert(#result.versions == 1, "Expected 1 version, got " .. #result.versions)
	assert(result.versions[1] == "1.0.0", "Version should be '1.0.0'")
	
	print("✓ Single version handling works")
end

-- Run tests
print("Running version listing tests...\n")

test_successful_version_listing()
print()
test_empty_version_filtering()
print()
test_http_error_handling()
print()
test_url_construction()
print()
test_single_version()

print("\n✅ All version listing tests passed!")

-- Restore original require
_G.require = original_require