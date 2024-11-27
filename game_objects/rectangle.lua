--shelves, store sections, walls, anything with a rectangleHitbox
function newRectangle(pTexture, pPosition, pSize, pRelativeOrigin)
    pSize = pSize or {width = pTexture:getWidth(), height = pTexture:getHeight()}
    pRelativeOrigin = pRelativeOrigin or newVector2D(0.5, 0.5)

    local scale = {x = pSize.width / pTexture:getWidth(), y = pSize.height / pTexture:getHeight()}
    local origin = newVector2D(pRelativeOrigin.x * pTexture:getWidth(), pRelativeOrigin.y * pTexture:getHeight())

    local rectangle = newSprite(pTexture, pPosition, scale, origin, 0)
    rectangle.type = "RECTANGLE"

    function rectangle.init()
        rectangle.createRectangleHitbox(newVector2D(-0.5, -0.5), {x = 1, y = 1}) --rectangle covering sprite fullly
        rectangle.updateHitbox()
    end

    --create one rectangle hitbox with size and position defined as a fraction of sprite's dimensions
    --for instance hitbox's position pRelativePosition(0.5, 0.5) is middle if sprite's origin is top-left, or bottom-right if sprite"s origin is middle
    --hitbox's dimensions pRelativeScale are a fraction of sprite's max dimension
    function rectangle.createRectangleHitbox(pRelativePosition, pRelativeScale)
        pRelativePosition = pRelativePosition or newVector2D(0, 0)
        pRelativeScale = pRelativeScale or {x = 1, y = 1}

        local x = (pRelativePosition.x + 0.5) * rectangle.width - rectangle.origin.x * rectangle.scale.x
        local y = -(pRelativePosition.y + 0.5) * rectangle.height + rectangle.origin.y * rectangle.scale.y
        local width = pRelativeScale.x * rectangle.width
        local height = pRelativeScale.y * rectangle.height
        local new_hitbox = newRectangleHitbox(newVector2D(x, y), width, height)
        new_hitbox.update(rectangle.pos, rectangle.angle)
        table.insert(rectangle.hitboxes_list, new_hitbox)
    end

    --visitor design pattern
    function rectangle.getCollided(collider)
        if not rectangle.isFree and collider.collideWithRectangle ~= nil then
            collider.collideWithRectangle(rectangle)
        end
    end

    function rectangle.isCollidingSprite(collider)
        if rectangle.isFree then
            return false
        else
            return collider.isCollidingRectangle(rectangle)
        end
    end

    function rectangle.collideWithCart(cart)
        if rectangle.isCollidingSprite(cart) then
            cart.collisionDetected = true
        end
    end

    return rectangle
end
