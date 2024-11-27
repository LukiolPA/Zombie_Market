--So many sprites
local tile_texture = love.graphics.newImage("images/tile.png")
local tiles_scale = {x = 2, y = 2}
local horizontal_wall_texture = love.graphics.newImage("images/wall_horizontal.png")
local vertical_wall_texture = love.graphics.newImage("images/wall_vertical.png")
local exit_door_texture = love.graphics.newImage("images/exit_door.png")
local caution_sign_texture = love.graphics.newImage("images/caution_sign.png")
local caution_sign_size = {width = 0.35 * caution_sign_texture:getWidth(), height = 0.35 * caution_sign_texture:getHeight()}
local checkout_texture = love.graphics.newImage("images/checkout.png")
local checkout_size = {width = 1.7 * checkout_texture:getWidth(), height = 1.7 * checkout_texture:getHeight()}
local horizontal_shelf_texture = love.graphics.newImage("images/shelf_horizontal.png")
local horizontal_shelves_size = {width = 1 * horizontal_shelf_texture:getWidth(), height = 1 * horizontal_shelf_texture:getHeight()}
local vertical_shelf_texture = love.graphics.newImage("images/shelf_vertical.png")
local vertical_shelves_size = {width = 1 * vertical_shelf_texture:getWidth(), height = 1 * vertical_shelf_texture:getHeight()}

--for now, shop is a rectangle area
--borders, width and height don't include walls
--in other words, walls are "outside of the shop"
local shop = {
    left_border = -550,
    width = 1000,
    top_border = -150,
    height = 3000,
    walls_thickness = 50,
    door_size = 200 --exit door in top middle of shop
}

local tile_size_x = tile_texture:getWidth() * tiles_scale.x
local tile_size_y = tile_texture:getHeight() * tiles_scale.y
shop.width = tile_size_x * math.ceil(shop.width / tile_size_x) --rounding up to be a muliple of number of tile_size
shop.height = tile_size_y * math.ceil(shop.height / tile_size_y)

function shop.init()
    --add floor
    for i = shop.left_border, shop.left_border + shop.width - tile_size_x, tile_size_x do
        for j = shop.top_border, shop.top_border + shop.height - tile_size_y, tile_size_y do
            newSprite(tile_texture, newVector2D(i, j), tiles_scale)
        end
    end

    --add walls
    local wall_width = shop.width + 2 * shop.walls_thickness
    local wall_height = shop.height + 2 * shop.walls_thickness
    local wall_left_x = shop.left_border - shop.walls_thickness
    local wall_top_y = shop.top_border - shop.walls_thickness
    newRectangle(horizontal_wall_texture, newVector2D(wall_left_x, wall_top_y), {width = wall_width, height = shop.walls_thickness}, newVector2D(0, 0))
    newRectangle(horizontal_wall_texture, newVector2D(wall_left_x, shop.top_border + shop.height), {width = wall_width, height = shop.walls_thickness}, newVector2D(0, 0))
    newRectangle(vertical_wall_texture, newVector2D(wall_left_x, wall_top_y), {width = shop.walls_thickness, height = wall_height}, newVector2D(0, 0))
    newRectangle(vertical_wall_texture, newVector2D(shop.left_border + shop.width, wall_top_y), {width = shop.walls_thickness, height = wall_height}, newVector2D(0, 0))

    --add checkouts
    newRectangle(checkout_texture, newVector2D(shop.left_border + 100, shop.top_border + 200), checkout_size, newVector2D(0, 0))
    newRectangle(checkout_texture, newVector2D(shop.left_border + 300, shop.top_border + 200), checkout_size, newVector2D(0, 0))
    newRectangle(checkout_texture, newVector2D(shop.left_border + shop.width - 300 - checkout_size.width, shop.top_border + 200), checkout_size, newVector2D(0, 0))
    newRectangle(checkout_texture, newVector2D(shop.left_border + shop.width - 100 - checkout_size.width, shop.top_border + 200), checkout_size, newVector2D(0, 0))

    --add sections, from north to south
    local NB_SECTIONS = 10 -- nb of sections in magasin from north to south
    local NB_ITEM_IN_SECTIONS = 5
    for i = 2, NB_SECTIONS - 1 do
        local walls_size = {width = shop.width * 0.3, height = shop.walls_thickness}
        local wall_x_1 = shop.left_border + 0.25 * shop.width
        local wall_x_2 = shop.left_border + 0.75 * shop.width
        local wall_y = shop.top_border + shop.height / NB_SECTIONS * i
        local shelves_size = {width = walls_size.width, height = walls_size.height * 0.85}
        local shelf_x_1 = wall_x_1 + 0.5 * (walls_size.width - shelves_size.width)
        local shelf_x_2 = wall_x_2 + 0.5 * (walls_size.width - shelves_size.width)
        local shelf_y_1 = wall_y - 0.5 * walls_size.height - 0.45 * shelves_size.height
        local shelf_y_2 = wall_y - 0.5 * walls_size.height + walls_size.height + 0.45 * shelves_size.height
        newShelf(horizontal_shelf_texture, newVector2D(shelf_x_1, shelf_y_1), shelves_size, 2, NB_ITEM_IN_SECTIONS)
        newShelf(horizontal_shelf_texture, newVector2D(shelf_x_1, shelf_y_2), shelves_size, 2, NB_ITEM_IN_SECTIONS)
        newShelf(horizontal_shelf_texture, newVector2D(shelf_x_2, shelf_y_1), shelves_size, 2, NB_ITEM_IN_SECTIONS)
        newShelf(horizontal_shelf_texture, newVector2D(shelf_x_2, shelf_y_2), shelves_size, 2, NB_ITEM_IN_SECTIONS)
        newRectangle(horizontal_wall_texture, newVector2D(wall_x_1, wall_y), walls_size)
        newRectangle(horizontal_wall_texture, newVector2D(wall_x_2, wall_y), walls_size)
        local zombie_y = shop.top_border + shop.height / 20 * (i + 0.5)
        if i % 2 == 0 then
            local zombie_x_1 = shop.left_border + 30
            local zombie_x_2 = shop.left_border + shop.width - 30
            newZombieSpawner(newVector2D(zombie_x_1, zombie_y), 0)
            newZombieSpawner(newVector2D(zombie_x_2, zombie_y), math.pi)
        else
            local zombie_x = shop.left_border + shop.width / 2
            newZombieSpawner(newVector2D(zombie_x, zombie_y), 0)
        end
    end

    --add door and exit
    local door_leftside_x = wall_left_x + shop.width / 2
    local door_rightside_x = door_leftside_x + shop.door_size
    newRectangle(exit_door_texture, newVector2D(door_leftside_x, wall_top_y), {width = shop.door_size, height = shop.walls_thickness}, newVector2D(0, 0))
    newExit(caution_sign_texture, newVector2D(door_leftside_x + 10 + 0.5 * caution_sign_size.width, wall_top_y + shop.walls_thickness * 0.5 + 0.5 * caution_sign_size.height), caution_sign_size)

    --add zombies spawners
    newZombieSpawner(newVector2D(shop.left_border + 50, shop.top_border + 50), math.pi / 4)
    newZombieSpawner(newVector2D(shop.left_border + 50, shop.top_border + shop.height - 50), -math.pi / 4)
    newZombieSpawner(newVector2D(shop.left_border + shop.width - 50, shop.top_border + shop.height - 50), -3 * math.pi / 4)
    newZombieSpawner(newVector2D(shop.left_border + shop.width - 50, shop.top_border + 50), 3 * math.pi / 4)

    --add items spawners
    newItemSpawner("ITEM", newVector2D(shop.left_border + 120, shop.top_border + 220), 0)
    newItemSpawner("ITEM", newVector2D(shop.left_border + 320, shop.top_border + 220), 0)
    newItemSpawner("ITEM", newVector2D(shop.left_border + shop.width - 180, shop.top_border + 220), 0)
    newItemSpawner("ITEM", newVector2D(shop.left_border + shop.width - 380, shop.top_border + 220), 0)
end

return shop
