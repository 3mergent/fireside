# Fireside

A modular dashboard addon for World of Warcraft TBC Classic (2.5.5) featuring a flexible applet system.

## Features

- **Modular Applet Architecture**: Easy to extend with new applets
- **XP Tracker**: Real-time experience tracking with detailed statistics
  - Current XP percentage
  - XP per hour calculation
  - Kills remaining to level
  - Time to level estimation
- **Draggable Windows**: Position applets anywhere on screen
- **Lock/Unlock System**: Prevent accidental window movement
- **Persistent Settings**: Positions and preferences saved between sessions

## Installation

1. Download or clone this repository
2. Copy the `Fireside` folder to `World of Warcraft/_classic_/Interface/AddOns/`
3. Restart WoW or reload UI
4. Enable the addon at character select

## Usage

### Commands

- `/fireside toggle` - Show/hide all applets
- `/fireside lock` - Lock all applets in place
- `/fireside unlock` - Unlock applets for repositioning
- `/fireside settings` - Open settings panel
- `/fireside reset` - Reset all window positions
- `/fireside list` - List all registered applets
- `/fireside help` - Display command list

Short form: `/fs` works as an alias for `/fireside`

### First Time Setup

1. After logging in, the XP Tracker will appear automatically
2. Use `/fireside unlock` to drag windows to your preferred positions
3. Use `/fireside lock` to lock them in place
4. Use `/fireside settings` to enable/disable specific applets

## Development

### File Structure

```
Fireside/
├── Fireside.toc              # Addon metadata and file load order
├── Core/
│   ├── Init.lua              # Main addon initialization
│   ├── Dashboard.lua         # Dashboard manager (controls all applets)
│   └── Applet.lua            # Base applet class/framework
├── Applets/
│   └── XPTracker.lua         # XP tracking applet
└── Settings.lua              # Settings UI and configuration
```

### Creating New Applets

To create a new applet:

1. Create a new file in `Applets/` directory
2. Extend the base `Fireside.Applet` class
3. Implement `OnInitialize()` method for custom UI and logic
4. Register the applet with `Fireside.Dashboard:RegisterApplet(yourApplet)`
5. Add the file to `Fireside.toc`

Example:

```lua
local MyApplet = Fireside.Applet:New("MyApplet", 200, 100)

function MyApplet:OnInitialize()
    -- Create UI elements
    -- Register events
    -- Set up update handlers
end

Fireside.Dashboard:RegisterApplet(MyApplet)
```

## Compatibility

- **WoW Version**: TBC Classic 2.5.5 (pre-patch)
- **Interface**: 20505
- **API Level**: TBC Classic (2.x)

## License

MIT License - See LICENSE file for details

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.
