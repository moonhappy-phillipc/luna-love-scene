local class = require "lib.middleclass.middleclass"

--[[--
 Actor of a Scene.
 An actor is an entity that resembles presence and characterisation. Use the
 actor construct as the foundation to perform the role of an entity in the game.
]]

local LnaActor = class('LnaActor')
function LnaActor:initialize(drawLayer)
  self.cues = {}
  self.mCues = {}
  self.mouseOverCues = {}
  self.id = -1
  self.drawLayer = drawLayer or 0
  self.scene = nil
  self.director = nil
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

function LnaActor:onMouseCue(region, callbackName)
  self.mCues[#self.mCues + 1] = {r=region, cb=callbackName, obj=self}
  if self.scene then
    self.scene:_addMouseCue({r=region, cb=callbackName, obj=self})
  end
end

function LnaActor:onMouseOver(region, callbackName)
  self.mouseOverCues[#self.mouseOverCues + 1] = {r=region, cb=callbackName, obj=self}
  if self.scene then
    self.scene:_addMouseOverCue({r=region, cb=callbackName, obj=self})
  end
end

function LnaActor:signalCue(cueName, userData)
  if self.scene then
    self.scene:_signalCue(cueName, self, userData)
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
    count = #self.mCues
    for i=1,count do
      scene:_addMouseCue(self.mCues[i])
    end
    count = #self.mouseOverCues
    for i=1,count do
      scene:_addMouseOverCue(self.mouseOverCues[i])
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
  self._actorCues = {}
  self:setVisible(false)
end

function LnaDirector:addActor(actor)
  if actor then
    self.actors[#self.actors + 1] = actor
    actor.director = self
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
    self:_clearOutActorCues(self._actorCues)
    -- Cues from actors
    scene:_clearDirectorActors(self)
    local count = #self.actors
    for i=1,count do
      local childActor = self.actors[i]
      self:_addCues(childActor.cues, self.cues)
      scene:addActor(childActor)
    end
    -- Add cues to scene
    self:_addCues(self.cues, scene.cues)
    self:_addCues(self._actorCues, scene.cues)
  end
end

--[[--
 Scene to behold.
 The scene contains an assortment of actors and props to delight and entertain.
]]

local LnaScene = class('LnaScene')
function LnaScene:initialize()
  self.actors = {}
  self._drawLayers = {}
  self.cues = {}
  self.mCues = {}
  self._mCueLayers = {}
  self.id = -1
  self.stage = nil
  self.mouseOverCues = {}
  self._mouseOverLayers = {}
end

function LnaScene:_setAsCurrent()
  -- Clear cues
  local count = #self.cues
  for i=1,count do self.cues[i]=nil end
  self.cues = {}
  -- Configure all actors
  for _,v in pairs(self.actors) do
    for k,a in pairs(v) do
      a:_setScene(k, self)
    end
  end
end

function LnaScene:_clearDirectorActors(director)
  local count = #self.actors
  for _,v in pairs(self.actors) do
    for k,a in pairs(v) do
      if a.director == director then
        v[k] = nil
      end
    end
  end
end

function LnaScene:addActor(actor)
  if self.actors[actor.drawLayer] == nil then
    self.actors[actor.drawLayer] = {}
  end
  local count = #self.actors[actor.drawLayer]
  self.actors[actor.drawLayer][count + 1] = actor
  -- Sort draw layers
  local keys = {}
  for k,_ in pairs(self.actors) do
    keys[#keys+1] = k
  end
  table.sort(keys)
  self._drawLayers = keys
end

function LnaScene:addDirector(director)
  self:addActor(director)
end

function LnaScene:_addMouseCue(watch)
  if self.mCues[watch.obj.drawLayer] == nil then
    self.mCues[watch.obj.drawLayer] = {}
  end
  local count = #self.mCues[watch.obj.drawLayer]
  self.mCues[watch.obj.drawLayer][count + 1] = watch
  -- Sort mouse watch layers
  local keys = {}
  for k,_ in pairs(self.mCues) do
    keys[#keys+1] = k
  end
  table.sort(keys, function(a,b) return a > b end)
  self._mCueLayers = keys
end

function LnaScene:_addMouseOverCue(watch)
  if self.mouseOverCues[watch.obj.drawLayer] == nil then
    self.mouseOverCues[watch.obj.drawLayer] = {}
  end
  local count = #self.mouseOverCues[watch.obj.drawLayer]
  self.mouseOverCues[watch.obj.drawLayer][count + 1] = watch
  -- Sort mouse watch layers
  local keys = {}
  for k,_ in pairs(self.mouseOverCues) do
    keys[#keys+1] = k
  end
  table.sort(keys, function(a,b) return a > b end)
  self._mouseOverLayers = keys
end

function LnaScene:signalCue(eventName, userData)
  self:_signalCue(eventName, self, userData)
end

function LnaScene:_signalCue(eventName, obj, userData)
  for _,v in pairs(self.cues) do
    if v.cue == eventName and (not v.dir or (v.dir._active and v.dir == obj)) then
      v.obj[v.cb](v.obj, userData)
    end
  end
end

function LnaScene:signalMouseCue(button, x, y, touch)
  for _,n in ipairs(self._mCueLayers) do
    for _,m in pairs(self.mCues[n]) do
      if m.r.x <= x and x <= (m.r.x + m.r.w) and m.r.y <= y and y <= (m.r.y + m.r.h) then
        if m.obj[m.cb](m.obj, button, x, y, touch) then
          return
        end
      end
    end
  end
end

function LnaScene:load()
  for _,v in pairs(self.actors) do
    for _,a in pairs(v) do
      a:load()
    end
  end
end

function LnaScene:_mouseOverUpdate(dt)
  -- Mouse over
  local mx, my = love.mouse.getPosition()
  for _,n in ipairs(self._mouseOverLayers) do
    for _,m in pairs(self.mouseOverCues[n]) do
      if m.r.x <= mx and mx <= (m.r.x + m.r.w) and m.r.y <= my and my <= (m.r.y + m.r.h) then
        if m.obj[m.cb](m.obj, dt, mx, my) then
          return
        end
      end
    end
  end
end

function LnaScene:update(dt)
  self:_mouseOverUpdate(dt)
  -- Actor updates
  for _,v in pairs(self.actors) do
    for _,a in pairs(v) do
      a:_doupdate(dt)
    end
  end
end

function LnaScene:draw()
  for _,k in ipairs(self._drawLayers) do
    for _,a in pairs(self.actors[k]) do
      a:_dodraw()
    end
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

function LnaStage:signalMouseCue(mousebutton, x , y, touch)
  if self.scenes[self.sceneCurrentIdx] then
    self.scenes[self.sceneCurrentIdx]:signalMouseCue(mousebutton, x, y, touch)
  end
end

function LnaStage:signalCue(cueName, userData)
  if self.scenes[self.sceneCurrentIdx] then
    self.scenes[self.sceneCurrentIdx]:signalCue(cueName, userData)
  end
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
