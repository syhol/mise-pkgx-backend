-- Unit tests for platform detection functions
-- Run with: lua test_platform_detection.lua

-- Mock cmd module for testing
local cmd_mock = {
	uname_s = nil,
	uname_m = nil,
}

cmd_mock.exec = function(command)
	if command == "uname -s" then
		return cmd_mock.uname_s
	elseif command == "uname -m" then
		return cmd_mock.uname_m
	end
	return ""
end

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

-- Replace require with mock
local original_require = require
_G.require = function(module)
	if module == "cmd" then
		return cmd_mock
	end
	return original_require(module)
end

-- Test cases
local function test_detect_platform()
	print("Testing detect_platform()...")
	
	-- Test Linux detection
	cmd_mock.uname_s = "Linux"
	local result = detect_platform()
	assert(result == "linux", "Expected 'linux', got '" .. result .. "'")
	print("✓ Linux detection works")
	
	-- Test Darwin detection
	cmd_mock.uname_s = "Darwin"
	result = detect_platform()
	assert(result == "darwin", "Expected 'darwin', got '" .. result .. "'")
	print("✓ Darwin detection works")
	
	-- Test case insensitive
	cmd_mock.uname_s = "linux"
	result = detect_platform()
	assert(result == "linux", "Expected 'linux', got '" .. result .. "'")
	print("✓ Case insensitive detection works")
	
	-- Test unsupported OS
	cmd_mock.uname_s = "Windows_NT"
	local ok, err = pcall(detect_platform)
	assert(not ok, "Expected error for unsupported OS")
	assert(err:find("Unsupported OS"), "Expected 'Unsupported OS' in error message")
	print("✓ Unsupported OS error handling works")
end

local function test_detect_arch()
	print("Testing detect_arch()...")
	
	-- Test x86_64 detection
	cmd_mock.uname_m = "x86_64"
	local result = detect_arch()
	assert(result == "x86-64", "Expected 'x86-64', got '" .. result .. "'")
	print("✓ x86_64 detection works")
	
	-- Test arm64 detection
	cmd_mock.uname_m = "arm64"
	result = detect_arch()
	assert(result == "aarch64", "Expected 'aarch64', got '" .. result .. "'")
	print("✓ arm64 detection works")
	
	-- Test aarch64 detection
	cmd_mock.uname_m = "aarch64"
	result = detect_arch()
	assert(result == "aarch64", "Expected 'aarch64', got '" .. result .. "'")
	print("✓ aarch64 detection works")
	
	-- Test with newline (simulating real command output)
	cmd_mock.uname_m = "x86_64\n"
	result = detect_arch()
	assert(result == "x86-64", "Expected 'x86-64', got '" .. result .. "'")
	print("✓ Newline trimming works")
	
	-- Test unsupported architecture
	cmd_mock.uname_m = "i386"
	local ok, err = pcall(detect_arch)
	assert(not ok, "Expected error for unsupported architecture")
	assert(err:find("Unsupported arch"), "Expected 'Unsupported arch' in error message")
	print("✓ Unsupported architecture error handling works")
end

-- Run tests
print("Running platform detection tests...\n")

test_detect_platform()
print()
test_detect_arch()

print("\n✅ All platform detection tests passed!")

-- Restore original require
_G.require = original_require