local textboxes_list = {}

function newTextBox(pText, pColor, pPosition, pWidth, pOrigin, pFont)
    local textBox = {
        text = pText,
        color = pColor,
        pos = pPosition,
        width = pWidth,
        origin = pOrigin,
        font = pFont
    }

    function textBox.draw()
        love.graphics.setFont(textBox.font)
        textBox.color.apply()
        love.graphics.printf(textBox.text, textBox.pos.x, textBox.pos.y, textBox.width, "center", 0, 1, 1, textBox.origin.x, textBox.origin.y)
        newColor(1, 1, 1, 1).apply()
    end

    table.insert(textboxes_list, textBox)

    return textBox
end

function printTextboxes()
    for _, tb in ipairs(textboxes_list) do
        tb.draw()
    end
end

function unloadTextBoxes()
    for i = #textboxes_list, 1, -1 do
        table.remove(textboxes_list, i)
    end
end
