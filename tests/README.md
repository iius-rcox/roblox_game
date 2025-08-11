# Anime Tycoon Game - Testing Guide

This folder contains comprehensive testing tools for the Anime Tycoon game. The testing system has been designed to work both with proper Rojo synchronization and as standalone scripts in Roblox Studio.

## 🚀 Quick Start

### Option 1: Simple Testing (Recommended for Studio)
Use `SimpleTest.lua` for immediate testing without folder dependencies:

1. **Place in ServerScriptService**: Copy `SimpleTest.lua` into your game's ServerScriptService
2. **Run the game**: The script will automatically execute and show results
3. **Check output**: Look at the output window for test results

### Option 2: Quick Testing
Use `QuickTest.lua` for basic system validation:

1. **Place in ServerScriptService**: Copy `QuickTest.lua` into ServerScriptService
2. **Run the game**: Script executes automatically
3. **View results**: Check the output for detailed test information

### Option 3: Full Test Suite
Use the complete testing system with proper Rojo sync:

1. **Sync via Rojo**: Ensure the entire `tests/` folder is synced
2. **Use RunTests.lua**: Place in ServerScriptService
3. **Execute tests**: Full test suite will run automatically

## 📁 File Structure

```
tests/
├── README.md              # This file - testing instructions
├── SimpleTest.lua         # Simple test launcher (recommended)
├── QuickTest.lua          # Basic system validation
├── RunTests.lua           # Full test suite launcher
├── TestRunner.lua         # Comprehensive test runner
└── QuickTest.lua          # Command bar testing script
```

## 🔧 Troubleshooting

### Common Issues

#### 1. "script.Parent is nil" Error
**Problem**: Script can't find its parent folder
**Solution**: 
- Use `SimpleTest.lua` instead of `RunTests.lua`
- Ensure script is placed in ServerScriptService
- Check that the script is a Script, not a LocalScript

#### 2. "TestRunner not found" Error
**Problem**: Can't locate the TestRunner script
**Solution**:
- Use `SimpleTest.lua` for basic testing
- Check Rojo synchronization if using full test suite
- Verify file paths in `default.project.json`

#### 3. Scripts not running
**Problem**: Tests don't execute automatically
**Solution**:
- Ensure script is in ServerScriptService (not StarterPlayer or other locations)
- Check that script is enabled
- Verify script is a Script (not LocalScript)

### Testing Without Rojo

If you don't have Rojo set up or the folder structure isn't synced:

1. **Use SimpleTest.lua**: This script works independently
2. **Copy scripts manually**: Place test scripts directly in Roblox Studio
3. **Check output**: All results will be displayed in the output window

## 🧪 What Gets Tested

### Basic Tests (SimpleTest.lua)
- ✅ Game services availability
- ✅ ServerScriptService functionality
- ✅ ReplicatedStorage access
- ✅ Player system status
- ✅ Basic performance metrics
- ✅ Memory management

### Advanced Tests (Full Suite)
- ✅ System integration
- ✅ Core game systems
- ✅ Network functionality
- ✅ Performance optimization
- ✅ Security validation
- ✅ Anime system integration

## 📊 Understanding Results

### Test Results Format
```
🎯 TEST EXECUTION COMPLETE
============================================================
Total tests run: 7
Tests passed: 7
Tests failed: 0
Success rate: 100.0%

🎉 PERFECT SCORE! All tests passed!
```

### Result Categories
- **100%**: Perfect - All systems operational
- **80-99%**: Good - Minor issues, mostly functional
- **60-79%**: Mixed - Some systems need attention
- **Below 60%**: Poor - Many systems failing

## 🚨 Error Handling

The test system includes comprehensive error handling:

- **Graceful fallbacks**: If one test fails, others continue
- **Detailed error messages**: Specific information about what went wrong
- **Multiple loading methods**: Tries different approaches to find test files
- **Minimal test runner**: Creates basic tests if full suite unavailable

## 💡 Best Practices

### For Development
1. **Run tests frequently**: Test after each major change
2. **Check output carefully**: Look for warnings and errors
3. **Fix issues promptly**: Address test failures before they compound
4. **Use appropriate tests**: Simple tests for quick checks, full suite for validation

### For Production
1. **Pre-deployment testing**: Run full test suite before release
2. **Performance monitoring**: Watch for performance test results
3. **Security validation**: Ensure security tests pass
4. **Documentation**: Keep test results for reference

## 🔄 Updating Tests

When adding new game features:

1. **Add test cases**: Create tests for new functionality
2. **Update existing tests**: Modify tests to cover new features
3. **Maintain compatibility**: Ensure tests work with current game version
4. **Document changes**: Update this README with new test information

## 📞 Support

If you encounter issues:

1. **Check this README**: Many common issues are covered here
2. **Use SimpleTest.lua**: This script has the most robust error handling
3. **Check Rojo sync**: Ensure files are properly synchronized
4. **Review error messages**: Specific error details help identify problems

## 🎯 Next Steps

After running tests:

1. **Review results**: Understand what passed and what failed
2. **Address issues**: Fix any failing tests
3. **Run again**: Verify that fixes resolved the problems
4. **Expand testing**: Add tests for new features as they're developed

---

**Happy Testing! 🧪✨**

The testing system is designed to help you build a robust, reliable Anime Tycoon game. Use it regularly to catch issues early and ensure your game runs smoothly.
