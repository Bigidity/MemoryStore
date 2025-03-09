# MemoryStore Module

## Introduction

The MemoryStore Module is a server-side utility designed to simplify interactions with Roblox's MemoryStoreService. Built on top of Knit, it provides a robust interface for managing temporary data storage with features like:

- HashMaps for key-value storage
- SortedMaps for leaderboards and ranked data
- Queues for message processing and temporary storage
- Automatic cleanup of expired entries
- Comprehensive error handling and warning system
- Configurable settings for production environments

This module is optimized for production use and includes safeguards against common issues such as memory leaks and overflow conditions.

## Installation

### Prerequisites

- [Knit](https://github.com/Sleitnick/Knit) framework
- [Trove](https://github.com/Sleitnick/RbxUtil/tree/main/modules/trove) utility

### Setup

1. Place the MemoryStore module in your server scripts, typically in `ServerScriptService` or a dedicated services folder.

2. Ensure Knit and Trove are properly installed in your project (typically in ReplicatedStorage.Packages).

3. Require the module in your main server script after initializing Knit:

```lua
-- In your main server script
local Knit = require(game.ReplicatedStorage.Packages.Knit)

-- Require all services
local MemoryStore = require(path.to.MemoryStore)

-- Start Knit
Knit.Start():catch(warn):await()
```

4. Access the service from other Knit services:

```lua
-- In another Knit service
local Knit = require(game.ReplicatedStorage.Packages.Knit)
local MemoryStore = Knit.GetService("MemoryStore")

-- Now you can use MemoryStore methods
MemoryStore:SetHashMap("PlayerData", "Player_123", {coins = 500})
```

## Configuration

The module comes with default settings that can be adjusted before initializing:

```lua
-- Example of adjusting settings (do this before Knit.Start())
local MemoryStore = require(path.to.MemoryStore)

-- Modify settings
MemoryStore.Settings = {
    DefaultExpiryTime = 7200, -- 2 hours
    AutoCleanupInterval = 600, -- 10 minutes
    MaxSortedMapEntries = 200, -- More leaderboard entries
    QueueMaxSize = 1000, -- Larger queue capacity
    DebugMode = false, -- Disable debug logs in production
    WarningsEnabled = true,
    ErrorsEnabled = true
}
```

## Documentation

For detailed information on all available functions, please refer to:

- [API Documentation](./API.md) - Core functionality
- [Experimental Features](./EXP.md) - Features still in testing

## Error Handling

The module provides two bindable events for error management:

```lua
-- Listen for critical errors
MemoryStore.ErrorOccurred.Event:Connect(function(message, errorType)
    -- Log to external service or take corrective action
end)

-- Listen for non-critical warnings
MemoryStore.WarningOccurred.Event:Connect(function(message, warningType)
    -- Monitor or log warnings
end)
```