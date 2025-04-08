# MemoryStore API Reference

This document provides detailed information about all public methods available in the MemoryStore module.

## HashMap Functions

HashMaps provide key-value storage for structured data.

### SetHashMap

Sets a value in a HashMap with the specified key.

```lua
MemoryStore:SetHashMap(name: string, key: string, value: any, expiryTime: number?)
```

**Parameters:**
- `name`: The name of the HashMap
- `key`: The key to store the value under
- `value`: The value to store (can be any serializable data)
- `expiryTime` (optional): Time in seconds before the entry expires (defaults to Settings.DefaultExpiryTime)

!!! warning "Important"
    Values must be serializable by Roblox's MemoryStoreService. Complex objects with circular references or certain data types may cause errors.

!!! info "Retry Mechanism"
    This function includes an automatic retry mechanism that will attempt the operation up to 3 times with exponential backoff before failing.

**Example:**
```lua
-- Store player data for 1 hour (default)
MemoryStore:SetHashMap("PlayerData", "Player_123", {
    coins = 500,
    level = 5,
    lastLogin = os.time()
})

-- Store temporary ban with custom expiry (30 minutes)
MemoryStore:SetHashMap("TempBans", "Player_456", true, 1800)
```

### GetHashMap

Retrieves a value from a HashMap by key.

```lua
local value = MemoryStore:GetHashMap(name: string, key: string)
```

**Parameters:**
- `name`: The name of the HashMap
- `key`: The key to retrieve

**Returns:**
- The stored value, or nil if the key doesn't exist or has expired

!!! info "Tip"
    Always check if the returned value is nil before attempting to use it, as entries may have expired.

!!! info "Retry Mechanism"
    This function includes an automatic retry mechanism that will attempt the operation up to 3 times with exponential backoff before failing.

**Example:**
```lua
local playerData = MemoryStore:GetHashMap("PlayerData", "Player_123")
if playerData then
    print("Player has", playerData.coins, "coins")
end

-- Check if player is temporarily banned
if MemoryStore:GetHashMap("TempBans", "Player_456") then
    print("Player is banned")
end
```
!!! note
    For any ban related logic, please use Roblox's [BanApi](https://devforum.roblox.com/t/introducing-the-ban-api-and-alt-account-detection/30397400).

## SortedMap Functions

SortedMaps are useful for leaderboards, rankings, and ordered data.

### SetSortedMap

Sets a numerical value for a key in a SortedMap.

```lua
MemoryStore:SetSortedMap(name: string, key: string, value: number, expiryTime: number?)
```

**Parameters:**
- `name`: The name of the SortedMap
- `key`: The key to store the value under
- `value`: The numerical value to store
- `expiryTime` (optional): Time in seconds before the entry expires (defaults to Settings.DefaultExpiryTime)

!!! warning
    The value parameter must be a number. Attempting to store non-numeric values will result in an error.

!!! info "Retry Mechanism"
    This function includes an automatic retry mechanism that will attempt the operation up to 3 times with exponential backoff before failing.

**Notes:**
- Automatically prevents overflow by trimming excess entries if the map exceeds Settings.MaxSortedMapEntries

**Example:**
```lua
-- Update player score on leaderboard
MemoryStore:SetSortedMap("WeeklyScores", "Player_123", 5000)
```

### GetSortedMapSize

Returns the current number of entries in a SortedMap.

```lua
local size = MemoryStore:GetSortedMapSize(name: string)
```

**Parameters:**
- `name`: The name of the SortedMap

**Returns:**
- The number of entries in the SortedMap

!!! note
    This function is useful for monitoring leaderboard sizes and ensuring they don't exceed the maximum allowed entries.

**Example:**
```lua
local leaderboardSize = MemoryStore:GetSortedMapSize("WeeklyScores")
print("There are", leaderboardSize, "players on the leaderboard")
```

## Queue Functions

Queues are FIFO (First-In-First-Out) data structures useful for message processing.

### Enqueue

Adds a value to the end of a queue.

```lua
MemoryStore:Enqueue(name: string, value: any, expiryTime: number?)
```

**Parameters:**
- `name`: The name of the Queue
- `value`: The value to add to the queue
- `expiryTime` (optional): Time in seconds before the entry expires (defaults to Settings.DefaultExpiryTime)

!!! warning
    If a queue exceeds the Settings.QueueMaxSize limit, a warning will be issued but items will still be added. Consider implementing a purge mechanism for very active queues.

!!! info "Retry Mechanism"
    This function includes an automatic retry mechanism that will attempt the operation up to 3 times with exponential backoff before failing.

**Example:**
```lua
-- Add a message to the processing queue
MemoryStore:Enqueue("MessageQueue", {
    sender = "Player_123",
    content = "Hello world!",
    timestamp = os.time()
})
```

### GetQueueLength

Returns the current number of items in a Queue.

```lua
local length = MemoryStore:GetQueueLength(name: string)
```

**Parameters:**
- `name`: The name of the Queue

**Returns:**
- The number of items in the Queue

!!! info "Tip"
    Monitor queue lengths periodically to detect potential bottlenecks in message processing systems.

**Example:**
```lua
local messageCount = MemoryStore:GetQueueLength("MessageQueue")
print("There are", messageCount, "messages waiting to be processed")
```

## Cleanup System

The cleanup system manages registered maintenance tasks that execute on a fixed schedule to keep memory store usage efficient. It supports manual control and dynamic configuration for flexible resource management.

---

### AddCleanupTask

Registers a named cleanup task to be run during every cleanup cycle.

```lua
MemoryStore:AddCleanupTask(taskName: string, callback: () -> ())
```

**Parameters:**
- `taskName`: A unique identifier for this cleanup task.
- `callback`: A function that will be executed during cleanup cycles.

!!! warning
    Adding a task with an existing name will raise an error. Use unique task names to avoid collisions.

**Example:**
```lua
MemoryStore:AddCleanupTask("PurgeInactiveQueues", function()
    print("Purging queues with no recent activity...")
    -- Custom logic to remove stale data
end)
```

---

### ForceCleanupCycle

Immediately executes all currently registered cleanup tasks.

```lua
MemoryStore:ForceCleanupCycle()
```

**Use Case:**  
Call this method when you need to force cleanup—such as before a server shutdown or after critical events.

!!! note
    This function does not respect the automatic interval and runs all tasks immediately.

**Example:**
```lua
-- Trigger cleanup manually
MemoryStore:ForceCleanupCycle()
```

---

### SetCleanupCycleTo

Changes the interval for automatic cleanup task execution.

```lua
MemoryStore:SetCleanupCycleTo(minutes: number)
```

**Parameters:**
- `minutes`: The new interval in minutes (must be ≥ 1)

!!! warning
    Setting the interval too low can affect server performance. A recommended minimum is 5 minutes for most production scenarios.

**Example:**
```lua
-- Schedule cleanup to run every 10 minutes
MemoryStore:SetCleanupCycleTo(10)
```

---

### StartAutoCleanup

Begins the automatic cleanup cycle using the configured interval. Internally uses `task.spawn()` and `task.wait()` for consistent loop execution.

```lua
MemoryStore:StartAutoCleanup()
```

**Behavior:**
- Runs cleanup tasks continuously on a loop defined by `CleanupInterval`.
- Automatically started during service initialization, but can be manually restarted if stopped.

!!! note
    Manual invocation is only needed if you call `StopAutoCleanup()` and wish to resume the loop.

**Example:**
```lua
-- Restart the cleanup system if it was stopped
MemoryStore:StartAutoCleanup()
```

---

### StopAutoCleanup

Stops the currently running auto-cleanup cycle.

```lua
MemoryStore:StopAutoCleanup()
```

**Behavior:**
- Terminates the background task responsible for periodic cleanup.
- Useful for maintenance windows or runtime control scenarios.

**Example:**
```lua
-- Stop automatic cleanup for the duration of a data migration
MemoryStore:StopAutoCleanup()
```

## Error Handling

The MemoryStore module includes an event-based error and warning system.

### Error Events

You can subscribe to error and warning events to monitor MemoryStore operations:

```lua
-- Listen for critical errors
MemoryStore.ErrorOccurred.Event:Connect(function(message, errorType)
    -- Log or handle the error
    print("MemoryStore Error:", message, errorType)
end)

-- Listen for non-critical warnings
MemoryStore.WarningOccurred.Event:Connect(function(message, warningType)
    -- Log or handle the warning
    print("MemoryStore Warning:", message, warningType)
end)
```

!!! tip
    Connecting to these events allows you to implement custom logging or error handling strategies.