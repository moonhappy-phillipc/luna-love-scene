--[[--
  Simple demonstration of the Luna-Love-Scene paradigm.
]]

local class = require "lib.middleclass.middleclass"
local Lna = require "llscn"

--[[
  Example actor.
  Performs "hello world" until signalled on cue to perform "bye world".
]]
local HiWorld = class("HiWorld", Lna.Actor)
function HiWorld:initialize()
  Lna.Actor.initialize(self)
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
  Another example actor.
  However, this actor will only monitor cues issued from particular director.
]]

local ObidientActor = class("ObidientActor", Lna.Actor)
function ObidientActor:initialize(director)
  Lna.Actor.initialize(self)
  self.message = "Director not saying anything yet"
  self:onCue("director_says_hi", "sayHi", director)
end
function ObidientActor:sayHi()
  self.message = "Director says hi"
end
function ObidientActor:draw()
  love.graphics.print(self.message, 200, 200)
end

--[[
  Example director.
  Monitors the time and will signal the cue for Hello World actor to start
  performing the less famous "bye world" routine, after 3 seconds have passed.
]]
local HiWorldDirector = class("HiWorldDirector", Lna.Director)
function HiWorldDirector:initialize()
  Lna.Director.initialize(self)
  self.timePassed = 0
  self.cueFired = false
  self.subCueFired = false
end
function HiWorldDirector:update(dt)
  self.timePassed = self.timePassed + dt
  if not self.cueFired and self.timePassed > 3 then
    self:signalCue("hiworld_bye")
    self.cueFired = true
  elseif not self.subCueFired and self.timePassed > 4 then
    self:signalCue("director_says_hi")
    self.subCueFired = true
  end
end


local stage = Lna.Stage:new()

-- Love2D calls
function love.load(arg)
  if arg[#arg] == "-debug" then require("mobdebug").start() end
  -- Construct the scene
  local scene = Lna.Scene:new()
  local director = HiWorldDirector:new()
  scene:addActor(HiWorld:new()) -- note this actor is not managed by a director and will perform on global cues
  local obidientActor = ObidientActor:new(director)
  -- director:addActor(obidientActor) -- uncomment to see director cue handled
  scene:addActor(obidientActor)
  scene:addDirector(director)
  local sceneIdx = stage:addScene(scene)
  stage:setCurrentScene(sceneIdx)
  stage:load()
end

function love.update(dt)
  stage:update(dt)
end

function love.draw()
  stage:draw()
end
