# MemoryStore API Reference

This document provides detailed information about all public methods available in the MemoryStore module.

!!! note
    Functions marked with **[EXPERIMENTAL]** are still under development and may change in future versions. See the [Experimental](./EXP.md) documentation for more details.

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

## Experimental Functions

!!! warning "Caution"
    The following functions are experimental and not fully implemented. See [Experimental Documentation](./EXP.md) for more details.

### StartAutoCleanup **[EXPERIMENTAL]**

Initializes the automatic cleanup process.

```lua
MemoryStore:StartAutoCleanup()
```

!!! note
    This function is called automatically during service initialization.


### ClearExpiredEntries **[EXPERIMENTAL]**

Performs the actual cleanup operation.

```lua
MemoryStore:ClearExpiredEntries()
```

!!! danger
    Implementation is incomplete. Use with caution.