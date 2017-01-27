local class = require "lib.middleclass.middleclass"

--[[--
 Actor of a Scene.
 An actor is an entity that resembles presence and characterisation. Use the
 actor construct as the foundation to perform the role of an entity in the game.
]]

local LnaActor = class('LnaActor')
function LnaActor:initialize()
  self.cues = {}
  self.kbCues = {}
  self.id = -1
  self.scene = nil
  self._visible = true
  self._active = true
end

function LnaActor:setActive(active)
  self._active = active
end

function LnaActor:setVisible(visible)
  self._visible = visible
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

function LnaActor:_setScene(id, scene)
  self.id = id
  self.scene = scene
  local count = 0
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

function LnaActor:update()
end

function LnaActor:draw()
end

function LnaActor:_doupdate(dt)
  if self._active then
    self:update(dt)
  end
end

function LnaActor:_dodraw()
  if self._visible then
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
  self.actors = {}
  self:setVisible(false)
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

function LnaDirector:_clearOutActorCues(cues)
  -- Clear cues of actors
  local count = #cues
  local remakeCues = {}
  for i=1,count do
    if cues[i].dir ~= self then
      remakeCues[#remakeCues + 1] = cues[i]
    end
    cues[i] = nil
  end
  cues = {}
  cues = remakeCues
end

function LnaDirector:_addCues(actorCues, toCues)
  local count = #actorCues
  for i=1,count do
    toCues[#toCues+1] = actorCues[i]
  end
end

function LnaDirector:_setScene(id, scene)
  self.id = id
  self.scene = scene
  if scene then
    -- Clear actor cues, ready for re-add
    self:_clearOutActorCues(self.cues)
    self:_clearOutActorCues(self.kbCues)
    -- Cues from actors
    local count = #self.actors
    for i=1,count do
      local childActor = self.actors[i]
      self:_addCues(childActor.cues, self.cues)
      self:_addCues(childActor.kbCues, self.kbCues)
    end
    -- Add cues to scene
    self:_addCues(self.cues, scene.cues)
    self:_addCues(self.kbCues, scene.kbCues)
  end
end

--[[--
 Scene to behold.
 The scene contains an assortment of actors and props to delight and entertain.
]]

local LnaScene = class('LnaScene')
function LnaScene:initialize()
  self.actors = {}
  self.cues = {}
  self.kbCues = {}
  self.id = -1
  self.stage = nil
end

function LnaScene:_setAsCurrent()
  -- Clear cues
  local count = #self.cues
  for i=0,count do self.cues[i]=nil end
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
  for _,v in pairs(self.cues) do
    if v.cue == eventName and (not v.dir or (v.dir._active and v.dir == obj)) then
      v.obj[v.cb](v.obj)
    end
  end
end

function LnaScene:signalKeyboardCue(key)
  for _,v in pairs(self.kbCues) do
    if v.key == key and (not v.dir or v.dir._active) then
      v.obj[v.cb](v.obj)
    end
  end
end

function LnaScene:load()
  for _,v in pairs(self.actors) do
    v:load()
  end
end

function LnaScene:update(dt)
  for _,v in pairs(self.actors) do
    v:_doupdate(dt)
  end
end

function LnaScene:draw()
  for _,v in pairs(self.actors) do
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
