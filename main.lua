local Delaunay = require 'Delaunay'
local Point    = Delaunay.Point

function getRandomPointInCircle(radius)
  local t = 2*math.pi*math.random()
  local u = math.random()+math.random()
  local r = nil
  if u > 1 then r = 2-u else r = u end
  return radius*r*math.cos(t), radius*r*math.sin(t)
end

local rooms = {}
local phase = 0
local triangles = {}

function room_intersects(left, right)
    return not (left.x + left.w < right.x or right.x + right.w < left.x
            or  left.y + left.h < right.y or right.y + right.h < left.y)
end

function seperate_rooms()
    local done = true
    for index1,i in ipairs(rooms) do
        local n = 0
        local vector_x = 0
        local vector_y = 0
        for index2,j in ipairs(rooms) do
            if index1 ~= index2 and room_intersects(i, j) then
                local dx = math.min((i.x+i.w)-j.x + 1, i.x - (j.x + j.w) - 1)
                local dy = math.min((i.y+i.h)-j.y + 1, i.y - (j.y + j.h) - 1)
                if math.abs(dx) < math.abs(dy) then
                    dy = 0
                else
                    dx = 0
                end
                local dxa = -dx/2
                local dxb  = dx+dxa
                local dya = -dy/2
                local dyb = dy+dya

                i.x = i.x + dxa
                i.y = i.y + dya

                j.x = j.x + dxb
                j.y = j.y + dyb
                done = false
            end
        end
        if n > 0 then
            vector_x = vector_x / n
            vector_y = vector_y / n
            dist = math.sqrt(vector_x*vector_x + vector_y*vector_y)
            vector_x = vector_x / dist
            vector_y = vector_y / dist

            i.x = i.x - vector_x
            i.y = i.y - vector_y
        end
    end
    return done
end

function love.load()
    math.randomseed( os.time() )
    local center_x = 200
    local center_y = 200
    if phase == 0 then
        for i=1,150 do
            x, y = getRandomPointInCircle(100)
            table.insert(rooms, { id = i, x = center_x + x, y = center_y + y, w = 5+15*math.random(), h = 5+15*math.random(), room_type = "ROOM_NONE" })
        end
        phase = 1
    end
end

function love.update()
    if phase == 1 then
        if seperate_rooms() then
            phase = 2
        end
    end
    if phase == 2 then
        for i,v in ipairs(rooms) do
            if v.w > 13 and v.h > 10 then
                v.room_type = "ROOM_MAIN"
            end
        end
        phase = 3
    end
    if phase == 3 then
        local points = {}
        for _,v in ipairs(rooms) do
            if v.room_type == "ROOM_MAIN" then
                local point = Point(v.x + v.w/2, v.y + v.h/2)
                point.id = v.id
                table.insert(points, point)
            end
        end
        triangles = Delaunay.triangulate(unpack(points))
        phase = 4
    end
end

function love.draw()
    love.graphics.setColor(255, 255, 255)
    for i,v in ipairs(rooms) do
        if v.room_type == "ROOM_NONE" then
            love.graphics.setColor(255, 255, 255)
        end
        if v.room_type == "ROOM_MAIN" then
            love.graphics.setColor(255, 0, 0)
        end
        love.graphics.rectangle("fill", v.x, v.y, v.w, v.h)
    end
    love.graphics.setColor(0, 255, 0)
    for i,t in ipairs(triangles) do
        love.graphics.line(t.e1.p1.x, t.e1.p1.y, t.e1.p2.x, t.e1.p2.y)
        love.graphics.line(t.e2.p1.x, t.e2.p1.y, t.e2.p2.x, t.e2.p2.y)
        love.graphics.line(t.e3.p1.x, t.e3.p1.y, t.e3.p2.x, t.e3.p2.y)
    end
end