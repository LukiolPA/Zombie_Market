if pcall(require, "lldebugger") then
    require("lldebugger").start()
end

require "scenes/sceneManager"
require "UI/color"
require "UI/button"
require "UI/textBox"

screen = {}

function love.load()
    love.window.setMode(1000, 750)
    love.window.setTitle("Zombie Market")
    screen = {
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight()
    }
    registerScene(require("scenes/sceneGame"), "game")
    registerScene(require("scenes/sceneHome"), "home")
    registerScene(require("scenes/sceneVictory"), "victory")
    registerScene(require("scenes/sceneDefeat"), "defeat")
    changeScene("home")
end

function love.update(dt)
    updateCurrentScene(dt)
end

function love.keypressed(key, scancode, isrepeat)
    keyPressed(key, scancode, isrepeat)
end

function love.mousepressed(x, y, btn)
    mousePressed(x, y, btn)
end

function love.draw()
    drawCurrentScene()
end
