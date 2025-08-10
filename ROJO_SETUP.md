# 🚀 Rojo Setup Guide for Roblox Tycoon Game

## What is Rojo?

Rojo is a tool that allows you to develop Roblox games using external text editors while automatically syncing your code to Roblox Studio. This gives you the best of both worlds: powerful development tools and seamless Roblox integration.

## ✅ What's Already Set Up

- **Rojo 7.5.1** installed on your system
- **`default.project.json`** configured to map your `src` folder to Roblox Studio
- **Automatic file syncing** between your local files and Studio

## 🎯 How It Works

1. **Local Development**: Edit your `.lua` files in Cursor/VS Code
2. **Automatic Sync**: Rojo automatically syncs changes to Roblox Studio
3. **Real-time Testing**: Test your changes immediately in Studio
4. **Version Control**: Keep your code in Git while working in Studio

## 🚀 Getting Started

### Step 1: Start the Rojo Server

```bash
# In your project directory
rojo serve
```

### Step 2: Install Rojo Plugin in Roblox Studio

1. Open Roblox Studio
2. Go to **Plugins** → **Marketplace**
3. Search for "Rojo" and install the plugin
4. Or use the command: `rojo plugin install`

### Step 3: Connect to Rojo

1. In Roblox Studio, click the **Rojo** plugin
2. Click **Connect** to connect to your local Rojo server
3. Your files will automatically sync!

## 📁 File Structure Mapping

Your local `src` folder maps to these Roblox Studio locations:

```
📁 ServerScriptService/
  📁 Tycoon/          ← src/Tycoon/
  📁 Hub/             ← src/Hub/
  📁 Multiplayer/     ← src/Multiplayer/
  📁 Competitive/     ← src/Competitive/
  📁 Utils/           ← src/Utils/
  📁 MainServer/      ← src/Server/

📁 ReplicatedStorage/
  📁 Shared/          ← src/Utils/ (as ModuleScripts)
  📁 Modules/         ← src/Player/ (as ModuleScripts)

📁 StarterPlayer/
  📁 StarterPlayerScripts/ ← src/Player/PlayerController.lua
  📁 StarterGui/           ← src/Hub/ (UI scripts)

📁 ReplicatedFirst/
  📄 MainClient.lua        ← src/Client/MainClient.lua
```

## 🔧 Development Workflow

### 1. Edit Files Locally
```bash
# Edit any .lua file in your src folder
code src/Tycoon/AbilityButton.lua
```

### 2. Auto-Sync to Studio
- Changes automatically appear in Roblox Studio
- No need to copy-paste or manually sync
- Test immediately in Studio

### 3. Version Control
```bash
# Commit your changes
git add .
git commit -m "Updated ability button system"

# Push to remote
git push origin main
```

## 🎮 Testing Your Game

1. **Start Rojo server**: `rojo serve`
2. **Connect Rojo plugin** in Studio
3. **Play the game** in Studio
4. **Make changes locally** and watch them sync automatically
5. **Test immediately** without restarting

## 🛠️ Useful Commands

```bash
# Start Rojo server
rojo serve

# Build .rbxl file (for sharing)
rojo build -o game.rbxl

# Check Rojo status
rojo --version

# Get help
rojo --help
```

## 🔍 Troubleshooting

### Rojo Server Won't Start
- Check if port 34872 is available
- Restart terminal/command prompt
- Verify Rojo installation: `rojo --version`

### Files Not Syncing
- Ensure Rojo plugin is connected in Studio
- Check Rojo server is running
- Verify file paths in `default.project.json`

### Script Errors
- Check Roblox Studio Output window for errors
- Verify script types (Script vs LocalScript vs ModuleScript)
- Check require() paths match new structure

## 🎯 Benefits of This Setup

1. **Professional Development**: Use powerful text editors
2. **Automatic Syncing**: No manual file copying
3. **Version Control**: Track all changes in Git
4. **Team Collaboration**: Multiple developers can work simultaneously
5. **Better Testing**: Real-time sync for immediate testing
6. **Code Quality**: Use linters, formatters, and language servers

## 🚀 Next Steps

1. **Start Rojo server**: `rojo serve`
2. **Open Roblox Studio** and install Rojo plugin
3. **Connect to Rojo** and start developing!
4. **Edit files locally** and watch them sync automatically

Your Roblox Tycoon Game is now set up for professional development with automatic file syncing! 🎉
