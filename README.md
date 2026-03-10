# FS25_SILODB - Centralized Database Manager

A centralized database mod for Farming Simulator 25 that provides a global `SILODB` API for other mods to store and retrieve persistent key-value data.

## Features

- **Namespace isolation** - Each mod gets its own data space, no collisions
- **Persistent storage** - Data survives game restarts (saved in savegame directory)
- **Simple API** - 5 functions: `setValue`, `getValue`, `deleteValue`, `listKeys`, `isReady`
- **Console commands** - Developer tools for debugging: `dbSet`, `dbGet`, `dbDelete`, `dbList`, `dbHelp`
- **Clean Architecture** - Infrastructure, persistence, use cases, and interfaces are fully separated
- **Multiplayer ready** - Data persists per savegame

## Quick Start (For Mod Developers)

### Check if SILODB is available

```xml
<modDesc>
  <name>My Mod</name>
  <version>1.0.0</version>
  <author>LeGrizzly</author>
  <description>A mod that uses FS25_SILODB for data storage.</description>
  <dependencies>
    <dependency name="FS25_SILODB" />
  </dependencies>
</modDesc>
```

```lua
-- Safe to use the API
local SILODB = g_globalMods["FS25_SILODB"]
```

### Store and retrieve data

```lua
local ns = "FS25_MyMod"  -- Your mod name as namespace

-- Store values
SILODB.setValue(ns, "playerScore", 42)
SILODB.setValue(ns, "settings", { difficulty = "hard", sound = true })

-- Retrieve values
local score = SILODB.getValue(ns, "playerScore")  -- 42
local settings = SILODB.getValue(ns, "settings")   -- { difficulty = "hard", sound = true }

-- Delete a key
SILODB.deleteValue(ns, "playerScore")

-- List all keys in your namespace
local keys = SILODB.listKeys(ns)  -- { "settings" }
```

### Supported value types

| Type | Example |
|------|---------|
| string | `"hello"` |
| number | `42`, `3.14` |
| boolean | `true`, `false` |
| table | `{ key = "value" }`, `{ 1, 2, 3 }` |

## Console Commands

Available in the developer console (`~` key):

| Command | Description | Example |
|---------|-------------|---------|
| `dbSet <ns> <key> <value>` | Store a value | `dbSet FS25_MyMod score 100` |
| `dbGet <ns> <key>` | Retrieve a value | `dbGet FS25_MyMod score` |
| `dbDelete <ns> <key>` | Delete a key | `dbDelete FS25_MyMod score` |
| `dbList <ns>` | List all keys | `dbList FS25_MyMod` |
| `dbHelp` | Show help | `dbHelp` |

## Installation

1. Download the latest release ZIP
2. Place it in your FS25 mods folder (`Documents/My Games/FarmingSimulator2025/mods/`)
3. Enable the mod in the game's mod manager
4. Other mods can now use `local SILODB = g_globalMods["FS25_SILODB"]` after the map loads

## Architecture

See [docs/architecture.md](docs/architecture.md) for the full architecture overview.

```
scripts/
  main.lua                       -- DI container & mod lifecycle
  infrastructure/FlatDB.lua      -- NoSQL engine (JSON-based)
  persistence/DatabaseAdapter.lua -- FS25 savegame adapter
  usecases/
    SetValue.lua                 -- Store business logic
    GetValue.lua                 -- Retrieve business logic
    DeleteValue.lua              -- Delete business logic
    ListKeys.lua                 -- List business logic
  interfaces/
    ConsoleInterface.lua         -- Developer console commands
    GlobalAPI.lua                -- Public g_globalMods["FS25_SILODB"] API builder
  utils/json.lua                 -- JSON encoder/decoder
```

## API Reference

See [docs/API.md](docs/API.md) for the complete API documentation.

## License

MIT
