-- Move Learn Plus: forget-list POWER/PP panel, plus mart BUY footer
-- showing POWER/ACC when the cursor is on a TM/HM.

local CURSOR = 0xED
local NAME_MAX = 18
local BAG_CAPACITY = 20

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

local function accuracyLabel(def)
  if not def or def.accuracy == nil then
    return "--"
  end
  return tostring(def.accuracy)
end

local function drawPowerPp(Font, def, y)
  local power = ("POWER %s"):format(powerLabel(def))
  local pp = ("PP %s"):format(ppLabel(def))
  Font.draw(power, 8, y)
  Font.draw(pp, 160 - 8 - #pp * 8, y)
end

local function txt(game, key, fallback)
  local table_ = game and game.data and game.data.text
  return (table_ and table_[key]) or fallback
end

local function isBadge(id)
  return type(id) == "string" and id:find("BADGE", 1, true) ~= nil
end

local function bagCapacity(game)
  local configured = game and game.data and game.data.constants
      and game.data.constants.bagSize
  if type(configured) == "number" and configured >= 1 then
    return math.floor(configured)
  end
  return BAG_CAPACITY
end

local function bagSlots(save)
  local n = 0
  for id in pairs(save.inventory or {}) do
    if not isBadge(id) then n = n + 1 end
  end
  return n
end

local function bagOrder(save)
  local order = save.bagOrder
  if not order then
    order = {}
    for id in pairs(save.inventory or {}) do
      if not isBadge(id) then order[#order + 1] = id end
    end
    table.sort(order)
    save.bagOrder = order
  end
  local seen = {}
  for i = #order, 1, -1 do
    local id = order[i]
    if not save.inventory[id] or seen[id] then
      table.remove(order, i)
    else
      seen[id] = true
    end
  end
  for id in pairs(save.inventory or {}) do
    if not isBadge(id) and not seen[id] then
      order[#order + 1] = id
    end
  end
  return order
end

local function bagAdd(save, id, qty, game)
  local inv = save.inventory
  qty = qty or 1
  if not inv[id] and not isBadge(id) and bagSlots(save) >= bagCapacity(game) then
    return false
  end
  if not isBadge(id) and (inv[id] or 0) + qty > 99 then
    return false
  end
  local isNew = not inv[id]
  inv[id] = (inv[id] or 0) + qty
  if isNew and not isBadge(id) then
    table.insert(bagOrder(save), id)
  end
  return true
end

local function bagRemove(save, id, qty)
  local inv = save.inventory
  inv[id] = (inv[id] or 0) - (qty or 1)
  if inv[id] <= 0 then
    inv[id] = nil
    local order = save.bagOrder
    if order then
      for i, oid in ipairs(order) do
        if oid == id then
          table.remove(order, i)
          break
        end
      end
    end
  end
end

local function machineMoveFooter(game, itemId)
  local items = game and game.data and game.data.items
  local idef = items and items[itemId]
  local machine = idef and idef.machine
  if not machine or not machine.move then
    return nil
  end
  -- TMs only (HMs keep the clerk greeting).
  if machine.kind == "HM" then
    return nil
  end
  if machine.kind ~= "TM"
      and not (type(itemId) == "string" and itemId:find("^TM_")) then
    return nil
  end
  local mdef = moveDef(game, machine.move)
  local name = trunc((mdef and mdef.name) or tostring(machine.move), NAME_MAX)
  return ("%s\nPOWER %s ACC %s"):format(
    name, powerLabel(mdef), accuracyLabel(mdef))
end

local function wireTmIdleFooter(list, game, greet, showStatsFn)
  local detailFooter = nil

  local function refreshIdleFooter()
    if not showStatsFn() then
      if list.footer == detailFooter then
        list.footer = greet
      end
      detailFooter = nil
      return
    end
    local item = list.items[list.index]
    local detail = item and machineMoveFooter(game, item.value) or nil
    local idle = list.footer == greet or list.footer == detailFooter
    if not idle then
      return
    end
    if detail then
      list.footer = detail
      detailFooter = detail
    else
      list.footer = greet
      detailFooter = nil
    end
  end

  local baseUpdate = list.update
  function list:update(dt)
    baseUpdate(self, dt)
    refreshIdleFooter()
  end

  return {
    clearDetail = function()
      detailFooter = nil
    end,
    restoreIdle = function()
      list.footer = greet
      detailFooter = nil
      refreshIdleFooter()
    end,
  }
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

-- Mirror of src/ui/ShopMenu.lua with TM/HM POWER/ACC in the BUY footer.
local function newShopMenu(mod, game, stock, onQuit)
  local ListMenu = mod.ui.ListMenu
  local Menu = mod.ui.Menu
  local ChoiceBox = mod.ui.ChoiceBox
  local QuantityBox = mod.ui.QuantityBox

  local function showStats()
    return mod.options:get("show_stats") ~= false
  end

  local function buy()
    local items = {}
    for _, id in ipairs(stock or {}) do
      local def = game.data.items[id]
      if def then
        items[#items + 1] = {
          value = id,
          label = def.name,
          right = ("¥%d"):format(def.price),
        }
      end
    end

    local greet = txt(game, "_PokemartBuyingGreetingText", "Take your time.")
    local notEnough = txt(game, "_PokemartNotEnoughMoneyText",
      "You don't have\nenough money.")
    local list
    local footer

    list = ListMenu.new(game, "BUY", items, {
      dialogue = true,
      money = function() return game.save.money end,
      footer = greet,
      onChoose = function(item)
        local def = game.data.items[item.value]
        if game.save.money < def.price then
          list.footer = notEnough
          footer.clearDetail()
          return
        end
        local affordable = math.min(99,
          math.floor(game.save.money / math.max(1, def.price)))
        game.stack:push(QuantityBox.new(game, {
          max = affordable,
          unitPrice = def.price,
          onDone = function(qty)
            if not qty then
              footer.restoreIdle()
              return
            end
            local cost = qty * def.price
            list.footer = ("%s?\nThat will be\n¥%d. OK?"):format(def.name, cost)
            footer.clearDetail()
            game.stack:push(ChoiceBox.new(game, function(yes)
              if not yes then
                footer.restoreIdle()
                return
              end
              if game.save.money < cost then
                list.footer = notEnough
                footer.clearDetail()
                return
              end
              if not bagAdd(game.save, item.value, qty, game) then
                list.footer = txt(game, "_PokemartItemBagFullText",
                  "You can't carry\nany more items.")
                footer.clearDetail()
                return
              end
              game.save.money = game.save.money - cost
              list.footer = txt(game, "_PokemartBoughtItemText",
                "Here you are!\nThank you!")
              footer.clearDetail()
            end))
          end,
        }))
      end,
    })

    footer = wireTmIdleFooter(list, game, greet, showStats)
    game.stack:push(list)
  end

  local function sell()
    local items = {}
    for _, id in ipairs(bagOrder(game.save)) do
      local def = game.data.items[id]
      items[#items + 1] = {
        value = id,
        label = def and def.name or id,
        right = "x" .. game.save.inventory[id],
      }
    end
    local greet = txt(game, "_PokemartBuyingGreetingText", "Take your time.")
    local list
    local footer
    list = ListMenu.new(game, "SELL", items, {
      dialogue = true,
      money = function() return game.save.money end,
      footer = greet,
      onChoose = function(item)
        local def = game.data.items[item.value]
        if not def or def.keyItem or item.value:find("^HM_") then
          list.footer = txt(game, "_PokemartUnsellableItemText",
            "I can't put a\nprice on that.")
          footer.clearDetail()
          return
        end
        local unit = math.floor(def.price / 2)
        game.stack:push(QuantityBox.new(game, {
          max = game.save.inventory[item.value] or 1,
          unitPrice = unit,
          onDone = function(qty)
            if not qty then
              footer.restoreIdle()
              return
            end
            list.footer = ("I can pay you\n¥%d for that."):format(unit * qty)
            footer.clearDetail()
            game.stack:push(ChoiceBox.new(game, function(yes)
              if not yes then
                footer.restoreIdle()
                return
              end
              game.save.money = game.save.money + unit * qty
              bagRemove(game.save, item.value, qty)
              local left = game.save.inventory[item.value]
              if left then
                item.right = "x" .. left
              else
                list:removeCurrent()
              end
              list.footer = txt(game, "_PokemartThankYouText", "Thank you!")
              footer.clearDetail()
            end))
          end,
        }))
      end,
    })
    footer = wireTmIdleFooter(list, game, greet, showStats)
    game.stack:push(list)
  end

  local menu = Menu.new(game, {
    { label = "BUY", keepOpen = true, onSelect = buy },
    { label = "SELL", keepOpen = true, onSelect = sell },
    { label = "QUIT", onSelect = onQuit },
  }, { tx = 0, ty = 0, tw = 8, th = 8 })
  menu.onCancel = onQuit
  return menu
end

return function(mod)
  mod.log:info("carregado")

  mod.options:define({
    { key = "show_stats", type = "toggle", label = "SHOW STATS", default = true },
  })

  mod.content.screens:override("MoveLearnMenu", {
    new = function(game, mon, newMoveId, onDone)
      return newMoveLearnMenu(mod, game, mon, newMoveId, onDone)
    end,
  })

  mod.content.screens:override("ShopMenu", {
    new = function(game, stock, onQuit)
      return newShopMenu(mod, game, stock, onQuit)
    end,
  })

  mod.events:on("game.ready", function()
    local learn = mod.content.screens:get("MoveLearnMenu")
    local shop = mod.content.screens:get("ShopMenu")
    if type(learn) == "table" and type(learn.new) == "function" then
      mod.log:info("MoveLearnMenu override active")
    else
      mod.log:error("MoveLearnMenu override missing after load")
    end
    if type(shop) == "table" and type(shop.new) == "function" then
      mod.log:info("ShopMenu override active")
    else
      mod.log:error("ShopMenu override missing after load")
    end
  end)
end
