local hitboxes_list = {}

function newHitbox(pPosition, pAngle)
    pAngle = pAngle or 0

    local hitbox = {}
    hitbox.relativePosition = pPosition or newvector2D(0, 0) --position relative to parent's position
    hitbox.pos = nil
    hitbox.isFree = false

    function hitbox.update(parentPos, parentAngle)
        parentAngle = parentAngle or 0

        --formula to rotate hitbox around parent origin
        local offset_x = hitbox.relativePosition.x * math.cos(parentAngle) + hitbox.relativePosition.y * math.sin(parentAngle)
        local offset_y = hitbox.relativePosition.x * math.sin(parentAngle) - hitbox.relativePosition.y * math.cos(parentAngle)
        hitbox.pos = parentPos + newVector2D(offset_x, offset_y)
    end

    hitbox.update(pPosition, pAngle)
    table.insert(hitboxes_list, hitbox)

    return hitbox
end

function newCircleHitbox(pPosition, pRadius)
    local circleHitbox = newHitbox(pPosition)
    circleHitbox.radius = pRadius

    --useful for debugging
    function circleHitbox.draw()
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("line", circleHitbox.pos.x, circleHitbox.pos.y, circleHitbox.radius)
        love.graphics.setColor(1, 1, 1)
    end

    function circleHitbox.collideRectangle(rect_hitbox)
        local left_border = rect_hitbox.pos.x
        local right_border = rect_hitbox.pos.x + rect_hitbox.width
        local top_border = rect_hitbox.pos.y
        local bottom_border = rect_hitbox.pos.y + rect_hitbox.height

        rectangle_corners = {} --rectangle's four corners
        table.insert(rectangle_corners, newVector2D(left_border, top_border))
        table.insert(rectangle_corners, newVector2D(right_border, top_border))
        table.insert(rectangle_corners, newVector2D(left_border, bottom_border))
        table.insert(rectangle_corners, newVector2D(right_border, bottom_border))
        for _, corner in ipairs(rectangle_corners) do
            --check if any of rectangle's corner is in circle
            if (corner - circleHitbox.pos).norm() <= circleHitbox.radius then
                return true
            end
        end
        circle_edges = {} --circle's four cardinal points
        table.insert(circle_edges, newVector2D(circleHitbox.pos.x + circleHitbox.radius, circleHitbox.pos.y))
        table.insert(circle_edges, newVector2D(circleHitbox.pos.x, circleHitbox.pos.y + circleHitbox.radius))
        table.insert(circle_edges, newVector2D(circleHitbox.pos.x - circleHitbox.radius, circleHitbox.pos.y))
        table.insert(circle_edges, newVector2D(circleHitbox.pos.x, circleHitbox.pos.y - circleHitbox.radius))
        for _, edge in ipairs(circle_edges) do
            --check if any of circle's cardinal points are in rectangle
            if edge.x >= left_border and edge.x <= right_border and edge.y >= top_border and edge.y <= bottom_border then
                return true
            end
        end
        return false
    end

    function circleHitbox.collideCircle(other_hitbox)
        local distance = (other_hitbox.pos - circleHitbox.pos).norm()
        return circleHitbox.radius and other_hitbox.radius and distance < circleHitbox.radius + other_hitbox.radius
    end

    return circleHitbox
end

function newRectangleHitbox(pPosition, pWidth, pHeight)
    local rectangleHitbox = newHitbox(pPosition)
    rectangleHitbox.width = pWidth
    rectangleHitbox.height = pHeight

    function rectangleHitbox.collideCircle(other_hitbox)
        return other_hitbox.collideRectangle(rectangleHitbox)
    end

    --useful for debugging
    function rectangleHitbox.draw()
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", rectangleHitbox.pos.x, rectangleHitbox.pos.y, rectangleHitbox.width, rectangleHitbox.height)
        love.graphics.setColor(1, 1, 1)
    end

    return rectangleHitbox
end

function drawHitboxes()
    for _, hitbox in ipairs(hitboxes_list) do
        hitbox.draw()
    end
end

function freeHitboxes()
    for i = #hitboxes_list, 1, -1 do
        if hitboxes_list[i].isFree then
            table.remove(hitboxes_list, i)
        end
    end
end
