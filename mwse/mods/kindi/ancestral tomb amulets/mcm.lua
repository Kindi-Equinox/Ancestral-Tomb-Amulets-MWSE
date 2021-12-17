local data = require("kindi.ancestral tomb amulets.data")
local core = require("kindi.ancestral tomb amulets.core")
local config = require("kindi.ancestral tomb amulets.config")

local EasyMCM = require("easyMCM.EasyMCM")

local template =
    EasyMCM.createTemplate {
    name = "Ancestral Tomb Amulets",
    onClose = function()
        mwse.saveConfig("ancestral_tomb_amulets", config)
    end
}

local page =
    template:createSideBarPage {
    label = "Main",
    description = "All the main setup for the mod is in this page\n"
}

local switch = page:createCategory("Main")
switch:createOnOffButton {
    label = "Mod Status",
    variable = EasyMCM.createTableVariable {id = "modActive", table = config},
    description = "The state of the mod.",
    callback = function()
        if config.modActive then
            tes3.messageBox("ON")
        else
            tes3.messageBox("OFF")
        end
    end
}

switch:createButton {
    label = "Reset all main settings to defaults",
    buttonText = "Default",
    description = "All main settings will be reset to default values",
    callback = function()
        config.modActive = true
        config.chance = 7.5
        config.maxCycle = 75
        config.useBestCont = false
        config.littleSecret = false
        config.tombRaider = false
        config.showSpawn = false
        config.showReset = false
        config.affectScripted = false
        config.dangerFactor = true
        config.removeRecycle = false
        config.hotkey = true
        config.hotkeyOpenTable = {keyCode = tes3.scanCode.k}
        config.hotkeyOpenModifier = {keyCode = tes3.scanCode.lShift}

        core.refreshMCM()

        tes3.messageBox("Settings reset to Defaults")
    end
}

local chanceCycle = page:createCategory("Chance and Cycle")
chanceCycle:createTextField {
    label = "Base Chance",
    variable = EasyMCM.createTableVariable {id = "chance", table = config},
    description = "Adjust the base chance to obtain the amulets\n100% chance means all interior cells will always have an amulet to search for provided there is a valid container inside\nA negative(-) value means no amulet can be found in any cell and added chance from other options is ignored.\nMaximum value: 100\nDefault value: 7.5",
    numbersOnly = true,
    callback = function()
        if tonumber(config.chance) > 100 then
            config.chance = 100
        end
    end
}

chanceCycle:createTextField {
    label = "Max Cycle",
    variable = EasyMCM.createTableVariable {id = "maxCycle", table = config},
    description = "How many different cells to be traversed before a cell can roll for amulets again after visiting it\nMinimum value: 0\nDefault value: 75",
    numbersOnly = true,
    callback = function()
        if tonumber(config.maxCycle) < 0 then
            config.maxCycle = 0
        end
    end
}

local keybind = page:createCategory("Hotkeys and Modifiers")
keybind:createOnOffButton {
    label = "ON\\OFF Hotkey",
    variable = EasyMCM.createTableVariable {id = "hotkey", table = config},
    description = "When ON, you can use hotkey to open the table",
    callback = function()
        if config.hotkey then
            tes3.messageBox("HOTKEY: ON")
        else
            tes3.messageBox("HOTKEY: OFF")
        end
    end
}

keybind:createKeyBinder {
    label = "Hotkey to open the ancestral tomb amulets table",
    description = "Hotkey to open a table list of all ancestral tomb amulets that have been collected",
    variable = EasyMCM.createTableVariable {id = "hotkeyOpenTable", table = config},
    defaultSetting = {
        keyCode = tes3.scanCode.k
    }
}

keybind:createKeyBinder {
    label = "Modifier to open the alternate ancestral tomb amulets table",
    description = "Enable more information in the table",
    variable = EasyMCM.createTableVariable {id = "hotkeyOpenModifier", table = config},
    defaultSetting = {
        keyCode = tes3.scanCode.lShift
    }
}

local gameplay = page:createCategory("Gameplay")
gameplay:createYesNoButton {
    label = "Chance will also depend on cell danger factor",
    variable = EasyMCM.createTableVariable {id = "dangerFactor", table = config},
    description = "Dangerous cells, ie. cells that contain powerful enemies or many aggressive actors will have a higher chance to have an amulet inside\nFor example, there is a better chance to find an amulet inside a daedric or dwemer ruin compared to common houses or town buildings.\nThe chance from this will be added to the base chance.",
    callback = function()
        if config.dangerFactor then
            tes3.messageBox("Danger factor is ON")
        else
            tes3.messageBox("Danger factor is OFF")
        end
    end
}

gameplay:createYesNoButton {
    label = "Remove and recycle amulet",
    variable = EasyMCM.createTableVariable {id = "removeRecycle", table = config},
    description = "If an amulet is inside a cell but you exited the cell before obtaining it, the amulet will be removed from the cell and the next cell you visit will have 10% more chance to contain an amulet\nAny cell before this option is activated is not affected.\nThe chance from this will be added to the base chance.",
    callback = function()
        if config.removeRecycle then
            tes3.messageBox("Remove and recycle is ON")
        else
            tes3.messageBox("Remove and recycle is OFF")
        end
    end
}

gameplay:createYesNoButton {
    label = "Best container",
    variable = EasyMCM.createTableVariable {id = "useBestCont", table = config},
    description = "Amulet will spawn inside the best container in the cell, ie. container with the largest capacity.\n",
    callback = function()
        if config.useBestCont then
            tes3.messageBox("Pick best container")
        else
            tes3.messageBox("Pick random container")
        end
    end
}

gameplay:createYesNoButton {
    label = "Tomb raider",
    variable = EasyMCM.createTableVariable {id = "tombRaider", table = config},
    description = "An amulet can always be found inside its associated ancestral tomb if it has not been placed elsewhere yet (yellow)\nIf base chance is negative, this will have no effect.\nIgnores cell cycling.",
    callback = function()
        if config.tombRaider then
            tes3.messageBox("Tomb raider")
        else
            tes3.messageBox("No tomb raiding")
        end
    end
}

local scripted = page:createCategory("Scripted Containers")
scripted:createYesNoButton {
    label = "Scripted Containers",
    variable = EasyMCM.createTableVariable {id = "affectScripted", table = config},
    description = "If yes, then amulets can appear inside scripted containers\nSome mods attach local scripts to containers, for quests or scripted events.\nThis option will prevent unimmersive or unwanted situations to happen.\nSome mods also attach local scripts to base containers, but it is generally not a good practice now\nSetting this to NO is recommended unless you really know what you want.",
    callback = function()
        if config.affectScripted then
            tes3.messageBox("Amulets can appear inside scripted containers")
        else
            tes3.messageBox("Scripted containers will not have amulets")
        end
    end
}

local page2 =
    template:createExclusionsPage {
    label = "Blocked Cells",
    description = "Blocked cells will not spawn ancestral tomb amulets. They still count for cell cycling.\n",
    toggleText = "Toggle Filtered Cells",
    leftListLabel = "Blocked Cells",
    rightListLabel = "Allowed Cells",
    showAllBlocked = false,
    variable = EasyMCM.createTableVariable {
        id = "blockedCells",
        table = config
    },
    filters = {
        {
            label = "Blacklist Cells",
            callback = (function()
                local tombs = {}
                for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
                    if cell.isInterior and cell.id ~= "atakindidummycell" then
                        table.insert(tombs, cell.id)
                    end
                end
                return tombs
            end)
        }
    }
}

local page3 = template:createSideBarPage {label = "Help"}

page3:createCategory {label = data.otherLabel}
page3:createHyperlink {text = "Modpage", exec = string.format("start %s", data.links.modpage)}
page3:createHyperlink {text = "Watch Demo", exec = string.format("start %s", data.links.video)}
page3:createButton {
    inGameOnly = true,
    label = "Hints",
    buttonText = "Hints",
    description = "Table:\n\nGray color-> This amulet has not spawned yet\nYellow color-> The amulet is somewhere in the world, but not in your possession\nBlue color-> Amulet for this tomb is in your possession\nClick-> Teleport to the tomb\nModifier+Click-> Equip amulet\nAlt+Click-> Open Wiki\nShift+Hover-> Reveal the location of the amulet (yellow only)\nClick +/- -> Store or return the amulet\n\n\nGameplay:\n\nTomb Raider-> Set base chance to 0, and 'Tomb Raider' active to make amulets spawn only inside Ancestral Tombs\n",
    callback = function()
        tes3.messageBox("Read")
    end
}

page3:createButton {
    inGameOnly = true,
    label = "Fixes all bad amulets in the game",
    buttonText = "Clean",
    description = "If you feel there's an issue with the mod, this may fix your issue, otherwise help submit a bug report.\n\nUse as much as you can,",
    callback = function()
        core.dropBad()
    end
}

page3:createButton {
    inGameOnly = true,
    label = "Reset all amulets",
    buttonText = "Reset",
    description = "Use this if you wish to recollect all amulets. Amulets will be recreated",
    callback = function()
        core.hardReset()
    end
}
page3:createButton {
    inGameOnly = true,
    label = "Removes all amulets and progress from the game",
    buttonText = "Uninstall",
    description = "WARNING: All progress will be lost, mod will not function. To undo, press RESET\n",
    callback = function()
        core.hardReset(true)
    end
}
page3:createButton {
    inGameOnly = true,
    label = "Give all amulets for all ancestral tombs in the game\nPress Reset button first before using",
    buttonText = "Give All",
    description = "Press RESET first before using.",
    callback = function()
        core.cheat()
    end
}

page3:createOnOffButton {
    label = "Amulet Inside Container: Show container name",
    variable = EasyMCM.createTableVariable {id = "showSpawn", table = config},
    description = "This is for debugging, use only for testing",
    callback = function()
        if config.showSpawn then
            tes3.messageBox("ON")
        else
            tes3.messageBox("OFF")
        end
    end
}
page3:createOnOffButton {
    label = "Notify Cell Reset: Show cell name and the container name",
    variable = EasyMCM.createTableVariable {id = "showReset", table = config},
    description = "This is for debugging, use only for testing",
    callback = function()
        if config.showReset then
            tes3.messageBox("ON")
        else
            tes3.messageBox("OFF")
        end
    end
}

EasyMCM.register(template)
