local STATES = {
    WAIT = "wait",
    WANDER = "wander",
    FOLLOW = "follow",
    STUNNED = "stunned"
}

local ANIMATION_STATES = {
    NOANIM = "no anim",
    ISHIT = "is hit"
}

function newZombie(pTexture, pPosition, pAngle, pOrigin)
    local scale = {x = 0.2, y = 0.2}

    local zombie = newSprite(pTexture, pPosition, scale, pOrigin, pAngle)
    zombie.type = "ZOMBIE"

    zombie.huntingSpeed = 60
    zombie.wanderingSpeed = 15
    zombie.waitingDuration = 5
    zombie.wanderingDuration = 8
    zombie.stunnedDuration = 2
    zombie.speed = zombie.huntingSpeed
    zombie.velocity = newVector2D(0, 0)
    local previousPos = zombie.pos

    zombie.state = STATES.WAIT
    local patternTimer = 0
    zombie.target = nil
    zombie.detectionRange = 200
    zombie.forgetRange = 300

    zombie.animationState = ANIMATION_STATES.NOANIM
    local HIT_ANIMATION_DURATION = 1
    local animation_timer = HIT_ANIMATION_DURATION
    local coloration = newColor(1, 1, 1)

    zombie.hp = 3
    zombie.damageDealt = 1

    function zombie.init()
        zombie.setState(STATES.WANDER)
        zombie.createCircleHitbox()
        zombie.updateHitbox()
    end

    --only called when state is changing
    function zombie.setState(newState)
        if newState == STATES.WAIT then
            zombie.state = newState
            zombie.target = nil
            patternTimer = zombie.waitingDuration
            zombie.speed = 0
        elseif newState == STATES.STUNNED then
            zombie.state = newState
            zombie.target = nil
            patternTimer = zombie.stunnedDuration
            zombie.speed = 0
        elseif newState == STATES.WANDER then
            zombie.state = newState
            zombie.target = nil
            patternTimer = zombie.wanderingDuration
            zombie.speed = zombie.wanderingSpeed
        elseif newState == STATES.FOLLOW then
            zombie.state = newState
            zombie.target = getSprites("CART")[1]
            zombie.speed = zombie.huntingSpeed
        elseif newState == ANIMATION_STATES.NOANIM then
            zombie.animationState = newState
            coloration = newColor(1, 1, 1)
        elseif newState == ANIMATION_STATES.ISHIT then
            zombie.animationState = newState
            animation_timer = 0
        end
    end

    --called every frame
    function zombie.updateState()
        local player = getSprites("CART")[1]
        if zombie.state == STATES.WAIT then
            if player and zombie.searchTarget(player, zombie.detectionRange) then
                zombie.setState(STATES.FOLLOW)
            elseif patternTimer <= 0 then
                zombie.angle = zombie.angle + math.rad(math.random(90, 270)) --turning back, more or less
                zombie.setState(STATES.WANDER)
            end
        elseif zombie.state == STATES.STUNNED then
            if patternTimer <= 0 then
                zombie.setState(STATES.WAIT)
            end
        elseif zombie.state == STATES.WANDER then
            if player and zombie.searchTarget(player, zombie.detectionRange) then
                zombie.setState(STATES.FOLLOW)
            elseif patternTimer <= 0 then
                zombie.setState(STATES.WAIT)
            end
        elseif zombie.state == STATES.FOLLOW then
            if player and not zombie.searchTarget(player, zombie.forgetRange) then
                zombie.setState(STATES.WAIT)
            end
        end

        if zombie.animationState == ANIMATION_STATES.NOANIM then
        elseif zombie.animationState == ANIMATION_STATES.ISHIT then
            if animation_timer >= HIT_ANIMATION_DURATION then
                zombie.setState(ANIMATION_STATES.NOANIM)
            end
        end
    end

    --checks if zombie is at range of target
    function zombie.searchTarget(target, range)
        for _, zombHitbox in ipairs(zombie.hitboxes_list) do
            for _, hitbox in ipairs(target.hitboxes_list) do
                if ((target.pos + target.radius) - (zombie.pos + zombie.radius)).norm() <= range then
                    return true
                end
            end
        end
        return false
    end

    function zombie.update(dt)
        previousPos = zombie.pos.clone()
        if zombie.state == STATES.WAIT or zombie.state == STATES.WANDER or zombie.state == STATES.STUNNED then
            patternTimer = patternTimer - dt
        end
        if zombie.state == STATES.FOLLOW then
            zombie.angle = (zombie.target.pos - zombie.pos).angle()
        end
        if zombie.state == STATES.FOLLOW or zombie.state == STATES.WANDER then
            zombie.move(dt)
        end

        if zombie.animationState == ANIMATION_STATES.ISHIT then
            animation_timer = animation_timer + dt
            local hue = animation_timer / HIT_ANIMATION_DURATION --turn red and back to normal
            coloration = newColor(1, hue, hue)
        end
        zombie.manageCollisions()
    end

    function zombie.move(dt)
        zombie.velocity.x = zombie.speed * math.cos(zombie.angle)
        zombie.velocity.y = zombie.speed * math.sin(zombie.angle)
        local old_pos = zombie.pos
        zombie.pos = zombie.pos + zombie.velocity * dt
        zombie.updateHitbox()
    end

    --visitor design pattern
    function zombie.getCollided(collider)
        if collider.collideWithZombie ~= nil then
            collider.collideWithZombie(zombie)
        end
    end

    function zombie.isCollidedWith(collider)
        return collider.isCollidingSprite(zombie)
    end

    function zombie.collideWithCart(cart)
        if zombie.isCollidingSprite(cart) then
            zombie.pos = previousPos
            zombie.updateHitbox()
            if cart.canCrush(zombie) then
                zombie.free() --dies immedialty
            else
                zombie.setState(STATES.STUNNED)
                cart.takeDamage(zombie.damageDealt)
                cart.collisionDetected = true
            end
        end
    end

    function zombie.collideWithRectangle(rectangle)
        if zombie.isCollidingRectangle(rectangle) then
            zombie.pos = previousPos
            zombie.updateHitbox()
            zombie.setState(STATES.STUNNED)
        end
    end

    function zombie.collideWithZombie(other_zombie)
        if zombie.isCollidingSprite(other_zombie) then
            zombie.pos = previousPos
            zombie.updateHitbox()
            zombie.setState(STATES.WAIT)
        end
    end

    function zombie.takeDamage(amount)
        if zombie.hp > amount then
            zombie.hp = zombie.hp - amount
            zombie.setState(ANIMATION_STATES.ISHIT)
        else
            zombie.free()
        end
    end

    function zombie.draw()
        if zombie.texture then
            coloration.apply()
            love.graphics.draw(zombie.texture, zombie.pos.x, zombie.pos.y, zombie.angle, zombie.scale.x, zombie.scale.y, zombie.origin.x, zombie.origin.y)
            love.graphics.setColor(1, 1, 1)
        end
    end

    function zombie.printState()
        love.graphics.setColor(0.4, 0.4, 0)
        love.graphics.print(zombie.state, zombie.pos.x - zombie.width * 0.5, zombie.pos.y - zombie.height * 0.5 - 20)
        love.graphics.print(zombie.animationState, zombie.pos.x - zombie.width * 0.5, zombie.pos.y + zombie.height * 0.5)
        love.graphics.setColor(1, 1, 1)
    end

    return zombie
end
