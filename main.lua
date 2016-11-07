--[[--
  Simple demonstration of the Luna-Love-Scene paradigm.
]]

local class = require("lib.middleclass.middleclass")
require "llscn"

-- Example declaration of actor
local HiWorld = class("HiWorld", LnaActor)
function HiWorld:initialize()
  LnaActor.initialize(self)
end
function HiWorld:draw()
  love.graphics.print("Hello World", 400, 400)
end

-- Construct the scene
local scene = LnaScene:new()
local actor = HiWorld:new()
local actorIdx = scene:addActor(actor)

local stage = LnaStage:new()
local sceneIdx = stage:addScene(scene)
stage:setCurrentScene(sceneIdx)


-- Love2D calls
function love.load()
  stage:load()
end

function love.update(dt)
  stage:update(dt)
end

function love.draw()
  stage:draw()
end
