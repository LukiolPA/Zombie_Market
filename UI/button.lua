function newButton(pPosition, pSize, pOrigin, pColor, pText, pFont, pTextColor, pHoveredColor, pHoveredTextColor)
    local button = {
        pos = pPosition,
        size = pSize,
        origin = pOrigin,
        color = pColor,
        text = pText,
        font = pFont,
        textColor = pTextColor,
        hoveredColor = pHoveredColor,
        hoveredTextColor = pHoveredTextColor,
        isHovered = false
    }

    local current_color = button.color
    local current_text_color = button.textColor

    button.textBox = newTextBox(button.text, button.color, button.pos + button.size * 0.1, button.size.x * 0.8, button.origin, button.font)

    function button.update()
        if button.isHovered(love.mouse.getPosition()) then
            current_color = button.hoveredColor or button.color
            current_text_color = button.hoveredTextColor or button.textColor
        else
            current_color = button.color
            current_text_color = button.textColor
        end
        button.textBox.color = current_text_color
    end

    function button.draw()
        current_color.apply()
        love.graphics.rectangle("fill", button.pos.x - button.origin.x, button.pos.y - button.origin.y, button.size.x, button.size.y)
        newColor(1, 1, 1, 1).apply()
    end

    function button.isHovered(mouseX, mouseY)
        local top_left_corner = button.pos - button.origin
        local bottom_right_corner = top_left_corner + button.size
        return mouseX >= top_left_corner.x and mouseX <= bottom_right_corner.x and mouseY >= top_left_corner.y and mouseY <= bottom_right_corner.y
    end

    return button
end
