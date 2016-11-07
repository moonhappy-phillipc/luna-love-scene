local class = require("lib.middleclass.middleclass")

--[[--
 Actor of a Scene.
 An actor is an entity that resembles presence and characterisation. Use the
 actor construct as the foundation to perform the role of an entity in the game.
]]

LnaActor = class('LnaActor')
function LnaActor:initialize()
end

function LnaActor:load()
end

function LnaActor:update(dt)
end

function LnaActor:draw()
end


--[[--
 Scene to behold.
 The scene contains an assortment of actors and props to delight and entertain.
]]

LnaScene = class('LnaScene')
function LnaScene:initialize()
  self.actors = {}
  self.actorsCount = 0
end

function LnaScene:addActor(actor)
  self.actors[self.actorsCount] = actor
  self.actorsCount = self.actorsCount + 1
  return self.actorsCount - 1
end

function LnaScene:load()
  for i,v in pairs(self.actors) do
    v:load()
  end
end

function LnaScene:update(dt)
  for i,v in pairs(self.actors) do
    v:update(dt)
  end
end

function LnaScene:draw()
  for i,v in pairs(self.actors) do
    v:draw()
  end
end


--[[
 Stage is the vessel of all the things.
 The stage is the foundation to which scenes belong.
]]

LnaStage = class('LnaStage')
function LnaStage:initialize()
  self.scenes = {}
  self.scenesCount = 0
  self.sceneCurrent = -1
end

function LnaStage:addScene(scene)
  self.scenes[self.scenesCount] = scene
  self.scenesCount = self.scenesCount + 1
  return self.scenesCount - 1
end

function LnaStage:setCurrentScene(sceneIdx)
  self.sceneCurrent = sceneIdx
end

function LnaStage:load()
  for i,v in ipairs(self.scenes) do
    v:load()
  end
end

function LnaStage:update(dt)
  if self.scenes[self.sceneCurrent] then
    self.scenes[self.sceneCurrent]:update(dt)
  end
end

function LnaStage:draw()
  if self.scenes[self.sceneCurrent] then
    self.scenes[self.sceneCurrent]:draw()
  end
end
