--[[

MemoryStore Module (Optimized for Production)
- Uses Knit
- Server-side only
- Includes retry mechanism for failed operations
- Dynamic cleanup task management
- Event-based error/warning system

]]

--// Dependencies
local Knit = require(game.ReplicatedStorage.Packages.Knit)
local Trove = require(game.ReplicatedStorage.Packages.Trove)

--// Module
local MemoryStore = Knit.CreateService {
	Name = "MemoryStore",
	CleanupTasks = {}, -- Holds registered cleanup tasks
	CleanupInterval = 300 -- Default: 5 minutes
}

--// Adjustable Settings
local Settings = {
	DefaultExpiryTime = 3600, -- 1 hour
	MaxSortedMapEntries = 100, -- Max leaderboard entries
	QueueMaxSize = 500, -- Max messages before auto-purge
	RetryAttempts = 3, -- Number of times to retry failed operations
	RetryDelay = 0.5, -- Initial delay before retrying (seconds, doubles each attempt)
	DebugMode = true, -- Enable logging
	WarningsEnabled = true, -- Enable warnings for non-critical issues
	ErrorsEnabled = true -- Enable errors for critical failures
}

--// Centralized Error Messages
local ErrorMessages = {
	InvalidKey = "Invalid key provided for %s in %s.",
	HashMapSetFail = "Failed to set key '%s' in HashMap '%s' after retries.",
	HashMapGetFail = "Failed to retrieve key '%s' from HashMap '%s' after retries.",
	SortedMapOverflow = "SortedMap '%s' exceeded max size (%d). Trimming excess entries.",
	QueueFull = "Queue '%s' is full (%d/%d items). Consider purging.",
	AutoCleanupFail = "Auto-cleanup failed unexpectedly.",
	CleanupTaskExists = "Cleanup task '%s' already exists.",
	CleanupTaskNotFound = "Cleanup task '%s' not found.",
	InvalidCleanupInterval = "Cleanup interval must be greater than 1 minute.",
	RetryFailed = "Operation '%s' failed after %d attempts."
}

--// Error & Warning Events
MemoryStore.ErrorOccurred = Instance.new("BindableEvent")
MemoryStore.WarningOccurred = Instance.new("BindableEvent")

--// Helper Functions
local function getHashMap(name: string)
	return game:GetService("MemoryStoreService"):GetHashMap(name)
end

local function getSortedMap(name: string)
	return game:GetService("MemoryStoreService"):GetSortedMap(name)
end

local function getQueue(name: string)
	return game:GetService("MemoryStoreService"):GetQueue(name)
end

local function debugLog(message)
	if Settings.DebugMode then
		print("[MemoryStore] " .. message)
	end
end

--// Error Handling Functions
local function throwError(errorKey, ...)
	if Settings.ErrorsEnabled then
		local message = ErrorMessages[errorKey]:format(...)
		MemoryStore.ErrorOccurred:Fire(message, "MemoryStoreError")
		error("[MemoryStore Error] " .. message, 2)
	end
end

local function throwWarning(errorKey, ...)
	if Settings.WarningsEnabled then
		local message = ErrorMessages[errorKey]:format(...)
		MemoryStore.WarningOccurred:Fire(message, "MemoryStoreWarning")
		warn("[MemoryStore Warning] " .. message)
	end
end

--// Retry Wrapper
local function withRetry(operationName, func, ...)
	local attempts = 0
	local delay = Settings.RetryDelay
	local success, result

	while attempts < Settings.RetryAttempts do
		attempts += 1
		success, result = pcall(func, ...)

		if success then
			return result -- Return result if successful
		end

		debugLog(("Retry %d for %s failed: %s"):format(attempts, operationName, tostring(result)))
		task.wait(delay) -- Exponential backoff
		delay = delay * 2
	end

	throwError("RetryFailed", operationName, Settings.RetryAttempts)
	return nil
end

--// Public Functions

-- HashMap Functions
function MemoryStore:SetHashMap(name: string, key: string, value: any, expiryTime: number?)
	local map = getHashMap(name)
	if not key or key == "" then
		throwError("InvalidKey", "SetHashMap", name)
		return
	end

	local success = withRetry("SetHashMap", function()
		map:SetAsync(key, value, expiryTime or Settings.DefaultExpiryTime)
	end)

	if not success then
		throwWarning("HashMapSetFail", key, name)
	end
end

function MemoryStore:GetHashMap(name: string, key: string)
	local map = getHashMap(name)
	if not key or key == "" then
		throwError("InvalidKey", "GetHashMap", name)
		return nil
	end

	return withRetry("GetHashMap", function()
		return map:GetAsync(key)
	end)
end

-- SortedMap Functions
function MemoryStore:SetSortedMap(name: string, key: string, value: number, expiryTime: number?)
	local sortedMap = getSortedMap(name)
	if not key or key == "" then
		throwError("InvalidKey", "SetSortedMap", name)
		return
	end

	withRetry("SetSortedMap", function()
		sortedMap:SetAsync(key, value, expiryTime or Settings.DefaultExpiryTime)
	end)
end

-- Queue Functions
function MemoryStore:Enqueue(name: string, value: any, expiryTime: number?)
	local queue = getQueue(name)

	-- Prevent queue overflow
	local currentSize = self:GetQueueLength(name)
	if currentSize >= Settings.QueueMaxSize then
		throwWarning("QueueFull", name, currentSize, Settings.QueueMaxSize)
	end

	withRetry("Enqueue", function()
		queue:AddAsync(value, expiryTime or Settings.DefaultExpiryTime)
	end)
end

-- Cleanup Task System
function MemoryStore:AddCleanupTask(taskName: string, callback: () -> ())
	if self.CleanupTasks[taskName] then
		throwError("CleanupTaskExists", taskName)
		return
	end

	self.CleanupTasks[taskName] = callback
	debugLog("Added cleanup task: " .. taskName)
end

function MemoryStore:ForceCleanupCycle()
	debugLog("Forcing cleanup cycle...")
	for taskName, taskFunc in pairs(self.CleanupTasks) do
		local success, err = pcall(taskFunc)
		if not success then
			throwWarning("AutoCleanupFail", taskName, err)
		end
	end
end

function MemoryStore:SetCleanupCycleTo(minutes: number)
	if minutes < 1 then
		throwError("InvalidCleanupInterval")
		return
	end

	self.CleanupInterval = minutes * 60
	debugLog("Cleanup cycle set to every " .. minutes .. " minutes.")
end

-- Auto Cleanup System
function MemoryStore:StartAutoCleanup()
	local cleanupTrove = Trove.new()
	cleanupTrove:AddTask(self.CleanupInterval, function()
		self:ForceCleanupCycle()
	end)
end

--// Start Auto-Cleanup on Initialization
MemoryStore:StartAutoCleanup()

return MemoryStore
