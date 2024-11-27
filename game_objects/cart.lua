local SHOPPING_STATES = {
    NOTSHOPPING = "not shopping",
    SHOPPING = "shopping"
}

local INVINCIBILITY_STATES = {
    INVINCIBLE = "invincible",
    VINCIBLE = "not invincible"
}

--those are constant values
local INITIAL_ANGLE = math.pi / 2
local INITIAL_POS = newVector2D(0, 0)
local INITIAL_MASS = 25 --kg

local FORCE = 37500 --FORCE to push or pull shopping cart
local FRICTIONAL_FORCE = 18750 --friction opposed to cart's translation
local ROTATION_FORCE = 1000 --FORCE to rotate cart
local ROTATION_FRICTIONAL_FORCE = 500 --friction opposed to cart's rotation
local WALL_FRICTION_FORCE = FRICTIONAL_FORCE --how much friction is increased when sliding on walls
local MAX_VELOCITY = 500
local MAX_ROTATION_SPEED = 30
local INITIAL_HP = 10

local MASS_TO_WIN = 125
local ENERGY_TO_WIN = 0.5 * 0.5 * MASS_TO_WIN * MAX_VELOCITY ^ 2
local MASS_TO_CRUSH = 75
local ENERGY_TO_CRUSH = 0.25 * 0.5 * MASS_TO_CRUSH * MAX_VELOCITY ^ 2

local SHOPPING_RANGE = 90
local SHOPPING_DELAY = 1

local INVINCIBILITY_DURATION = 2
local BLINKING_PERIOD = 0.3

--the shopping cart
local img = love.graphics.newImage("images/man_and_cart.png")
local pos = INITITAL_POS
local angle = INITIAL_POS
local scale = {x = 0.15, y = 0.15}
local origin = newVector2D(img:getWidth() * 0.37, img:getHeight() * 0.5)
local cart = newSprite(img, pos, scale, origin, angle)
cart.type = "CART"

local previous_pos
local previous_angle
local previous_velocity

local invincibility_timer
local alpha_blending

local shopping_timer

function cart.init()
    cart.pos = INITIAL_POS.clone()
    cart.angle = INITIAL_ANGLE

    cart.initialMass = INITIAL_MASS
    cart.mass = cart.initialMass
    cart.velocity = newVector2D(0, 0)
    cart.acceleration = newVector2D(0, 0) --proportional to 1/mass
    cart.friction = newVector2D(0, 0) --proportional to 1/mass
    cart.rotationSpeed = 0
    cart.rotationAcceleration = 0 --proportional to 1/mass
    cart.rotationFriction = 0 --proportional to 1/mass
    cart.cineticEnergy = 0 -- =1/2*mass*velocity^2

    cart.collisionDetected = false

    local invincibility_timer = INVINCIBILITY_DURATION  
    local alpha_blending = 1

    cart.HP = INITIAL_HP

    cart.invincibilityState = INVINCIBILITY_STATES.VINCIBLE

    cart.itemPossessed = {}
    shopping_timer = 0
    cart.shoppingState = SHOPPING_STATES.NOTSHOPPING

    cart.createCircleHitbox(newVector2D(-0.18, 0), 0.3)
    cart.createCircleHitbox(newVector2D(0, 0), 0.4)
    cart.createCircleHitbox(newVector2D(0.2, 0), 0.38)
    cart.createCircleHitbox(newVector2D(0.39, 0), 0.36)
    cart.createCircleHitbox(newVector2D(0.47, 0), 0.33)
    cart.createCircleHitbox(newVector2D(0.58, -0.3), 0.08)
    cart.createCircleHitbox(newVector2D(0.58, 0.3), 0.08)

    cart.updateHitbox()
end

--rectangle delimiting the actual area of the cart without the character, inside which items can be placed
--when cart position is (0,0) and angle is 0 (transformations are made afterwards)
--TODO, make this code more clean
function cart.getInsideRectangle()
    local xmin = 0.45 * cart.width - cart.origin.x * cart.scale.x
    local ymin = 0.1 * cart.height - cart.origin.y * cart.scale.y
    local xmax = xmin + cart.width * 0.55
    local ymax = ymin + cart.height * 0.8
    return xmin, ymin, xmax, ymax
end

function cart.update(dt)
    previous_pos = cart.pos.clone()
    previous_angle = cart.angle
    previous_velocity = cart.velocity.clone()

    cart.updatePhysics(dt)
    cart.move(dt)
    cart.manageCollisions()
    if cart.collisionDetected == true then -- movement is cancel and we slide
        cart.pos = previous_pos.clone()
        cart.angle = previous_angle
        cart.velocity = previous_velocity.clone()
        cart.updateHitbox()
        cart.slide(dt)
        cart.collisionDetected = false
    end

    if cart.invincibilityState == INVINCIBILITY_STATES.INVINCIBLE then
        cart.blink(dt)
    end
end

function cart.updatePhysics(dt)
    --acceleration sign depends on key pressed
    if love.keyboard.isScancodeDown("w") then
        cart.updateTranslation(dt, 1)
    elseif love.keyboard.isScancodeDown("s") then
        cart.updateTranslation(dt, -1)
    elseif cart.velocity.norm() > 0 then
        cart.updateTranslation(dt, 0)
    end

    if love.keyboard.isScancodeDown("a") then
        cart.updateRotation(dt, -1)
    elseif love.keyboard.isScancodeDown("d") then
        cart.updateRotation(dt, 1)
    elseif cart.rotationSpeed ~= 0 then
        cart.updateRotation(dt, 0)
    end
    cart.cineticEnergy = 0.5 * cart.mass * (cart.velocity.norm() ^ 2)
end

function cart.move(dt)
    cart.pos = cart.pos + cart.velocity * dt
    cart.angle = cart.angle + cart.rotationSpeed * dt
    cart.updateHitbox()
    cart.moveItems()
end

--recalculate translation and rotation by considering collision
function cart.slide(dt)
    local velocityAngle = cart.velocity.angle()

    --first recalculate translation
    --newVelocity is estimated before checking collisions
    local newVelocity = cart.velocity + (cart.acceleration + cart.friction) * dt
    if newVelocity.norm() > MAX_VELOCITY then --if velocity is to high, it's reduced to limit
        newVelocity = newVelocity.normalize() * MAX_VELOCITY
    end

    --xpos and ypos are updated separately so the cart can slide on the walls
    cart.pos.x = cart.pos.x + newVelocity.x * dt
    cart.updateHitbox()
    local nb_collisions = cart.countCollisions()
    if nb_collisions >= 1 then --stop cart on x-axis
        cart.pos.x = previous_pos.x --move cart to previous position
        newVelocity.x = 0
        cart.friction.x = 0
        cart.acceleration.x = 0

        if math.abs(cart.velocity.y) > 0 then
            cart.friction.y = cart.friction.y + WALL_FRICTION_FORCE * -math.sin(velocityAngle) / cart.mass
        else
            cart.friction.y = 0
        end
    end
    cart.pos.y = cart.pos.y + newVelocity.y * dt
    cart.updateHitbox()
    nb_collisions = cart.countCollisions()
    if nb_collisions >= 1 then --stop cart on y-axis
        cart.pos.y = previous_pos.y --move cart to previous position
        newVelocity.y = 0
        cart.friction.y = 0
        cart.acceleration.y = 0
        if math.abs(cart.velocity.x) > 0 then
            cart.friction.x = cart.friction.x + WALL_FRICTION_FORCE * -math.cos(velocityAngle) / cart.mass
        else
            cart.friction.x = 0
        end
    end
    cart.updateHitbox()

    --calculate actual new velocity with frictions due to colision
    if newVelocity.x ~= 0 then
        newVelocity.x = cart.velocity.x + (cart.acceleration.x + cart.friction.x) * dt
    end
    if newVelocity.y ~= 0 then
        newVelocity.y = cart.velocity.y + (cart.acceleration.y + cart.friction.y) * dt
    end
    if newVelocity.norm() > MAX_VELOCITY then --if velocity is to hight, it comes down to limit
        newVelocity = newVelocity.normalize() * MAX_VELOCITY
    end
    cart.velocity = newVelocity

    --then recalculate rotation
    cart.angle = cart.angle + cart.rotationSpeed * dt
    cart.updateHitbox()
    local nb_collisions = cart.countCollisions()
    if nb_collisions >= 1 then
        cart.angle = previous_angle
        cart.rotationAcceleration = 0
        cart.rotationFriction = 0
        cart.rotationSpeed = 0
    end

    cart.updateHitbox()
    cart.moveItems()
    cart.cineticEnergy = 0.5 * cart.mass * (cart.velocity.norm() ^ 2)
end

--only called when state is changing
function cart.setState(newState)
    if newState == INVINCIBILITY_STATES.INVINCIBLE then
        cart.invincibilityState = newState
        invincibility_timer = 0
    elseif newState == INVINCIBILITY_STATES.VINCIBLE then
        cart.invincibilityState = newState
        cart.setAlpha(1)
    elseif newState == SHOPPING_STATES.NOTSHOPPING then
        cart.shoppingState = newState
    elseif newState == SHOPPING_STATES.SHOPPING then
        cart.shoppingState = newState
    end
end

--called every frame
function cart.updateState()
    if cart.invincibilityState == INVINCIBILITY_STATES.INVINCIBLE then
        if invincibility_timer >= INVINCIBILITY_DURATION then --stop blinking
            cart.setState(INVINCIBILITY_STATES.VINCIBLE)
        end
    elseif cart.invincibilityState == INVINCIBILITY_STATES.VINCIBLE then
    end

    if cart.shoppingState == SHOPPING_STATES.NOTSHOPPING then
    elseif cart.shoppingState == SHOPPING_STATES.SHOPPING then
    end
end

function cart.updateHitbox()
    for _, hitbox in ipairs(cart.hitboxes_list) do
        hitbox.update(cart.pos, cart.angle)
    end
end

function cart.countCollisions()
    local count = #cart.collidedRectangles(getSprites("RECTANGLE"))
    count = count + #cart.collidedCircles(getSprites("ZOMBIE"))
    count = count + #cart.collidedRectangles(getSprites("SHELF"))
    count = count + #cart.collidedRectangles(getSprites("EXIT"))
    return count
end

--visitor design pattern
function cart.getCollided(collider)
    if collider.collideWithCart ~= nil then
        collider.collideWithCart(cart)
    end
end

function cart.collideWithZombie(zombie)
    if cart.isCollidingSprite(zombie) then
        if cart.canCrush(zombie) then
            cart.velocity = cart.velocity * 0.75
            cart.dropItems(math.ceil(#cart.itemPossessed * 0.1))
        else
            cart.collisionDetected = true
        end
    end
end

function cart.canCrush(zombie)
    local collision_direction = (zombie.pos - cart.pos).normalize().dot(cart.velocity.normalize())
    return collision_direction > 0.5 and cart.mass >= MASS_TO_CRUSH and cart.cineticEnergy >= ENERGY_TO_CRUSH
end

function cart.collideWithRectangle(rectangle)
    if cart.isCollidingRectangle(rectangle) then
        cart.collisionDetected = true
    end
end

function cart.collideWithExit(exit)
    if cart.isCollidingRectangle(exit) then
        local collision_direction = (exit.pos - cart.pos).normalize().dot(cart.velocity.normalize())
        if collision_direction > 0.5 and cart.mass >= MASS_TO_WIN and cart.cineticEnergy >= ENERGY_TO_WIN then
            print("test")
            exit.free()
            changeScene("victory")
        else
            cart.collisionDetected = true
        end
    end
end

--way = 1 means cart accelerates forward, -1 is backward, 0 is no acceleration
function cart.updateTranslation(dt, way)
    local velocityAngle = cart.velocity.angle()
    local acceleration = way * FORCE / cart.mass
    local friction = FRICTIONAL_FORCE / cart.mass

    cart.acceleration.x = acceleration * math.cos(cart.angle)
    cart.acceleration.y = acceleration * math.sin(cart.angle)

    if math.abs(cart.acceleration.x) < 0.001 then
        cart.acceleration.x = 0
    end

    if math.abs(cart.acceleration.y) < 0.001 then
        cart.acceleration.y = 0
    end

    --friction vector has direction opposite to speed vector
    if math.abs(cart.velocity.x) > 0 then
        cart.friction.x = friction * -math.cos(velocityAngle)
    else
        cart.friction.x = 0
    end
    if math.abs(cart.velocity.y) > 0 then
        cart.friction.y = friction * -math.sin(velocityAngle)
    else
        cart.friction.y = 0
    end

    --cart must stop if too slow and no button is pressed
    if way == 0 then
        --here acceleration is 0, so speed can just be compared to friction
        if math.abs(cart.velocity.x) < math.abs(cart.friction.x * dt) then
            cart.velocity.x = 0
            cart.acceleration.x = 0
            cart.friction.x = 0
        end
        if math.abs(cart.velocity.y) < math.abs(cart.friction.y * dt) then
            cart.velocity.y = 0
            cart.acceleration.y = 0
            cart.friction.y = 0
        end
    end

    cart.velocity = cart.velocity + (cart.acceleration + cart.friction) * dt
    if cart.velocity.norm() > MAX_VELOCITY then --if velocity is to high, it comes down to limit
        cart.velocity = cart.velocity.normalize() * MAX_VELOCITY
    end
end

function cart.moveItems()
    for _, item in ipairs(cart.itemPossessed) do
        item.follow(cart)
    end
end

--way = 1 means rotation accelerates clockwise, -1 is counterclockwise, 0 is no acceleration
function cart.updateRotation(dt, way)
    cart.rotationAcceleration = way * ROTATION_FORCE / cart.mass

    --rotation friction is opposite to rotation speed
    if cart.rotationSpeed > 0 then
        cart.rotationFriction = -ROTATION_FRICTIONAL_FORCE / cart.mass
    else
        cart.rotationFriction = ROTATION_FRICTIONAL_FORCE / cart.mass
    end
    cart.rotationSpeed = cart.rotationSpeed + (cart.rotationAcceleration + cart.rotationFriction) * dt

    --if rotation is too slow, it stops
    if way == 0 and math.abs(cart.rotationSpeed) <= math.abs(cart.rotationFriction * dt) then
        cart.rotationSpeed = 0
        cart.rotationFriction = 0
    end
    --if rotation is too fast, it gets back to maximum rotation speed
    cart.rotationSpeed = math.min(MAX_ROTATION_SPEED, math.max(-MAX_ROTATION_SPEED, cart.rotationSpeed))
end

function cart.takeDamage(amount)
    if cart.invincibilityState == INVINCIBILITY_STATES.VINCIBLE then
        if cart.HP > amount then
            cart.HP = cart.HP - amount
            cart.setState(INVINCIBILITY_STATES.INVINCIBLE)
            cart.dropItems(math.ceil(#cart.itemPossessed * 0.1))
        else
            cart.HP = 0
            changeScene("defeat")
        end
    end
end

--aim at mouse position
function cart.throwItem(mouseX, mouseY)
    local angle_cart_mouse = (newVector2D(mouseX, mouseY) - cart.pos).angle()
    for i = #cart.itemPossessed, 1, -1 do
        if not cart.itemPossessed[i].isFree then
            cart.itemPossessed[i].getThrowned(angle_cart_mouse)
            cart.mass = cart.mass - cart.itemPossessed[i].mass
            table.remove(cart.itemPossessed, i)
            break
        end
    end
end

function cart.dropItems(amount)
    for i = 1, amount do
        local nb_item = #cart.itemPossessed
        if nb_item > 0 then
            local item = cart.itemPossessed[nb_item]
            cart.mass = cart.mass - item.mass
            item.getDropped()
            table.remove(cart.itemPossessed, nb_item)
        end
    end
end

--blink during invicibility
function cart.blink(dt)
    invincibility_timer = invincibility_timer + dt
    --alpha transparency oscillate between 1 and 0 with a period of BLINKING_PERIOD
    local alpha = (math.cos(invincibility_timer * math.pi / BLINKING_PERIOD) + 1) / 2
    cart.setAlpha(alpha)
end

function cart.setAlpha(alpha)
    alpha_blending = alpha
    for _, item in ipairs(cart.itemPossessed) do
        item.setAlpha(alpha)
    end
end

--gain item from nearest detected spawner that is not empty
function cart.shop()
    local detected_spawners = {}
    for _, spawner in ipairs(getSpawners("ITEM_SPAWNER")) do
        if spawner.item ~= nil and spawner.isInShoppingRange(cart.pos, SHOPPING_RANGE) then
            table.insert(detected_spawners, spawner)
        end
    end

    function compareDistance(spawner1, spawner2)
        if cart.pos.distance(spawner1.pos) < cart.pos.distance(spawner2.pos) then
            return true
        else
            return false
        end
    end

    if #detected_spawners > 1 then
        --sort spawners found in range by distance to cart, and steal item from the closest
        table.sort(detected_spawners, compareDistance)
    end

    if #detected_spawners > 0 then
        detected_spawners[1].giveItem(cart)
    end
end

function cart.pickUpItem(item)
    item.getPickedUp()
    table.insert(cart.itemPossessed, item)
    cart.mass = cart.mass + item.mass
end

--for UI
function cart.getHPColor()
    if cart.HP == INITIAL_HP then
        return newColor(1, 1, 0) --yellow
    elseif cart.HP == 1 then
        return newColor(0.53, 0.03, 0.03) --dark red
    else
        return newColor(1, 1, 1) --white
    end
end

function cart.getMassColor()
    if cart.mass < MASS_TO_CRUSH then
        return newColor(1, 1, 1) --white
    elseif cart.mass < MASS_TO_WIN then
        return newColor(0.53, 0.03, 0.03) --dark red
    else
        return newColor(1, 1, 0) --yellow
    end
end

function cart.getSpeedColor()
    if cart.velocity.norm() == MAX_VELOCITY then
        return newColor(1, 1, 0) --yellow
    else
        return newColor(1, 1, 1) --white
    end
end

function cart.getEnergyColor()
    if cart.cineticEnergy < ENERGY_TO_CRUSH then
        return newColor(1, 1, 1) --white
    elseif cart.cineticEnergy < ENERGY_TO_WIN then
        return newColor(0.53, 0.03, 0.03) --dark red
    else
        return newColor(1, 1, 0) --yellow
    end
end

function cart.draw()
    if cart.texture then
        love.graphics.setColor(1, 1, 1, alpha_blending)
        love.graphics.draw(cart.texture, cart.pos.x, cart.pos.y, cart.angle, cart.scale.x, cart.scale.y, cart.origin.x, cart.origin.y)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function cart.printState()
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(cart.shoppingState, cart.pos.x - cart.width * 0.5, cart.pos.y - cart.height * 0.5 - 20)
    love.graphics.print(cart.invincibilityState, cart.pos.x - cart.width * 0.5, cart.pos.y + cart.height * 0.5)
    love.graphics.setColor(1, 1, 1)
end

return cart
