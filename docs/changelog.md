# Changelog
Find all the recent changelog notes here, all versions are also found on the GitHub Repository.

(Dates are in DD/MM/YYYY)
# V0.0.3
8/04/2025

### **MemoryStore Changes**
---

### **Documentation Page** 
- Updated the [Cleanup System API documentation page](https://memorystore-api-documentation.readthedocs.io/en/main/API/#cleanup-system).
- Other information should still be up-to-date, if not they'll be added into this update log.

### **Changes & Improvements**
| Type    | Description |
|---------|-------------|
| **Fix** | Replaced broken `Trove:AddTask()` call in `:StartAutoCleanup()` with a proper `task.spawn`-based loop using `task.wait()`. |
| **Fix** | Removed unnecessary success check after `SetAsync()` in `SetHashMap()` — the method returns `nil`, not a success value. |
| **Added** | Implemented `MemoryStore:GetQueueLength()` method to support queue size checks in `Enqueue()`. |
| **Added** | `MemoryStore:StopAutoCleanup()` to allow stopping the auto-cleanup task at runtime. |
| **Refactor** | Simplified `withRetry()` logic and improved debug output with attempt-specific failure info. |
| **Refactor** | Cleaned up `ForceCleanupCycle()` warning message to include task name and error info. |
| **Refactor** | Removed redundant `return` statements after `throwError()` calls (which already `error()`). |
| **Refactor** | Improved naming consistency and documentation comments across all public methods. |

---

### **Stability & Behavior**
| Area | Behavior |
|------|----------|
| Auto-Cleanup | Now runs on a consistent interval using `task.wait`, no longer reliant on invalid Trove timing. |
| Error Handling | Centralized error and warning messages used across the board with consistent formatting. |
| Retry Logic | More robust retry mechanism with exponential backoff and clearer logging per attempt. |

---

# V0.0.2
12/03/2025

**Documentation Page**

- Added a new category "Help!"
- Added a new subcategory "Errors Explained" to "Help!"
- Added a new subcategory "How Do I?" to "Help!" for new users.

**MemoryStore Changes**

- Cleanup tasks are now out of testing and live with additional functions, click [here](https://memorystore-api-documentation.readthedocs.io/en/main/API/#cleanup-system) for the documentation.

# V0.0.1

