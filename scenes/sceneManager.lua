local scenes = {}
local currentScene = nil

registerScene = function(scene, key)
    scenes[key] = scene
end

changeScene = function(pSceneLabel, data)
    if currentScene ~= nil then
        currentScene.unload()
    end
    if pSceneLabel == "victory" then
        local nbItemsGathered = currentScene.nbItemsGathered
        local massGathered = currentScene.massGathered
        currentScene = scenes[pSceneLabel]
        currentScene.nbItemsGathered = nbItemsGathered
        currentScene.massGathered = massGathered
    else
        currentScene = scenes[pSceneLabel]
    end
    if currentScene ~= nil then
        currentScene.load(data)
    end
end

updateCurrentScene = function(dt)
    if currentScene ~= nil then
        currentScene.update(dt)
    end
end

drawCurrentScene = function()
    if currentScene ~= nil then
        currentScene.draw()
    end
end

mousePressed = function(x, y, btn)
    if currentScene ~= nil then
        currentScene.mousePressed(x, y, btn)
    end
end

keyPressed = function(key, scancode, isrepeat)
    if currentScene ~= nil then
        currentScene.keyPressed(key, scancode, isrepeat)
    end
end
