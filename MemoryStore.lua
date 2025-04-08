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
	CleanupTasks = {},
	CleanupInterval = 300 -- Default: 5 minutes
}

--// Config
local Settings = {
	DefaultExpiryTime = 3600,
	MaxSortedMapEntries = 100,
	QueueMaxSize = 500,
	RetryAttempts = 3,
	RetryDelay = 0.5,
	DebugMode = true,
	WarningsEnabled = true,
	ErrorsEnabled = true
}

--// Centralized Error Messages
local ErrorMessages = {
	InvalidKey = "Invalid key provided for %s in %s.",
	HashMapSetFail = "Failed to set key '%s' in HashMap '%s' after retries.",
	HashMapGetFail = "Failed to retrieve key '%s' from HashMap '%s' after retries.",
	SortedMapOverflow = "SortedMap '%s' exceeded max size (%d). Trimming excess entries.",
	QueueFull = "Queue '%s' is full (%d/%d items). Consider purging.",
	AutoCleanupFail = "Auto-cleanup for task '%s' failed: %s",
	CleanupTaskExists = "Cleanup task '%s' already exists.",
	CleanupTaskNotFound = "Cleanup task '%s' not found.",
	InvalidCleanupInterval = "Cleanup interval must be greater than 1 minute.",
	RetryFailed = "Operation '%s' failed after %d attempts."
}

--// Events
MemoryStore.ErrorOccurred = Instance.new("BindableEvent")
MemoryStore.WarningOccurred = Instance.new("BindableEvent")

--// Utility
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

--// Error Handling
local function throwError(key, ...)
	if Settings.ErrorsEnabled then
		local message = ErrorMessages[key]:format(...)
		MemoryStore.ErrorOccurred:Fire(message, "MemoryStoreError")
		error("[MemoryStore Error] " .. message, 2)
	end
end

local function throwWarning(key, ...)
	if Settings.WarningsEnabled then
		local message = ErrorMessages[key]:format(...)
		MemoryStore.WarningOccurred:Fire(message, "MemoryStoreWarning")
		warn("[MemoryStore Warning] " .. message)
	end
end

--// Retry Logic
local function withRetry(operationName, func, ...)
	local attempts = 0
	local delay = Settings.RetryDelay
	local success, result

	while attempts < Settings.RetryAttempts do
		attempts += 1
		success, result = pcall(func, ...)
		if success then return result end
		debugLog(("Retry %d for %s failed: %s"):format(attempts, operationName, tostring(result)))
		task.wait(delay)
		delay *= 2
	end

	throwError("RetryFailed", operationName, Settings.RetryAttempts)
	return nil
end

--// Public: HashMap
function MemoryStore:SetHashMap(name: string, key: string, value: any, expiryTime: number?)
	if not key or key == "" then
		throwError("InvalidKey", "SetHashMap", name)
	end

	local map = getHashMap(name)
	withRetry("SetHashMap", function()
		map:SetAsync(key, value, expiryTime or Settings.DefaultExpiryTime)
	end)
end

function MemoryStore:GetHashMap(name: string, key: string)
	if not key or key == "" then
		throwError("InvalidKey", "GetHashMap", name)
	end

	local map = getHashMap(name)
	return withRetry("GetHashMap", function()
		return map:GetAsync(key)
	end)
end

--// Public: SortedMap
function MemoryStore:SetSortedMap(name: string, key: string, value: number, expiryTime: number?)
	if not key or key == "" then
		throwError("InvalidKey", "SetSortedMap", name)
	end

	local map = getSortedMap(name)
	withRetry("SetSortedMap", function()
		map:SetAsync(key, value, expiryTime or Settings.DefaultExpiryTime)
	end)
end

--// Public: Queue
function MemoryStore:Enqueue(name: string, value: any, expiryTime: number?)
	local queue = getQueue(name)
	local currentSize = self:GetQueueLength(name)

	if currentSize >= Settings.QueueMaxSize then
		throwWarning("QueueFull", name, currentSize, Settings.QueueMaxSize)
	end

	withRetry("Enqueue", function()
		queue:AddAsync(value, expiryTime or Settings.DefaultExpiryTime)
	end)
end

function MemoryStore:GetQueueLength(name: string)
	local queue = getQueue(name)
	return withRetry("GetQueueLength", function()
		return queue:GetSize()
	end)
end

--// Cleanup Tasks
function MemoryStore:AddCleanupTask(taskName: string, callback: () -> ())
	if self.CleanupTasks[taskName] then
		throwError("CleanupTaskExists", taskName)
	end

	self.CleanupTasks[taskName] = callback
	debugLog("Added cleanup task: " .. taskName)
end

function MemoryStore:ForceCleanupCycle()
	debugLog("Forcing cleanup cycle...")
	for taskName, taskFunc in pairs(self.CleanupTasks) do
		local ok, err = pcall(taskFunc)
		if not ok then
			throwWarning("AutoCleanupFail", taskName, err)
		end
	end
end

function MemoryStore:SetCleanupCycleTo(minutes: number)
	if minutes < 1 then
		throwError("InvalidCleanupInterval")
	end

	self.CleanupInterval = minutes * 60
	debugLog("Cleanup cycle set to every " .. minutes .. " minutes.")
end

--// Auto-Cleanup
function MemoryStore:StartAutoCleanup()
	if self._cleanupRunning then return end
	self._cleanupRunning = true

	task.spawn(function()
		while self._cleanupRunning do
			self:ForceCleanupCycle()
			task.wait(self.CleanupInterval)
		end
	end)

	debugLog("Auto-cleanup started (Interval: " .. self.CleanupInterval .. " seconds)")
end

function MemoryStore:StopAutoCleanup()
	self._cleanupRunning = false
	debugLog("Auto-cleanup stopped.")
end

-- Optional: Start on init
-- MemoryStore:StartAutoCleanup()

return MemoryStore
