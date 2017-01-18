local class = require "lib.middleclass.middleclass"

--[[--
 Actor of a Scene.
 An actor is an entity that resembles presence and characterisation. Use the
 actor construct as the foundation to perform the role of an entity in the game.
]]

local LnaActor = class('LnaActor')
function LnaActor:initialize()
  self.id = -1
  self.scene = nil
  self.visible = true
  self.active = true
  self.cues = {}
  self.kbCues = {}
end

function LnaActor:onCue(cueName, callbackName, director)
  self.cues[#self.cues + 1] = {cue=cueName, cb=callbackName, obj=self, dir=director}
  if self.scene then
    self.scene.cues[#self.scene.cues + 1] = {cue=cueName, cb=callbackName, obj=self, dir=self.scene}
  end
end

function LnaActor:onKeyboardCue(keyName, callbackName, director)
  self.kbCues[#self.kbCues + 1] = {key=keyName, cb=callbackName, obj=self, dir=director}
  if self.scene then
    self.scene.kbCues[#self.scene.kbCues + 1] = {key=keyName, cb=callbackName, obj=self, dir=self.scene}
  end
end

function LnaActor:signalCue(cueName)
  if self.scene then
    self.scene:_signalCue(cueName, self)
  end
end

function LnaActor:_setDirector(director)
  if director then
    count = #self.cues
    for i=1,count do
      if self.cues[i].dir == director then
        director.cues[#director.cues+1] = self.cues[i]
      end
    end
    count = #self.kbCues
    for i=1,count do
      if self.kbCues[i].dir == director then
        director.kbCues[#director.kbCues+1] = self.kbCues[i]
      end
    end
  end
end

function LnaActor:_setScene(id, scene)
  self.id = id
  self.scene = scene
  if scene then
    count = #self.cues
    for i=1,count do
      if not self.cues[i].dir or self.cues[i].dir == scene then
        scene.cues[#scene.cues+1] = self.cues[i]
      end
    end
    count = #self.kbCues
    for i=1,count do
      if not self.kbCues[i].dir or self.kbCues[i].dir == scene then
        scene.kbCues[#scene.kbCues+1] = self.kbCues[i]
      end
    end
  end
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
local LnaDirector = class('LnaDirector', LnaActor)
function LnaDirector:initialize()
  LnaActor.initialize(self)
  self.visible = false
  self.actors = {}
end

function LnaDirector:addActor(actor)
  if actor then
    self.actors[#self.actors + 1] = actor
    return #self.actors
  else
    return -1
  end
end

function LnaDirector:addDirector(director)
  return self:addActor(director)
end

function LnaDirector:_setScene(id, scene)
  self.id = id
  self.scene = scene
  if scene then
    -- cues from actors
    local count = #self.actors
    for i=1,count do
      local childActor = self.actors[i]
      local cueCount = #childActor.cues
      for x=1,cueCount do
        self.cues[#self.cues+1] = childActor.cues[x]
      end
    end
    -- add cues to scene
    count = #self.cues
    for i=1,count do
      scene.cues[#scene.cues+1] = self.cues[i]
    end
    count = #self.kbCues
    for i=1,count do
      scene.kbCues[#scene.kbCues+1] = self.kbCues[i]
    end
  end
end

--[[--
 Scene to behold.
 The scene contains an assortment of actors and props to delight and entertain.
]]

local LnaScene = class('LnaScene')
function LnaScene:initialize()
  self.id = -1
  self.stage = nil
  self.actors = {}
  self.cues = {}
  self.kbCues = {}
end

function LnaScene:_setAsCurrent()
  -- Clear cues
  count = #self.cues
  for i=0, count do self.cues[i]=nil end
  self.cues = {}
  -- Configure all actors
  for i,v in pairs(self.actors) do
    v:_setScene(i, self)
  end
end

function LnaScene:addActor(actor)
  self.actors[#self.actors + 1] = actor
  return #self.actors
end

function LnaScene:addDirector(director)
  return self:addActor(director)
end

function LnaScene:signalCue(eventName)
  self:_signalCue(eventName, self)
end

function LnaScene:_signalCue(eventName, obj)
  for i,v in pairs(self.cues) do
    if v.cue == eventName and (not v.dir or (v.dir.active and v.dir == obj)) then
      v.obj[v.cb](v.obj)
    end
  end
end

function LnaScene:signalKeyboardCue(key)
  for i,v in pairs(self.kbCues) do
    if v.key == key and (not v.dir or v.dir.active) then
      v.obj[v.cb](v.obj)
    end
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

local LnaStage = class('LnaStage')
function LnaStage:initialize()
  self.id = -1
  self.scenes = {}
  self.sceneCurrentIdx = -1
  self.stageLoad = false
end

function LnaStage:addScene(scene)
  self.scenes[#self.scenes + 1] = scene
  scene.id = #self.scenes
  scene.stage = self
  return #self.scenes
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

return { Actor=LnaActor, Director=LnaDirector, Scene=LnaScene, Stage=LnaStage }
