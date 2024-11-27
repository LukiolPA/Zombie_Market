local spawners_list = {}
local DEFAULT_PERIOD = 15

function newSpawner(pPosition, pPeriod) --this is abstract
    local spawner = {}
    spawner.pos = pPosition
    spawner.period = pPeriod
    spawner.timer = 0
    spawner.type = "spawner"

    function spawner.update(dt)
        spawner.increaseTimer(dt)
        if spawner.timer >= spawner.period then
            spawner.spawn()
            spawner.timer = 0
        end
    end

    function spawner.increaseTimer(dt)
        spawner.timer = spawner.timer + dt
    end

    function spawner.spawn()
    end

    function spawner.draw()
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("line", spawner.pos.x, spawner.pos.y, 10)
        love.graphics.setColor(1, 1, 1)
    end

    return spawner
end

function newZombieSpawner(pPosition, pAngle, pPeriod)
    pPeriod = pPeriod or DEFAULT_PERIOD

    local zombie_img = love.graphics.newImage("images/zombie.png")
    local zombie_origin = newVector2D(zombie_img:getWidth() / 2, zombie_img:getHeight() / 2)
    local angle = pAngle
    local MAX_NB_ZOMBIES = 50 --max number of zombies that can spawn
    local MAX_DETECTION_RANGE = 700 -- spawner is only active when player is in range
    local MIN_DETECTION_RANGE = 200 -- zombie won't spawn too close from player

    local zombieSpawner = newSpawner(pPosition, pPeriod)
    zombieSpawner.type = "ZOMBIE_SPAWNER"

    function zombieSpawner.increaseTimer(dt)
        local cart = getSprites("CART")[1]
        local current_nb_zombies = #getSprites("ZOMBIE")
        local distance = zombieSpawner.pos.distance(cart.pos)
        -- spawner is only active when player is in range and when there are not too much zombies
        if current_nb_zombies < MAX_NB_ZOMBIES and cart and distance <= MAX_DETECTION_RANGE and distance >= MIN_DETECTION_RANGE then
            zombieSpawner.timer = zombieSpawner.timer + dt
        end
    end

    function zombieSpawner.spawn()
        local spawn_angle = love.math.random(-math.pi / 6, math.pi / 6) + angle --randomize starting angle a bit
        local new_zombie = newZombie(zombie_img, zombieSpawner.pos, spawn_angle, zombie_origin)
        new_zombie.init()
        --zombie only spawns if spawner's area is empty
        if zombieSpawner.isOccupied(new_zombie) then
            new_zombie.free()
        end
    end

    function zombieSpawner.isOccupied(new_zombie)
        --count collision with most colliders
        local count = #new_zombie.collidedCircles(getSprites("ZOMBIE"))
        count = count + #new_zombie.collidedCircles(getSprites("CART"))
        count = count + #new_zombie.collidedRectangles(getSprites("RECTANGLE"))
        count = count + #new_zombie.collidedRectangles(getSprites("SHELF"))
        count = count + #new_zombie.collidedRectangles(getSprites("EXIT"))
        if count > 0 then
            return true
        else
            return false
        end
    end

    table.insert(spawners_list, zombieSpawner)

    return zombieSpawner
end

function newItemSpawner(pItemType, pPosition, pAngle, pPeriod)
    pPeriod = pPeriod or DEFAULT_PERIOD
    local angle = pAngle

    local itemSpawner = newSpawner(pPosition, pPeriod)
    itemSpawner.type = "ITEM_SPAWNER"
    itemSpawner.item = nil

    function itemSpawner.increaseTimer(dt)
        if itemSpawner.item == nil then
            itemSpawner.timer = itemSpawner.timer + dt
        end
    end

    function itemSpawner.spawn()
        if itemSpawner.item == nil then
            if pItemType == "ITEM" then
                itemSpawner.item = newItem(pPosition, pAngle)
            end
            if itemSpawner.item then
                itemSpawner.item.init()
            end
        end
    end

    --also kind of a visitor pattern ?
    function itemSpawner.giveItem(player)
        if player.pickUpItem then
            player.pickUpItem(itemSpawner.item)
            itemSpawner.item = nil
        end
    end

    function itemSpawner.isInShoppingRange(player_position, range)
        return itemSpawner.item ~= nil and player_position.distance(itemSpawner.pos) < range
    end

    itemSpawner.spawn() --we want items to spawn when the game is launched

    table.insert(spawners_list, itemSpawner)

    return itemSpawner
end

function updateSpawners(dt)
    for _, spawner in ipairs(spawners_list) do
        if spawner.update then
            spawner.update(dt)
        end
    end
end

function drawSpawners()
    for _, spawner in ipairs(spawners_list) do
        spawner.draw()
    end
end

function unloadSpawners()
    for i = #spawners_list, 1, -1 do
        table.remove(spawners_list, i)
    end
end

function getSpawners(pType)
    local spawners_found = {}
    for _, spawner in ipairs(spawners_list) do
        if spawner.type == pType then
            table.insert(spawners_found, spawner)
        end
    end
    return spawners_found
end
