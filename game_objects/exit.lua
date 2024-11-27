function newExit(pTexture, pPosition, pSize)
    pSize = pSize or {width = pTexture:getWidth(), height = pTexture:getHeight()}

    local exit = newRectangle(pTexture, pPosition, pSize, newVector2D(0.5, 0.5))
    exit.type = "EXIT"

    --visitor design pattern
    function exit.getCollided(collider)
        if collider.collideWithExit ~= nil then
            collider.collideWithExit(exit)
        end
    end

    function exit.collideWithCart(cart)
        cart.collideWithExit(exit)
    end

    return exit
end
