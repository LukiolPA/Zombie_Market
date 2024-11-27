local item_onshelf_img = love.graphics.newImage("images/strawberry.png")
local item_onshelf_origin = newVector2D(item_onshelf_img:getWidth() / 2, item_onshelf_img:getHeight() / 2)
-- local item_thrown_img = love.graphics.newImage("images/egg_thrown.png")
-- local item_thrown_origin = newVector2D(item_thrown_img:getWidth() / 2, item_thrown_img:getHeight() / 2)

local ITEMSTATES = {
    ONSHELF = "on shelf",
    INCART = "in cart",
    THROWN = "thrown",
    DROPPED = "on the floor"
}

function newItem(pPosition, pAngle)
    pAngle = pAngle or 0
    scale = {x = 0.30, y = 0.30}
    local item = newSprite(item_onshelf_img, pPosition, scale, item_onshelf_origin, pAngle)
    item.type = "ITEM"

    item.state = ITEMSTATES.ONSHELF

    item.relativePosition = newVector2D(0, 0) --position relative to parent (cart)
    local SPEED = 300 --norm wanted for velocity when thrown
    item.velocity = newVector2D(0, 0)
    item.shootingRange = 400 -- max range of thrown item
    local lifetime = item.shootingRange / SPEED

    --item.mass = 0.075 --kg
    item.mass = 2 --TODO, to ajust, wayyyyyyyyyy too heavy for strawberries
    item.damageDealt = 2

    local FADING_DURATION = 3
    local alpha_blending = 1

    function item.init()
        item.createCircleHitbox()
    end

    --only called when state is changing
    function item.setState(newState)
        item.state = newState
        local cart = getSprites("CART")[1]

        if newState == ITEMSTATES.ONSHELF then
        elseif newState == ITEMSTATES.INCART and cart then
            item.randomlyPutInCart(cart)
        elseif newState == ITEMSTATES.THROWN and cart then
            item.pos = cart.pos.clone()
            item.updateHitbox()
            item.velocity = newVector2D(math.cos(item.angle) * SPEED, math.sin(item.angle) * SPEED)
            alpha_blending = 1
        elseif newState == ITEMSTATES.DROPPED then
            alpha_blending = 1
        end
    end

    function item.update(dt)
        if item.state == ITEMSTATES.THROWN then
            lifetime = lifetime - dt
            if lifetime <= 0 then
                item.free()
            else
                item.fly(dt)
            end
        elseif item.state == ITEMSTATES.INCART and cart then
            local cart = getSprites("CART")[1]
            item.follow(cart)
        elseif item.state == ITEMSTATES.DROPPED then
            alpha_blending = alpha_blending - (dt / FADING_DURATION)
            if alpha_blending <= 0 then
                item.free()
            end
        end
        item.manageCollisions()
    end

    function item.fly(dt)
        item.pos.x = item.pos.x + item.velocity.x * dt
        item.pos.y = item.pos.y + item.velocity.y * dt
        item.updateHitbox()
    end

    --follow cart, when item is contained in it
    function item.follow(cart)
        --formula to rotate object around parent origin
        local offset_x = item.relativePosition.x * math.cos(cart.angle) + item.relativePosition.y * math.sin(cart.angle)
        local offset_y = item.relativePosition.x * math.sin(cart.angle) - item.relativePosition.y * math.cos(cart.angle)
        item.pos = cart.pos + newVector2D(offset_x, offset_y)
        item.updateHitbox()
    end

    function item.getPickedUp()
        if not item.isFree and item.state == ITEMSTATES.ONSHELF then
            item.setState(ITEMSTATES.INCART)
        end
    end

    function item.getThrowned(pAngle)
        if item.state == ITEMSTATES.INCART then
            item.angle = pAngle
            item.setState(ITEMSTATES.THROWN)
        end
    end

    function item.getDropped()
        if item.state == ITEMSTATES.INCART then
            item.setState(ITEMSTATES.DROPPED)
        end
    end

    --visitor design pattern
    function item.getCollided(collider)
        if not item.isFree and collider.collideWithItem ~= nil then
            collider.collideWithItem(item)
        end
    end

    function item.collideWithZombie(zombie)
        if item.state == ITEMSTATES.THROWN and item.isCollidingSprite(zombie) then
            item.free()
            zombie.takeDamage(item.damageDealt)
        end
    end

    function item.collideWithRectangle(rectangle)
        if item.state == ITEMSTATES.THROWN and item.isCollidingRectangle(rectangle) then
            item.free()
        end
    end

    function item.randomlyPutInCart(cart)
        --relative position of actual cart area in wich to place items
        local xmin, ymin, xmax, ymax = cart.getInsideRectangle()

        local new_x = love.math.random(xmin + item.width / 2, xmax - item.width / 2)
        local new_y = love.math.random(ymin + item.height / 2, ymax - item.height / 2)
        item.relativePosition = newVector2D(new_x, new_y)
        item.angle = math.rad(love.math.random(0, 360))
        item.follow(cart)
    end

    function item.setAlpha(alpha)
        alpha_blending = alpha
    end

    function item.draw()
        if item.texture then
            love.graphics.setColor(1, 1, 1, alpha_blending)
            love.graphics.draw(item.texture, item.pos.x, item.pos.y, item.angle, item.scale.x, item.scale.y, item.origin.x, item.origin.y)
            love.graphics.setColor(1, 1, 1, 1)
        end
    end

    return item
end
