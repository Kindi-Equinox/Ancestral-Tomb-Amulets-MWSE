local data = require("kindi.ancestral tomb amulets.data")
local core = require("kindi.ancestral tomb amulets.core")
local playerData
local config

local function amuletEquipped(this)
    if not string.startswith(this.item.id, "ata_kindi_amulet_") then
        return
    end
    local item = this.item
    local equipor = this.mobile
    local itemdata = this.itemData
    local cell

    if itemdata and itemdata.data and itemdata.data.tomb then
        cell = itemdata.data.tomb
    end

    if not cell then
        this.itemData.data.tomb = tes3.getObject(this.item.id).itemData.data.tomb
    end

    if equipor == tes3.player.mobile then
        --equip normally
    elseif cell and equipor ~= tes3.player.mobile then
        --if not player then we make the wearer teleport to the tomb
        equipor:unequip {item = item}
        core.teleport(cell, equipor)
        equipor = nil
    end
end

--mod starts to work when the player finishes loading a game
local function loadDataAndCheckMod(loaded)
    playerData = tes3.player.data

    if not tes3.isModActive("Ancestral Tomb Amulets.esm") then
        tes3.messageBox {
            message = "[Ancestral Tomb Amulets] mod is missing the plugin file, ensure that the mod is installed properly.",
            buttons = {tes3.findGMST(26).value}
        }
        return
    end

    if not playerData.ata_kindi_data then
        playerData.ata_kindi_data = {}
    end

    playerData.ata_kindi_data.defaultTombs = playerData.ata_kindi_data.defaultTombs or {}
    playerData.ata_kindi_data.customTombs = playerData.ata_kindi_data.customTombs or {}
    playerData.ata_kindi_data.modifiedAmulets = playerData.ata_kindi_data.modifiedAmulets or {}
    playerData.ata_kindi_data.traversedCells = playerData.ata_kindi_data.traversedCells or {}
    playerData.ata_kindi_data.crateThatHoldsAllAmulets = nil
    playerData.ata_kindi_data.rejectedTombs = {}

    data.meta = {
        --if a new tomb is added, create an amulet for it
        __newindex = function(tombCategory, tomb, door)
            rawset(tombCategory, tomb, door)
            core.createAmuletForThisTomb(tomb)
        end,
        --combine contents of two tables
        __add = function(t1, t2)
            local tempT = {}
            for k, v in pairs(t1) do
                tempT[k] = v
            end
            for k, v in pairs(t2) do
                tempT[k] = v
            end
            return tempT
        end
    }

    data.superCrate = tes3.getReference("ata_kindi_dummy_crate")
    data.storageCrate = tes3.getReference("ata_kindi_dummy_crateLo")

    if data.superCrate and data.storageCrate then
        mwse.log("ATA storage has been set up!")
    else
        error("The master crate which holds all amulets cannot be found!, this mod will not work.", 2)
    end

    core.initialize()

    --amulet tooltip is lost every new game session, restore them here
    for _, ids in pairs(playerData.ata_kindi_data.modifiedAmulets) do
        core.setAmuletTooltips(ids)
    end

    mwscript.startScript {script = "Main"}

    if not tes3.getObject("atakinditelevfx") then
        tes3activator.create {
            id = "atakinditelevfx",
            mesh = "ata_kindi_tele.nif",
            name = "Beautiful Effect",
            script = "sprigganeffect"
        }
    end

    tes3ui.forcePlayerInventoryUpdate()
    tes3ui.updateInventoryTiles()
end

--when the player enters an interior cell, we commence the amulet placement
local function amuletCreationCellRecycle(e)
    local thisCell = e.cell or e

    if not config.modActive then
        return
    end

    if thisCell.id == "atakindidummycell" then
        return
    end

    --we only want to proceed if chargen is completed
    if tes3.findGlobal("ChargenState").value ~= -1 then
        return
    end

    --we only want to proceed if there was a previous cell (this is nil when loading a game)
    if not e.previousCell and not e.id then
        return
    end

    --here we recycle any amulet in the cell if the option is enabled
    if config.removeRecycle and data.plusChance == 0 and e.previousCell then
        for cont in e.previousCell:iterateReferences(tes3.objectType.container) do
            for _, item in pairs(cont.object.inventory) do
                if (item.object.id):match("ata_kindi_amulet_") then
                    tes3.transferItem {from = cont, to = data.superCrate, item = item.object.id, playSound = false}
                    data.plusChance = 10
                end
            end
        end
    end

    --we only want to place amulets inside interiors
    if not thisCell.isInterior then
        return
    end

    --if this is a tomb, and its amulet has not been placed anywhere yet, and if tomb raider option is enabled, then we remove this tomb from the cell limit (if enabled)
    for _, amulet in pairs(data.superCrate.object.inventory) do
        if amulet.variables[1].data.tomb == thisCell.id and config.tombRaider then
            table.removevalue(playerData.ata_kindi_data.traversedCells, thisCell.id)
        end
    end

    --we only want to proceed if this cell has not rolled for an amulet
    if table.find(playerData.ata_kindi_data.traversedCells, thisCell.id) then
        return
    end

    --we set this cell as "visited"
    table.insert(playerData.ata_kindi_data.traversedCells, thisCell.id)

    --if N of traversed cells exceeds max cycle config value, we remove the oldest cell in this list
    while table.size(playerData.ata_kindi_data.traversedCells) > tonumber(config.maxCycle) do
        if config.showReset then
            tes3.messageBox(playerData.ata_kindi_data.traversedCells[1] .. " can roll again")
        end
        table.remove(playerData.ata_kindi_data.traversedCells, 1)
    end

    --now we go to the more specific amulet placement process
    core.amuletCreation(thisCell)
end

event.register(
    "modConfigReady",
    function()
        require("kindi.ancestral tomb amulets.mcm")
        config = require("kindi.ancestral tomb amulets.config")
    end
)

local function openList(k)
    if tes3.menuMode() or tes3.onMainMenu() then
        return
    end

    if config.hotkey and k.keyCode == config.hotkeyOpenTable.keyCode then
        if tes3.findGlobal("ChargenState").value ~= -1 then
            tes3.messageBox("Table can only be opened after chargen is completed")
            return
        end
        core.showTombList()
    end
end

local function closeAtaTableRC()
    local todd = tes3ui.findMenu(ata_kindi_menuId)
	if todd then
    data.menuPosx = todd.positionX
    data.menuPosy = todd.positiony
    data.menuWidth = todd.width
    data.menuHeight = todd.height
	end
    if todd then
        core.alternate = false
        todd:destroy()
    end
end

local function getall()
    for a in tes3.getPlayerCell():iterateReferences(tes3.objectType.container) do
        for k, v in pairs(a.object.inventory) do
            if v.object.id:match("ata_kindi_amulet") then
                tes3.transferItem {from = a, to = tes3.player, item = v.object.id, playSound = true}
            end
        end
    end
    tes3ui.forcePlayerInventoryUpdate()
    tes3ui.updateInventoryTiles()
    amuletCreationCellRecycle(tes3.getPlayerCell())
end
event.register("keyDown", getall, {filter = tes3.scanCode.g})

event.register("equipped", amuletEquipped)
event.register("loaded", loadDataAndCheckMod)
event.register("cellChanged", amuletCreationCellRecycle)
event.register("keyDown", openList)
event.register("menuExit", closeAtaTableRC)
