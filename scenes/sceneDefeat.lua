local defeatScene = {}

local font = love.graphics.newFont(35)
local button
local textBox

defeatScene.load = function()
    love.graphics.setFont(font)
    local button_size = newVector2D(360, 60)
    local textbox_size = newVector2D(500, 60)
    local text = "YOU DIED\nLooks like the zombies were the one shopping... for you !"

    textBox = newTextBox(text, newColor(0.53, 0.03, 0.03), newVector2D(screen.width * 0.5, screen.height * 0.3), textbox_size.x, textbox_size * 0.5, font)

    button = newButton(newVector2D(screen.width * 0.5, screen.height * 0.5), button_size, button_size * 0.5, newColor(0.53, 0.03, 0.03), "BACK TO MENU", font, newColor(1, 1, 1), newColor(0.26, 0, 0), newColor(1, 1, 0))
end

defeatScene.update = function()
    button.update(dt)
end

defeatScene.keyPressed = function(key)
    if key == "escape" then
        changeScene("home")
    end
end

defeatScene.mousePressed = function(mouseX, mouseY, btn)
    if btn == 1 and button.isHovered(mouseX, mouseY) then
        changeScene("home")
    end
end

defeatScene.draw = function()
    button.draw()
    printTextboxes()
end

defeatScene.unload = function()
    unloadSprites()
    unloadTextBoxes()
    button = nil
    textBox = nil
end

return defeatScene
