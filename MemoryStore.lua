--[[

MemoryStore Module (Optimized for Production)
- Uses Knit
- Server-side only
- Includes adjustable settings & auto-cleanup
- Event-based error/warning system

]]

--// Dependencies
local Knit = require(game.ReplicatedStorage.Packages.Knit)
local Trove = require(game.ReplicatedStorage.Packages.Trove)

--// Module
local MemoryStore = Knit.CreateService {
	Name = "MemoryStore"
}

--// Adjustable Settings
local Settings = {
	DefaultExpiryTime = 3600, -- 1 hour
	AutoCleanupInterval = 300, -- 5 minutes
	MaxSortedMapEntries = 100, -- Max leaderboard entries
	QueueMaxSize = 500, -- Max messages before auto-purge
	DebugMode = true, -- Enable logging
	WarningsEnabled = true, -- Enable warnings for non-critical issues
	ErrorsEnabled = true -- Enable errors for critical failures
}

--// Centralized Error Messages
local ErrorMessages = {
	InvalidKey = "Invalid key provided for %s in %s.",
	HashMapSetFail = "Failed to set key '%s' in HashMap '%s'.",
	SortedMapOverflow = "SortedMap '%s' exceeded max size (%d). Trimming excess entries.",
	QueueFull = "Queue '%s' is full (%d/%d items). Consider purging.",
	AutoCleanupFail = "Auto-cleanup failed unexpectedly."
}

--// Error & Warning Events
MemoryStore.ErrorOccurred = Instance.new("BindableEvent") -- Fires for critical failures
MemoryStore.WarningOccurred = Instance.new("BindableEvent") -- Fires for warnings

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
		MemoryStore.ErrorOccurred:Fire(message, "MemoryStoreError") -- Fire event for listeners
		error("[MemoryStore Error] " .. message, 2)
	end
end

local function throwWarning(errorKey, ...)
	if Settings.WarningsEnabled then
		local message = ErrorMessages[errorKey]:format(...)
		MemoryStore.WarningOccurred:Fire(message, "MemoryStoreWarning") -- Fire event for listeners
		warn("[MemoryStore Warning] " .. message)
	end
end

--// Public Functions

-- HashMap Functions
function MemoryStore:SetHashMap(name: string, key: string, value: any, expiryTime: number?)
	local map = getHashMap(name)
	if not key or key == "" then
		throwError("InvalidKey", "SetHashMap", name)
		return
	end

	local success = pcall(function()
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

	local success, result = pcall(function()
		return map:GetAsync(key)
	end)

	if not success then
		throwWarning("HashMapGetFail", key, name)
	end
	return result
end

-- SortedMap Functions
function MemoryStore:SetSortedMap(name: string, key: string, value: number, expiryTime: number?)
	local sortedMap = getSortedMap(name)
	if not key or key == "" then
		throwError("InvalidKey", "SetSortedMap", name)
		return
	end

	sortedMap:SetAsync(key, value, expiryTime or Settings.DefaultExpiryTime)

	-- Prevent leaderboard overflow
	if self:GetSortedMapSize(name) > Settings.MaxSortedMapEntries then
		throwWarning("SortedMapOverflow", name, self:GetSortedMapSize(name))
		self:TrimSortedMap(name, Settings.MaxSortedMapEntries)
	end
end

function MemoryStore:GetSortedMapSize(name: string)
	local sortedMap = getSortedMap(name)
	local success, result = pcall(function()
		return sortedMap:GetRangeAsync(Enum.SortDirection.Descending, 1)
	end)
	return success and #result or 0
end

-- Queue Functions
function MemoryStore:Enqueue(name: string, value: any, expiryTime: number?)
	local queue = getQueue(name)

	-- Prevent queue overflow
	local currentSize = self:GetQueueLength(name)
	if currentSize >= Settings.QueueMaxSize then
		throwWarning("QueueFull", name, currentSize, Settings.QueueMaxSize)
	end

	queue:AddAsync(value, expiryTime or Settings.DefaultExpiryTime)
end

function MemoryStore:GetQueueLength(name: string)
	local queue = getQueue(name)
	local success, result = pcall(function()
		return queue:GetLengthAsync()
	end)
	if not success then
		throwWarning("QueueLengthFail", name)
	end
	return success and result or 0
end

-- Auto Cleanup System || CONCEPT
function MemoryStore:StartAutoCleanup()
	local cleanupTrove = Trove.new()
	cleanupTrove:AddTask(Settings.AutoCleanupInterval, function()
		local success = pcall(function()
			self:ClearExpiredEntries()
		end)
		if not success then
			throwError("AutoCleanupFail")
		end
	end)
end

function MemoryStore:ClearExpiredEntries()
	local success, result = pcall(function()
	end)

	if not success then
		throwWarning("AutoCleanupWarning")
	end
end

--// Start Auto-Cleanup on Initialization
MemoryStore:StartAutoCleanup()

return MemoryStore
