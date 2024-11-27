function newShelf(pTexture, pPosition, pSize, pNbRows, pNbColumns, pItemType, pRelativeOrigin)
    pItemType = pItemType or "ITEM"
    pNbRows = pNbRows or 1
    pNbColumns = pNbColumns or 1
    pRelativeOrigin = pRelativeOrigin or newVector2D(0.5, 0.5)

    local shelf = newRectangle(pTexture, pPosition, pSize, pRelativeOrigin)
    shelf.type = "SHELF"
    local SPAWNING_PERIOD = 15
    local timer = 0
    shelf.itemSpawnersList = {}

    function shelf.init()
        for i = 1, pNbRows do
            local y_pos = shelf.pos.y - shelf.origin.y * shelf.scale.y + shelf.height / (pNbRows + 1) * i
            for j = 1, pNbColumns do
                local x_pos = shelf.pos.x - shelf.origin.x * shelf.scale.x + shelf.width / (pNbColumns + 1) * j
                local angle = math.rad(love.math.random(0, 360))
                local sp = newItemSpawner(pItemType, newVector2D(x_pos, y_pos), angle, SPAWNING_PERIOD)

                sp.update = nil --those don't get an update function, the shelf will manage their update
                table.insert(shelf.itemSpawnersList, sp)
            end
        end
        shelf.createRectangleHitbox(newVector2D(-0.5, -0.5), {x = 1, y = 1})
        shelf.updateHitbox()
    end

    function shelf.update(dt)
        if not shelf.isFull() then -- timer will start when first item is picked from shelf.
            timer = timer + dt
        end
        if timer > SPAWNING_PERIOD then
            timer = 0
            for _, spawner in ipairs(shelf.itemSpawnersList) do
                spawner.spawn() --they all spawn at the same time
            end
        end
        shelf.manageCollisions()
    end

    function shelf.isFull()
        for _, sp in ipairs(shelf.itemSpawnersList) do
            if sp.item == nil then
                return false
            end
        end
        return true
    end

    return shelf
end
