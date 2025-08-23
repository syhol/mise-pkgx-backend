-- Unit tests for exec environment functionality
-- Run with: lua test_exec_env.lua

local PLUGIN = {}

-- Copy the actual function from backend_exec_env.lua
function PLUGIN:BackendExecEnv(ctx)
	local file = require("file")
	return {
		env_vars = {
			{
				key = "PATH",
				value = file.join_path(ctx.install_path, ctx.tool, "v" .. ctx.version, "bin"),
			},
		},
	}
end

-- Mock file module for testing
local file_mock = {
	join_path = function(...)
		local args = {...}
		return table.concat(args, "/")
	end
}

-- Replace require with mock
local original_require = require
_G.require = function(module)
	if module == "file" then
		return file_mock
	end
	return original_require(module)
end

-- Test cases
local function test_path_construction()
	print("Testing PATH construction...")
	
	local ctx = {
		install_path = "/home/user/.local/share/mise/installs",
		tool = "git-scm.org",
		version = "2.44.0"
	}
	
	local result = PLUGIN:BackendExecEnv(ctx)
	
	assert(type(result) == "table", "Result should be a table")
	assert(type(result.env_vars) == "table", "Result should have env_vars array")
	assert(#result.env_vars == 1, "Expected 1 environment variable, got " .. #result.env_vars)
	
	local path_var = result.env_vars[1]
	assert(path_var.key == "PATH", "Environment variable key should be 'PATH'")
	
	local expected_path = "/home/user/.local/share/mise/installs/git-scm.org/v2.44.0/bin"
	assert(path_var.value == expected_path, "Expected PATH '" .. expected_path .. "', got '" .. path_var.value .. "'")
	
	print("✓ PATH construction works correctly")
end

local function test_different_versions()
	print("Testing different version formats...")
	
	local test_cases = {
		{
			ctx = {install_path = "/opt/mise", tool = "node.js", version = "18.0.0"},
			expected = "/opt/mise/node.js/v18.0.0/bin"
		},
		{
			ctx = {install_path = "/usr/local/mise", tool = "python.org", version = "3.11.1"},
			expected = "/usr/local/mise/python.org/v3.11.1/bin"
		},
		{
			ctx = {install_path = "/tmp/test", tool = "go.dev", version = "1.20.0"},
			expected = "/tmp/test/go.dev/v1.20.0/bin"
		}
	}
	
	for i, test_case in ipairs(test_cases) do
		local result = PLUGIN:BackendExecEnv(test_case.ctx)
		local actual_path = result.env_vars[1].value
		assert(actual_path == test_case.expected, 
			"Test case " .. i .. ": Expected '" .. test_case.expected .. "', got '" .. actual_path .. "'")
	end
	
	print("✓ Different version formats work correctly")
end

local function test_special_characters_in_paths()
	print("Testing special characters in paths...")
	
	local ctx = {
		install_path = "/path/with spaces/mise",
		tool = "some-tool.com",
		version = "1.0.0-beta.1"
	}
	
	local result = PLUGIN:BackendExecEnv(ctx)
	local path_var = result.env_vars[1]
	
	local expected_path = "/path/with spaces/mise/some-tool.com/v1.0.0-beta.1/bin"
	assert(path_var.value == expected_path, "Expected PATH '" .. expected_path .. "', got '" .. path_var.value .. "'")
	
	print("✓ Special characters in paths work correctly")
end

local function test_return_structure()
	print("Testing return structure...")
	
	local ctx = {install_path = "/test", tool = "test", version = "1.0.0"}
	local result = PLUGIN:BackendExecEnv(ctx)
	
	-- Test overall structure
	assert(type(result) == "table", "Result should be a table")
	assert(result.env_vars ~= nil, "Result should have env_vars field")
	assert(type(result.env_vars) == "table", "env_vars should be a table")
	
	-- Test env_vars structure
	local env_var = result.env_vars[1]
	assert(type(env_var) == "table", "Environment variable should be a table")
	assert(type(env_var.key) == "string", "Environment variable key should be a string")
	assert(type(env_var.value) == "string", "Environment variable value should be a string")
	assert(env_var.key ~= "", "Environment variable key should not be empty")
	assert(env_var.value ~= "", "Environment variable value should not be empty")
	
	print("✓ Return structure is correct")
end

local function test_empty_inputs()
	print("Testing edge cases...")
	
	local ctx = {install_path = "", tool = "", version = ""}
	local result = PLUGIN:BackendExecEnv(ctx)
	
	assert(#result.env_vars == 1, "Should still return one environment variable")
	assert(result.env_vars[1].key == "PATH", "Key should still be PATH")
	
	-- Even with empty inputs, should construct a path (may not be valid, but structured)
	local path_value = result.env_vars[1].value
	assert(type(path_value) == "string", "PATH value should be a string")
	
	print("✓ Edge cases handled")
end

-- Run tests
print("Running exec environment tests...\n")

test_path_construction()
print()
test_different_versions()
print()
test_special_characters_in_paths()
print()
test_return_structure()
print()
test_empty_inputs()

print("\n✅ All exec environment tests passed!")

-- Restore original require
_G.require = original_require