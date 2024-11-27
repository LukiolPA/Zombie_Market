local victoryScene = {}

local font = love.graphics.newFont(30)
local button
local textBox
victoryScene.nbItemsGathered = nil
victoryScene.massGathered = nil

victoryScene.load = function()
    love.graphics.setFont(font)
    local button_size = newVector2D(360, 60)
    local textbox_size = newVector2D(700, 60)
    local text = "You escaped, and took with you " .. victoryScene.nbItemsGathered .. " strawberries, weighing a total of " .. victoryScene.massGathered .. " kg!\n\nNow, you are covered in a slimy red substance. Hope it's strawberry juice..."

    textBox = newTextBox(text, newColor(0.53, 0.03, 0.03), newVector2D(screen.width * 0.5, screen.height * 0.25), textbox_size.x, textbox_size * 0.5, font)

    button = newButton(newVector2D(screen.width * 0.5, screen.height * 0.6), button_size, button_size * 0.5, newColor(0.53, 0.03, 0.03), "BACK TO MENU", font, newColor(1, 1, 1), newColor(0.26, 0, 0), newColor(1, 1, 0))
end

victoryScene.update = function()
    button.update(dt)
end

victoryScene.keyPressed = function(key)
end

victoryScene.mousePressed = function(mouseX, mouseY, btn)
    if btn == 1 and button.isHovered(mouseX, mouseY) then
        changeScene("home")
    end
end

victoryScene.draw = function()
    button.draw()
    printTextboxes()
end

victoryScene.unload = function()
    unloadTextBoxes()
    button = nil
    textBox = nil
end

return victoryScene
