function newVector2D(px, py)
    local v = {x = px, y = py}

    local vector2DMT = {}

    function v.clone()
        return newVector2D(v.x, v.y)
    end

    --sum of two vectors, or one vector and one number
    function vector2DMT.__add(v1, v2)
        if type(v1) == "number" then
            return newVector2D(v1 + v2.x, v1 + v2.y)
        elseif type(v2) == "number" then
            return newVector2D(v1.x + v2, v1.y + v2)
        else
            return newVector2D(v1.x + v2.x, v1.y + v2.y)
        end
    end

    function vector2DMT.__mul(k, v)
        if type(k) == "number" then
            return newVector2D(k * v.x, k * v.y)
        else
            return newVector2D(k.x * v, k.y * v)
        end
    end

    function vector2DMT.__unm(v)
        return v * -1
    end

    function vector2DMT.__sub(v1, v2)
        return v1 + (-v2)
    end

    -- TODO : comparison operator is not recognized, why ?
    -- --compares norms, beware, separate coordinates might not be the same
    -- function vector2DMT.__eq(v1, v2)
    --     if type(v1) == "number" then
    --         return v1 == v2.norm()
    --     elseif type(v2 == "number") then
    --         return v2 == v1.norm()
    --     else
    --         return v1.norm() == v2.norm()
    --     end
    -- end

    -- function vector2DMT.__lt(v1, v2)
    --     if type(v1) == "number" then
    --         return v1 < v2.norm()
    --     elseif type(v2 == "number") then
    --         return v1.norm() < v2
    --     else
    --         return v1.norm() < v2.norm()
    --     end
    -- end

    -- function vector2DMT.__le(v1, v2)
    --     return v1 == v2 or v1 < v2
    -- end

    function v.norm()
        return math.sqrt(v.x * v.x + v.y * v.y)
    end

    function v.normalize()
        return v * (1 / v.norm())
    end

    --angle relative to horizontal rightway vector
    function v.angle()
        return math.atan2(v.y, v.x)
    end

    --distance between to points represented by vectors
    function v.distance(other_vector)
        return (v - other_vector).norm()
    end

    function v.dot(other_vector)
        return v.x * other_vector.x + v.y * other_vector.y
    end

    setmetatable(v, vector2DMT)

    return v
end
