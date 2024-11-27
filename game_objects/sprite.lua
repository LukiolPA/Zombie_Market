require "game_objects/hitbox"

local sprites_list = {}

function newSprite(pTexture, pPosition, pScale, pOrigin, pAngle)
    pPosition = pPosition or newVector2D(0, 0)
    pAngle = pAngle or 0
    pScale = pScale or {x = 1, y = 1}
    pOrigin = pOrigin or newVector2D(0, 0)

    local sprite = {
        texture = pTexture,
        pos = pPosition,
        angle = pAngle,
        scale = pScale,
        origin = pOrigin,
        hitboxes_list = {},
        width,
        height,
        isFree = false
    }
    sprite.type = "SPRITE"

    if pTexture then
        sprite.width = sprite.texture:getWidth() * sprite.scale.x
        sprite.height = sprite.texture:getHeight() * sprite.scale.y
        sprite.radius = math.max(sprite.width, sprite.height) / 2
    else
        sprite.width = 0
        sprite.height = 0
        sprite.radius = 0
    end

    --create one circular hitbox with size and position defined as a fraction of sprite's dimensions
    --for instance pRelativePosition (0.5, 0.5) is middle if sprite's origin is top-left, or bottom-right if sprite"s origin is middle
    --hitbox's radius pRelativeRadius is a fraction of sprite's max dimension
    function sprite.createCircleHitbox(pRelativePosition, pRelativeRadius)
        pRelativePosition = pRelativePosition or newVector2D(0, 0)
        pRelativeRadius = pRelativeRadius or 1

        local local_x = pRelativePosition.x * sprite.width
        local local_y = -pRelativePosition.y * sprite.height
        local hitbox_radius = pRelativeRadius * sprite.radius
        local new_hitbox = newCircleHitbox(newVector2D(local_x, local_y), hitbox_radius)
        table.insert(sprite.hitboxes_list, new_hitbox)
    end

    function sprite.update(dt)
        sprite.manageCollisions()
    end

    function sprite.updateHitbox()
        for _, hitbox in ipairs(sprite.hitboxes_list) do
            hitbox.update(sprite.pos, sprite.angle)
        end
    end

    function sprite.isCollidingRectangle(rect_sprite)
        for _, rect_hitbox in ipairs(rect_sprite.hitboxes_list) do
            for _, circle_hitbox in ipairs(sprite.hitboxes_list) do
                if circle_hitbox.collideRectangle(rect_hitbox) then
                    return true
                end
            end
        end
        return false
    end

    --returns all collided sprites with rectangle hitbox
    --sprite can't collide with itself
    function sprite.collidedRectangles(rect_list)
        local detected_collisions = {}
        for _, rect_sprite in pairs(rect_list) do
            if sprite ~= rect_sprite and sprite.isCollidingRectangle(rect_sprite) then
                table.insert(detected_collisions, rect_sprite)
            end
        end
        return detected_collisions
    end

    --must be overloaded if sprite is rectangle
    function sprite.isCollidingSprite(other_sprite)
        for _, other_hitbox in ipairs(other_sprite.hitboxes_list) do
            for _, hitbox in ipairs(sprite.hitboxes_list) do
                if hitbox.collideCircle(other_hitbox) then
                    return true
                end
            end
        end
        return false
    end

    --returns all collided sprites with circle hitbox, among sprite_list
    --sprite can't collide with itself
    function sprite.collidedCircles(sprite_list)
        local detected_collisions = {}
        for _, other_sprite in pairs(sprite_list) do
            if sprite ~= other_sprite and sprite.isCollidingSprite(other_sprite) then
                table.insert(detected_collisions, other_sprite)
            end
        end
        return detected_collisions
    end

    --if not overloaded, colliding with exit sign is just like colliding with rectangle
    function sprite.collideWithExit(exit)
        if sprite.collideWithRectangle then
            sprite.collideWithRectangle(exit)
        end
    end

    --abstract method, visitor pattern
    function sprite.getCollided(collider)
    end

    function sprite.manageCollisions()
        for _, other_sprite in ipairs(sprites_list) do
            if sprite ~= other_sprite then
                sprite.getCollided(other_sprite)
            end
        end
    end

    --abstract method
    function sprite.updateState()
    end

    function sprite.draw()
        if sprite.texture then
            love.graphics.draw(sprite.texture, sprite.pos.x, sprite.pos.y, sprite.angle, sprite.scale.x, sprite.scale.y, sprite.origin.x, sprite.origin.y)
        end
    end

    function sprite.isOnScreen(camera)
        local left_side = sprite.pos.x - sprite.origin.x * sprite.scale.x
        local right_side = sprite.pos.x - sprite.origin.x * sprite.scale.x + sprite.width
        local top_side = sprite.pos.y - sprite.origin.y * sprite.scale.y
        local bottom_side = sprite.pos.y - sprite.origin.y * sprite.scale.y + sprite.height
        return right_side > camera.pos.x and left_side < camera.pos.x + screen.width and bottom_side > camera.pos.y and top_side < camera.pos.y + screen.height
    end

    --abstract
    function sprite.printState()
    end

    function sprite.free()
        sprite.isFree = true
        for _, hitbox in ipairs(sprite.hitboxes_list) do
            hitbox.isFree = true
        end
    end

    table.insert(sprites_list, sprite)
    return sprite
end

function initSprites()
    for _, sprite in ipairs(sprites_list) do
        if sprite.init then
            sprite.init()
        end
    end
end
function updateSprites(dt)
    for _, sprite in ipairs(sprites_list) do
        sprite.update(dt)
    end
    --manageCollisions()
    updateStates()
end

function manageCollisions()
    for _, sprite in ipairs(sprites_list) do
        sprite.manageCollisions()
    end
end

function drawSprites(camera)
    for _, sprite in ipairs(getSprites("SPRITE")) do
        if sprite.isOnScreen(camera) then
            sprite.draw()
        end
    end

    for _, sprite in ipairs(getSprites("RECTANGLE")) do
        if sprite.isOnScreen(camera) then
            sprite.draw()
        end
    end

    for _, sprite in ipairs(getSprites("EXIT")) do
        if sprite.isOnScreen(camera) then
            sprite.draw()
        end
    end

    for _, sprite in ipairs(getSprites("SHELF")) do
        if sprite.isOnScreen(camera) then
            sprite.draw()
        end
    end

    for _, sprite in ipairs(getSprites("ZOMBIE")) do
        if sprite.isOnScreen(camera) then
            sprite.draw()
        end
    end

    for _, sprite in ipairs(getSprites("CART")) do
        if sprite.isOnScreen(camera) then
            sprite.draw()
        end
    end
    for _, sprite in ipairs(getSprites("ITEM")) do
        if sprite.isOnScreen(camera) then
            sprite.draw()
        end
    end
end

function printStates(camera)
    for _, sprite in ipairs(sprites_list) do
        if sprite.isOnScreen(camera) then
            sprite.printState()
        end
    end
end

function freeSprites()
    for i = #sprites_list, 1, -1 do
        if sprites_list[i].isFree then
            table.remove(sprites_list, i)
        end
    end
    freeHitboxes()
end

function updateStates()
    for _, sprite in ipairs(sprites_list) do
        if sprite.updateState then
            sprite.updateState()
        end
    end
end

function getSprites(pType)
    local sprites_found = {}
    for _, sprite in ipairs(sprites_list) do
        if sprite.type == pType then
            table.insert(sprites_found, sprite)
        end
    end
    return sprites_found
end

function unloadSprites()
    for i = #sprites_list, 1, -1 do
        if sprites_list[i].type ~= "CART" then
            table.remove(sprites_list, i)
        end
    end
    freeHitboxes()
end

--unused function, may not be necessary
-- function deleteSprite(sprite)
--     for i = 1, #sprites_list do
--         if sprites_list[i] == sprite then
--             table.remove(sprites_list, i)
--         end
--     end
-- end
