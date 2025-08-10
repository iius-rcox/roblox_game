# Roblox Tycoon Game

A multiplayer tycoon game featuring 20 different tycoons based on popular anime and trending memes. Players can own multiple tycoons, steal abilities from others, and compete in a shared world.

## 🎮 Game Features

### Current Implementation (Milestone 0)
- **Single Tycoon Prototype**: Fully functional single-player tycoon experience
- **3-Floor Building**: Multi-level tycoon structure with destructible walls
- **Cash Generation**: Automatic money earning system with upgrades
- **6 Ability Buttons**: Upgradeable abilities including:
  - Double Jump
  - Speed Boost
  - Jump Boost
  - Cash Multiplier
  - Wall Repair
  - Teleport
- **Player Abilities**: Active ability effects with death/respawn system
- **Save System**: Data persistence for player progress
- **Modern UI**: Clean, responsive user interface

### Planned Features (Milestone 1-3)
- **Multiplayer Hub**: Central area for all players
- **Multiple Tycoons**: Own up to 3 different tycoons
- **Ability Theft**: Steal abilities from other players
- **Advanced Economy**: Cross-tycoon progression
- **Social Features**: Friends, trading, leaderboards

## 🚀 Quick Start

### Prerequisites
- Roblox Studio (latest version)
- Basic knowledge of Roblox development

### Installation
1. **Clone or Download** this repository
2. **Open Roblox Studio** and create a new place
3. **Copy the `src` folder** into your Roblox Studio project
4. **Set up the folder structure** in Studio:
   - Create a `ServerScriptService` folder
   - Create a `StarterPlayerScripts` folder
   - Create a `ReplicatedStorage` folder

### Setup Steps

#### 1. Server Setup
- Place `src/Server/MainServer.lua` in `ServerScriptService`
- Place `src/Server/SaveSystem.lua` in `ServerScriptService`

#### 2. Client Setup
- Place `src/Client/MainClient.lua` in `StarterPlayerScripts`

#### 3. Module Setup
- Place all files from `src/Tycoon/` in `ReplicatedStorage`
- Place all files from `src/Player/` in `ReplicatedStorage`
- Place all files from `src/Utils/` in `ReplicatedStorage`
- Place all files from `src/Hub/` in `ReplicatedStorage` (for future use)
- Place all files from `src/Multiplayer/` in `ReplicatedStorage` (for future use)

#### 4. Configure Studio Settings
- Enable **HTTP Requests** in Game Settings
- Set **Studio API Services** to enabled
- Configure **Security Settings** as needed

#### 5. Test the Game
- Press **Play** in Roblox Studio
- The game will automatically create a tycoon
- Players will spawn and be assigned to the tycoon
- Test the ability buttons and cash generation

## 🏗️ Architecture Overview

### Core Systems
```
src/
├── Server/           # Server-side logic
│   ├── MainServer.lua    # Main game server
│   └── SaveSystem.lua    # Data persistence
├── Client/           # Client-side logic
│   └── MainClient.lua    # Main client and UI
├── Tycoon/          # Tycoon components
│   ├── TycoonBase.lua    # Main tycoon structure
│   ├── CashGenerator.lua # Cash generation system
│   └── AbilityButton.lua # Ability upgrade buttons
├── Player/           # Player systems
│   ├── PlayerController.lua # Player management
│   ├── PlayerData.lua      # Player data storage
│   └── PlayerAbilities.lua # Ability effects
├── Utils/            # Utility functions
│   ├── Constants.lua       # Game configuration
│   └── HelperFunctions.lua # Helper utilities
├── Hub/              # Central hub (Milestone 1)
└── Multiplayer/      # Networking (Milestone 1)
```

### Data Flow
1. **Server Initialization**: Creates tycoon and sets up systems
2. **Player Joining**: Loads player data and assigns tycoon
3. **Game Loop**: Cash generation, ability upgrades, save system
4. **Client Updates**: Real-time UI updates via RemoteEvents

## 🎯 Game Mechanics

### Tycoon System
- **3 Floors**: Each floor provides different gameplay opportunities
- **Walls**: Destructible with auto-repair system
- **Owner Door**: Access control for tycoon ownership
- **Cash Generator**: Automatic income generation

### Ability System
- **6 Abilities**: Each with 10 upgrade levels
- **Progressive Costs**: Exponential cost scaling
- **Death Penalty**: Abilities reset on death
- **Reclaim System**: Re-earn abilities via buttons

### Economy System
- **Starting Cash**: $100 for new players
- **Cash Generation**: $10 per second base rate
- **Upgrade Costs**: $50 base, 1.5x multiplier per level
- **Auto-Save**: Every 30 seconds

## 🔧 Configuration

### Constants (src/Utils/Constants.lua)
```lua
Constants.TYCOON = {
    MAX_FLOORS = 3,
    WALL_HP = 100,
    CASH_GENERATION_BASE = 10,
    MAX_ABILITY_BUTTONS = 6
}

Constants.PLAYER = {
    WALK_SPEED = 16,
    JUMP_POWER = 50,
    MAX_HEALTH = 100
}

Constants.ECONOMY = {
    STARTING_CASH = 100,
    ABILITY_BASE_COST = 50,
    MAX_UPGRADE_LEVEL = 10
}
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Scripts Not Running
- Check that scripts are in the correct folders
- Ensure folder structure matches the architecture
- Check for syntax errors in the Output window

#### 2. Players Not Spawning
- Verify PlayerController is in StarterPlayerScripts
- Check that MainServer is in ServerScriptService
- Look for error messages in the Output window

#### 3. Cash Not Generating
- Ensure CashGenerator is properly initialized
- Check that players are assigned to tycoons
- Verify save system is working

#### 4. Abilities Not Working
- Check PlayerAbilities module is loaded
- Verify ability buttons are properly connected
- Look for input handling errors

### Debug Mode
Enable debug output by checking the Output window in Roblox Studio. The game provides detailed logging for:
- Player joining/leaving
- Tycoon creation
- Cash generation
- Save operations
- Error conditions

## 🚧 Development Status

### ✅ Completed (Milestone 0)
- [x] Single tycoon prototype
- [x] Basic player system
- [x] Cash generation
- [x] Ability system
- [x] Save/load system
- [x] User interface
- [x] Wall system

### ✅ Completed (Milestone 1)
- [x] Hub system (fully implemented)
- [x] Multiplayer networking (fully implemented)
- [x] Plot selection system (fully implemented)
- [x] Player interaction (fully implemented)
- [x] Plot claiming system (fully implemented)
- [x] Plot map UI (fully implemented)
- [x] Status synchronization (fully implemented)
- [x] DataStore persistence (NEW: Hub data persistence)
- [x] Plot ownership restoration (NEW: Players keep plots after rejoin)

### 📋 Planned (Milestone 2-3)
- [ ] Multiple tycoon ownership
- [ ] Cloud save system
- [ ] Advanced abilities
- [ ] Social features
- [ ] Performance optimization

## 🤝 Contributing

This is a learning project for Roblox development. Feel free to:
- Report bugs and issues
- Suggest new features
- Improve existing code
- Add documentation

## 📝 License

This project is open source and available under the MIT License.

## 🎮 Play the Game

Once set up in Roblox Studio, you can:
1. **Test Locally**: Use Studio's Play button
2. **Publish**: Upload to Roblox for multiplayer testing
3. **Customize**: Modify constants and add new features

## 📚 Learning Resources

- [Roblox Developer Hub](https://developer.roblox.com/)
- [Lua Programming](https://www.lua.org/)
- [Roblox API Reference](https://developer.roblox.com/en-us/api-reference)

---

**Happy Building! 🏗️💰**
