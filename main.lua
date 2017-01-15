--[[--
  Simple demonstration of the Luna-Love-Scene paradigm.
]]

local class = require("lib.middleclass.middleclass")
require "llscn"

--[[
  Example actor.
  Performs "hello world" until signalled on cue to perform "bye world".
]]
local HiWorld = class("HiWorld", LnaActor)
function HiWorld:initialize()
  LnaActor.initialize(self)
  self.message = "Hello World"
  self:onCue("hiworld_bye", "sayBye")
end
function HiWorld:sayBye()
  self.message = "Bye World"
end
function HiWorld:draw()
  love.graphics.print(self.message, 400, 400)
end

--[[
  Example director.
  Monitors the time and will signal the cue for Hello World actor to start
  performing the less famous "bye world" routine, after 3 seconds have passed.
]]
local HiWorldDirector = class("HiWorldDirector", LnaDirector)
function HiWorldDirector:initialize()
  LnaDirector.initialize(self)
  self.timePassed = 0
  self.cueFired = false
end
function HiWorldDirector:update(dt)
  self.timePassed = self.timePassed + dt
  if not self.cureFired and self.timePassed > 3 then
    self:signalCue("hiworld_bye")
    self.cueFired = true
  end
end

-- Construct the scene
local scene = LnaScene:new()
local actor = HiWorld:new()
local director = HiWorldDirector:new()
local actorIdx = scene:addActor(actor)
local directorIdx = scene:addDirector(director)

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
