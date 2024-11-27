function newColor(pRed, pGreen, pBlue, pAlpha)
    pAlpha = pAlpha or 1

    local color = {
        red = pRed,
        green = pGreen,
        blue = pBlue
    }

    function color.apply()
        love.graphics.setColor(color.red, color.green, color.blue)
    end

    function color.clone()
        return newColor(color.red, color.green, color.blue, color.alpha)
    end

    return color
end
