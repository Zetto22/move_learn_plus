-- Move Learn Plus: forget-list shows POWER / PP for the selected move and
-- the move being learned. Reimplements MoveLearnMenu (no engine require)
-- so the screens override cannot silently fall back to vanilla.

local CURSOR = 0xED
local NAME_MAX = 18

local HM_MOVES = {
  CUT = true, FLY = true, SURF = true, STRENGTH = true, FLASH = true,
}

local function trunc(s, max)
  if type(s) ~= "string" or s == "" then return "?????" end
  if #s <= max then return s end
  return s:sub(1, max)
end

local function moveDef(game, moveId)
  local moves = game and game.data and game.data.moves
  return moves and moveId and moves[moveId] or nil
end

local function powerLabel(def)
  if not def or def.power == nil or def.power == 0 then
    return "--"
  end
  return tostring(def.power)
end

local function ppLabel(def)
  if not def or def.pp == nil then
    return "--"
  end
  return tostring(def.pp)
end

local function drawPowerPp(Font, def, y)
  local power = ("POWER %s"):format(powerLabel(def))
  local pp = ("PP %s"):format(ppLabel(def))
  Font.draw(power, 8, y)
  Font.draw(pp, 160 - 8 - #pp * 8, y)
end

-- Mirror of src/ui/MoveLearnMenu.lua (engine 0.1.6x), with L2 detail panel.
local function newMoveLearnMenu(mod, game, mon, newMoveId, onDone)
  local Font = mod.ui.Font
  local TextBox = mod.ui.TextBox
  local showStats = function()
    return mod.options:get("show_stats") ~= false
  end

  local self = {
    game = game,
    mon = mon,
    newMoveId = newMoveId,
    onDone = onDone,
    index = 1,
    selecting = false,
  }

  local function monName()
    return self.mon.nickname
      or self.game.data.pokemon[self.mon.species].name
  end

  local function stringsCancel()
    -- Keep the English CANCEL label; localization of engine Strings is
    -- not on the stable mod surface without internals.
    return "CANCEL"
  end

  function self:enter()
    local g = self.game
    local mdef = moveDef(g, self.newMoveId)
    local name = monName()
    local moveName = mdef and mdef.name or tostring(self.newMoveId)
    self.selecting = false
    g.stack:push(TextBox.new(g,
      ("%s is\ntrying to learn\v%s!\fBut, %s\ncan't learn more\vthan 4 moves!\f"):format(
        name, moveName, name)
      .. ("Delete an older\nmove to make room\vfor %s?"):format(moveName),
      nil, {
        choice = function(yes)
          if yes then
            self.selecting = true
          else
            self:confirmAbandon()
          end
        end,
      }))
  end

  function self:update(dt)
    if not self.selecting then return end
    local input = self.game.input
    local n = #self.mon.moves + 1
    if input:wasPressed("up") then
      self.index = self.index > 1 and self.index - 1 or n
    elseif input:wasPressed("down") then
      self.index = self.index < n and self.index + 1 or 1
    elseif input:wasPressed("b") then
      self:confirmAbandon()
    elseif input:wasPressed("a") then
      if self.index > #self.mon.moves then
        self:confirmAbandon()
      else
        local old = self.mon.moves[self.index]
        if HM_MOVES[old.id] then
          self.game.stack:push(TextBox.new(self.game,
            "HM techniques\ncan't be deleted!"))
          return
        end
        local mdef = moveDef(self.game, self.newMoveId)
        local oldDef = moveDef(self.game, old.id)
        self.mon.moves[self.index] = {
          id = self.newMoveId,
          pp = mdef and mdef.pp or 0,
        }
        self.forgot = oldDef and oldDef.name or tostring(old.id)
        self:finish(true)
      end
    end
  end

  function self:confirmAbandon()
    local g = self.game
    local mdef = moveDef(g, self.newMoveId)
    local moveName = mdef and mdef.name or tostring(self.newMoveId)
    self.selecting = false
    g.stack:push(TextBox.new(g,
      ("Abandon learning\n%s?"):format(moveName), nil, {
        choice = function(yes)
          if yes then self:finish(false) else self:enter() end
        end,
      }))
  end

  function self:finish(learned)
    local g = self.game
    local name = monName()
    local mdef = moveDef(g, self.newMoveId)
    local moveName = mdef and mdef.name or tostring(self.newMoveId)
    self.selecting = false
    g.stack:pop()
    local msg
    if learned then
      msg = ("1, 2 and... Poof!\f%s forgot\n%s!\fAnd...\f%s learned\n%s!"):format(
        name, self.forgot, name, moveName)
    else
      msg = ("%s\ndid not learn\v%s!"):format(name, moveName)
    end
    g.stack:push(TextBox.new(g, msg, function()
      if self.onDone then self.onDone(learned) end
    end))
  end

  function self:drawVanillaPanel()
    Font.drawBox(0, 12, 20, 6)
    Font.draw("Which move should", 8, 14 * 8)
    Font.draw("be forgotten?", 8, 16 * 8)
  end

  function self:drawDetailPanel()
    local nMoves = #self.mon.moves
    local onCancel = self.index > nMoves
    local cancel = stringsCancel()

    Font.drawBox(0, 12, 20, 6)

    if onCancel then
      Font.draw(cancel, 8, 13 * 8)
    else
      local mv = self.mon.moves[self.index]
      local def = mv and moveDef(self.game, mv.id)
      local name = def and def.name or (mv and tostring(mv.id)) or "?????"
      Font.draw(trunc(name, NAME_MAX), 8, 13 * 8)
      drawPowerPp(Font, def, 14 * 8)
    end

    local newDef = moveDef(self.game, self.newMoveId)
    local newName = newDef and newDef.name or tostring(self.newMoveId or "?????")
    Font.draw(trunc(newName, NAME_MAX), 8, 15 * 8)
    drawPowerPp(Font, newDef, 16 * 8)
  end

  function self:draw()
    if not self.selecting then return end
    Font.drawBox(4, 5, 16, 7)
    love.graphics.setColor(0, 0, 0, 1)
    for i, mv in ipairs(self.mon.moves) do
      local def = moveDef(self.game, mv.id)
      local name = def and def.name or tostring(mv.id or "?????")
      Font.draw(name, 48, (5 + i) * 8)
    end
    Font.draw(stringsCancel(), 48, (6 + #self.mon.moves) * 8)
    if Font.drawCode then
      Font.drawCode(CURSOR, 40, (5 + self.index) * 8)
    end
    if showStats() then
      self:drawDetailPanel()
    else
      self:drawVanillaPanel()
    end
    love.graphics.setColor(1, 1, 1, 1)
  end

  return self
end

return function(mod)
  mod.log:info("carregado")

  mod.options:define({
    { key = "show_stats", type = "toggle", label = "SHOW STATS", default = true },
  })

  -- Builtin is not pre-registered in Data.screens; override installs ours.
  mod.content.screens:override("MoveLearnMenu", {
    new = function(game, mon, newMoveId, onDone)
      return newMoveLearnMenu(mod, game, mon, newMoveId, onDone)
    end,
  })

  mod.events:on("game.ready", function()
    local rec = mod.content.screens:get("MoveLearnMenu")
    if type(rec) == "table" and type(rec.new) == "function" then
      mod.log:info("MoveLearnMenu override active")
    else
      mod.log:error("MoveLearnMenu override missing after load")
    end
  end)
end
