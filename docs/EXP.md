# Experimental Functions

!!! danger "**⚠️ WARNING ⚠️**"
    The functions documented in this page are public and available for use, but they **have not been thoroughly tested in production environments**. We cannot guarantee their reliability or performance. Use them at your own risk and thoroughly test in development environments before deploying to production.

## Auto-Cleanup System

The experimental auto-cleanup system aims to prevent memory leaks and resource consumption by automatically removing expired entries from MemoryStore containers.

### StartAutoCleanup

Initializes the automatic cleanup process based on the configured interval.

```lua
MemoryStore:StartAutoCleanup()
```

**Behavior:**
- Creates a scheduled task using Trove that runs at intervals defined by `Settings.AutoCleanupInterval`
- Calls `ClearExpiredEntries()` on each interval
- Reports errors through the ErrorOccurred event if cleanup fails

!!! note
    This function is called automatically during service initialization. The cleanup interval defaults to 300 seconds (5 minutes).


**Example of manually restarting cleanup:**
```lua
-- Only use if you've previously stopped the cleanup or need to restart it
MemoryStore:StartAutoCleanup()
```

### ClearExpiredEntries

Performs the actual cleanup operation by removing expired entries from all containers.

```lua
MemoryStore:ClearExpiredEntries()
```

**Behavior:**
- Attempts to identify and remove expired entries from HashMaps, SortedMaps, and Queues
- Reports warnings through the WarningOccurred event if cleanup encounters non-critical issues

!!! warning
    The current implementation is incomplete. The function exists but the actual logic for identifying and removing expired entries is not fully implemented.

**Example of manual cleanup:**
```lua
-- Force an immediate cleanup
MemoryStore:ClearExpiredEntries()
```

!!! warning "Important"
    Manually calling this function is not recommended until the implementation is complete.


## Current Limitations

The experimental auto-cleanup system has the following limitations:

1. The actual implementation of identifying and removing expired entries is not yet complete
2. There's no tracking of which entries have been created or when they expire
3. The system may not be efficient for large numbers of entries
4. Error handling during cleanup needs further refinement

!!! info "Tip"
    Until the auto-cleanup system is fully implemented, consider manually managing expired entries or implementing your own cleanup logic.


## Future Improvements

Planned enhancements for the auto-cleanup system include:

1. Implementing a tracking system for created entries and their expiry times
2. Adding selective cleanup for specific containers
3. Improving error reporting with more detailed diagnostics
4. Adding statistics collection for cleanup operations
5. Implementing more efficient batch processing for large datasets

!!! note
    We welcome community feedback and contributions to improve the experimental features. Please report any issues or suggestions for improvement.


## Development Status

!!! info "**Development Status: Alpha**"
    functions are in early development stage and subject to significant changes. They are included in the public API to gather feedback and allow for early testing in non-critical environments.
