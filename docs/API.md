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

**Notes:**
- Issues a warning if the queue exceeds Settings.QueueMaxSize

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

**Example:**
```lua
local messageCount = MemoryStore:GetQueueLength("MessageQueue")
print("There are", messageCount, "messages waiting to be processed")
```