local class = require "lib.middleclass.middleclass"

--[[--
 Actor of a Scene.
 An actor is an entity that resembles presence and characterisation. Use the
 actor construct as the foundation to perform the role of an entity in the game.
]]

LnaActor = class('LnaActor')
function LnaActor:initialize()
  self.id = -1
  self.scene = nil
  self.visible = true
  self.active = true
  self.cues = {}
  self.cuesCount = 0
end

function LnaActor:onCue(cueName, callbackName)
  self.cues[self.cuesCount] = {cue=cueName, cb=callbackName}
  self.cuesCount = self.cuesCount + 1
end

function LnaActor:_doHandleCue(cueName)
  for i,v in pairs(self.cues) do
    if v.cue == cueName then
      self[v.cb](self)
    end
  end
end

function LnaActor:signalCue(cueName)
  self.scene:signalCue(cueName)
end

function LnaActor:load()
end

function LnaActor:update(dt)
end

function LnaActor:draw()
end

function LnaActor:_doupdate(dt)
  if self.active then
    self:update(dt)
  end
end

function LnaActor:_dodraw()
  if self.visible then
    self:draw()
  end
end

--[[--
 Director to boss actors around.
 The director is like an actor, but is behind the scenes making sure everything
 goes to "plan".
]]
LnaDirector = class('LnaDirector', LnaActor)
function LnaDirector:initialize()
  LnaActor.initialize(self)
  self.visible = false
end

--[[--
 Scene to behold.
 The scene contains an assortment of actors and props to delight and entertain.
]]

LnaScene = class('LnaScene')
function LnaScene:initialize()
  self.id = -1
  self.stage = nil
  self.actors = {}
  self.actorsCount = 0
end

-- As an actor/director might be allocated to multiple scenes, when a transistion
-- occurs, the id must be adjusted to the newly set scene.
function LnaScene:_setAsCurrent()
  for i,v in pairs(self.actors) do
    v.id = i
    v.scene = self
  end
end

function LnaScene:addActor(actor)
  self.actors[self.actorsCount] = actor
  self.actorsCount = self.actorsCount + 1
  return self.actorsCount - 1
end

function LnaScene:addDirector(director)
  return self:addActor(director)
end

function LnaScene:signalCue(eventName)
  for i,v in pairs(self.actors) do
    v:_doHandleCue(eventName)
  end
end

function LnaScene:load()
  for i,v in pairs(self.actors) do
    v:load()
  end
end

function LnaScene:update(dt)
  for i,v in pairs(self.actors) do
    v:_doupdate(dt)
  end
end

function LnaScene:draw()
  for i,v in pairs(self.actors) do
    v:_dodraw()
  end
end


--[[
 Stage is the vessel of all the things.
 The stage is the foundation to which scenes belong.
]]

LnaStage = class('LnaStage')
function LnaStage:initialize()
  self.id = -1
  self.scenes = {}
  self.scenesCount = 0
  self.sceneCurrentIdx = -1
  self.stageLoad = false
end

function LnaStage:addScene(scene)
  self.scenes[self.scenesCount] = scene
  scene.id = self.scenesCount
  scene.stage = self
  self.scenesCount = self.scenesCount + 1
  return self.scenesCount - 1
end

function LnaStage:setCurrentScene(sceneIdx)
  self.sceneCurrentIdx = sceneIdx
  if self.stageLoad then
    self.scenes[sceneIdx]:load()
  end
  self.scenes[sceneIdx]:_setAsCurrent()
end

function LnaStage:load()
  if self.scenes[self.sceneCurrentIdx] then
    self.scenes[self.sceneCurrentIdx]:load()
  end
  self.stageLoad = true
end

function LnaStage:update(dt)
  if self.scenes[self.sceneCurrentIdx] then
    self.scenes[self.sceneCurrentIdx]:update(dt)
  end
end

function LnaStage:draw()
  if self.scenes[self.sceneCurrentIdx] then
    self.scenes[self.sceneCurrentIdx]:draw()
  end
end
