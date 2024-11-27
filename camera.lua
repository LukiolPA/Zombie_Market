local camera

function screen.toWorldPosition(pX, pY)
    return pX + camera.pos.x, pY + camera.pos.y
end

camera = {
    pos = newVector2D(0, 0),
    left_limit_onscreen = 0.4 * screen.width,
    right_limit_onscreen = 0.6 * screen.width,
    top_limit_onscreen = 0.4 * screen.height,
    bottom_limit_onscreen = 0.6 * screen.height,
    left_limit_onworld, --borders of the world camera can't cross
    right_limit_onworld,
    top_limit_onworld,
    bottom_limit_onworld
}

camera.init = function(shop)
    camera.left_limit_onworld = shop.left_border - shop.walls_thickness
    camera.right_limit_onworld = shop.left_border + shop.width + shop.walls_thickness - screen.width
    camera.top_limit_onworld = shop.top_border - shop.walls_thickness - 0.05 * screen.height
    camera.bottom_limit_onworld = shop.top_border + shop.height + shop.walls_thickness - screen.height
end

camera.follow = function(linkedObject)
    --camera moves when linked object reaches border of screen
    if linkedObject.pos.x - camera.pos.x > camera.right_limit_onscreen then
        camera.pos.x = linkedObject.pos.x - camera.right_limit_onscreen
    end
    if linkedObject.pos.x - camera.pos.x < camera.left_limit_onscreen then
        camera.pos.x = linkedObject.pos.x - camera.left_limit_onscreen
    end
    if linkedObject.pos.y - camera.pos.y > camera.bottom_limit_onscreen then
        camera.pos.y = linkedObject.pos.y - camera.bottom_limit_onscreen
    end
    if linkedObject.pos.y - camera.pos.y < camera.top_limit_onscreen then
        camera.pos.y = linkedObject.pos.y - camera.top_limit_onscreen
    end
    --camera can't cross world's limits
    if camera.pos.x < camera.left_limit_onworld then
        camera.pos.x = camera.left_limit_onworld
    end
    if camera.pos.x > camera.right_limit_onworld then
        camera.pos.x = camera.right_limit_onworld
    end
    if camera.pos.y < camera.top_limit_onworld then
        camera.pos.y = camera.top_limit_onworld
    end
    if camera.pos.y > camera.bottom_limit_onworld then
        camera.pos.y = camera.bottom_limit_onworld
    end
end

return camera
