require "vector2D"
require "game_objects/sprite"
require "game_objects/rectangle"
require "game_objects/exit"
require "game_objects/shelf"
require "game_objects/item"
require "game_objects/zombie"
require "game_objects/spawner"

local game = {}
local isPaused = nil

--local prototype = require "prototype"
local camera = require "camera"
local shop = require "game_objects/shop"
local cart = require "game_objects/cart"

--useful for debugging
local ARE_HITBOXES_VISIBLE = false
local ARE_SPAWNERS_VISIBLE = false
local ARE_STATES_VISIBLE = false

local font = love.graphics.newFont(15)
local hp_textbox
local mass_textbox
local speed_textbox
local energy_textbox

game.nbItemsGathered = nil
game.massGathered = nil

game.load = function()
    isPaused = false
    shop.init()
    initSprites()
    camera.init(shop)
    camera.follow(cart)
    game.itemsOwned = 0
    game.massGathered = 0

    local textbox_width = screen.width * 0.2
    hp_textbox = newTextBox("HP =", newColor(1, 1, 1, 1), newVector2D(screen.width * 0.125, 5), textbox_width, newVector2D(textbox_width / 2, 0), font)
    mass_textbox = newTextBox("Mass gathered =", newColor(1, 1, 1, 1), newVector2D(screen.width * 0.375, 5), textbox_width, newVector2D(textbox_width / 2, 0), font)
    speed_textbox = newTextBox("Speed =", newColor(1, 1, 1, 1), newVector2D(screen.width * 0.625, 5), textbox_width, newVector2D(textbox_width / 2, 0), font)
    energy_textbox = newTextBox("Power =", newColor(1, 1, 1, 1), newVector2D(screen.width * 0.875, 5), textbox_width, newVector2D(textbox_width / 2, 0), font)
end

game.update = function(dt)
    if isPaused then
        return
    end
    updateSprites(dt)
    updateSpawners(dt)
    freeSprites()
    camera.follow(cart)
    game.updateUI()
end

game.updateUI = function()
    hp_textbox.text = "HP = " .. cart.HP
    hp_textbox.color = cart.getHPColor()

    mass_textbox.text = "Mass = " .. math.floor(cart.mass - cart.initialMass)
    mass_textbox.color = cart.getMassColor()

    speed_textbox.text = "Speed = " .. math.floor(cart.velocity.norm())
    speed_textbox.color = cart.getSpeedColor()

    if cart.cineticEnergy < 1000 then
        energy_textbox.text = "Power = " .. math.floor(cart.cineticEnergy)
    else
        energy_textbox.text = "Power = " .. math.floor(cart.cineticEnergy / 1000) .. "k"
    end
    energy_textbox.color = cart.getEnergyColor()
end

game.keyPressed = function(key, scancode, isrepeat)
    if scancode == "p" then
        isPaused = not isPaused
        return
    end
    if isPaused then
        return
    end
    if scancode == "space" then
        cart.shop()
    end
    if scancode == "escape" then
        changeScene("home")
    end
end

game.mousePressed = function(x, y, btn)
    if isPaused then
        return
    end
    if btn == 1 then
        local mouseX, mouseY = screen.toWorldPosition(x, y)
        cart.throwItem(mouseX, mouseY)
    end
end

game.draw = function()
    love.graphics.push("all")
    love.graphics.setScissor(0, screen.height * 0.05, screen.width, screen.height * 0.9)
    --love.graphics.scale(1, 1)
    love.graphics.translate(-camera.pos.x, -camera.pos.y) --we move to camera position before draw objects on level
    drawSprites(camera)
    if ARE_HITBOXES_VISIBLE then
        drawHitboxes()
    end
    if ARE_SPAWNERS_VISIBLE then
        drawSpawners()
    end

    if ARE_STATES_VISIBLE then
        printStates(camera)
    end
    love.graphics.pop()
    printTextboxes()
    --love.graphics.print("HP = " .. cart.HP .. "    Mass = " .. cart.mass - cart.initialMass .. "   Speed = " .. cart.velocity.norm() .. "  Energy=" .. math.floor(cart.cineticEnergy))
    -- love.graphics.print("x=" .. math.floor(cart.pos.x) .. "   y=" .. math.floor(cart.pos.y) .. "     Angle=" .. math.floor(math.deg(cart.angle) % 360) .. "     acceleration=" .. math.floor(cart.acceleration.norm()), 0, 0)
    -- love.graphics.setColor(0, 0, 0)
    -- love.graphics.print("   frictionx=" .. math.floor(cart.friction.x) .. "     frictiony=" .. math.floor(cart.friction.y), 0, 30)
    -- love.graphics.print("speedx=" .. math.floor(cart.velocity.x) .. "   speedy=" .. math.floor(cart.velocity.y) .. "    speed=" .. math.floor(cart.velocity.norm()) .. "    rotationSpeed=" .. math.floor(cart.rotationSpeed), 0, 60)
    -- love.graphics.setColor(1, 1, 1)

    love.graphics.reset()
end

game.unload = function()
    unloadSprites() -- also unloads hitboxes
    unloadSpawners()
    unloadTextBoxes()
    game.nbItemsGathered = #cart.itemPossessed
    game.massGathered = cart.mass - cart.initialMass
    isPaused = nil
end

return game
