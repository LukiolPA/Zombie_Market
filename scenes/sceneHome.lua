local homeScene = {}

local main_texture = love.graphics.newImage("images/title_screen.png")
local main_texture_size = {width = main_texture:getWidth(), height = main_texture:getHeight()}
local font = love.graphics.newFont(24)
local button
local picture

homeScene.load = function()
    picture = newSprite(main_texture, newVector2D(screen.width / 2, screen.height), {x = 1.1, y = 1.1}, newVector2D(main_texture_size.width / 2, main_texture_size.height))

    local button_size = newVector2D(250, 48)
    button = newButton(newVector2D(screen.width * 0.5, screen.height * 0.1), button_size, button_size * 0.5, newColor(0.53, 0.03, 0.03), "START GAME", font, newColor(1, 1, 1), newColor(0.26, 0, 0), newColor(1, 1, 0))
end

homeScene.update = function()
    button.update(dt)
end

homeScene.keyPressed = function(key)
    if key == "space" then
        changeScene("game")
    end
end

homeScene.mousePressed = function(mouseX, mouseY, btn)
    if btn == 1 and button.isHovered(mouseX, mouseY) then
        changeScene("game")
    end
end

homeScene.draw = function()
    picture.draw()
    button.draw()
    printTextboxes()
end

homeScene.unload = function()
    unloadSprites()
    unloadTextBoxes()
    button = nil
    picture = nil
end

return homeScene
