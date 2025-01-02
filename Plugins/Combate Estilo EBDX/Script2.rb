  #=============================================================================
   #BOTONES ATAQUES HORIZONTAL
   #CREADO POR MARYN @cosmic_pipo/@PkmnRadiante(en TW/X)
   #V21.1(BASE DE SKY)
  #=============================================================================
  class Battle::Scene::FightMenu < Battle::Scene::MenuBase
    GET_MOVE_TEXT_COLOR_FROM_MOVE_BUTTON = false #Cambiar a false si deseas que los botones no muestren los colores según el tipo
  #==========================================================================================================================================================
    PP_COLORS = [                                      # Colores de los PP
    Color.new(248, 72, 72), Color.new(136, 48, 48),    # Rojo, cuando los PP son 0
    Color.new(248, 136, 32), Color.new(144, 72, 24),   # Naranja cuando queda 1/4 de los pp o menos
    Color.new(248, 192, 0), Color.new(144, 104, 0),    # Amarillo, cuando queda 1/2 de los pp o menos
    Color.new(255, 255, 255), Color.new(32, 32, 32)    # Color normal cuando es mayor a 1/2
  ]
  end
  #==========================================================================================================================================================
  class Battle::Scene::MenuBase
    BUTTON_HEIGHT = 46
    TEXT_BASE_COLOR   = Color.new(255, 255, 255) #Solo funciona cuando GET_MOVE_TEXT_COLOR_FROM_MOVE_BUTTON es false, este es el color base
    TEXT_SHADOW_COLOR = Color.new(32, 32, 32) #Solo funciona cuando GET_MOVE_TEXT_COLOR_FROM_MOVE_BUTTON es false, este es el color de las sombra
  end
  #==========================================================================================================================================================
class Battle::Scene::FightMenu < Battle::Scene::MenuBase
  def initialize(viewport, z)
    super(viewport)
    self.x = 0
    self.y = Graphics.height - 96
    @battler = nil
    resetMenuToggles
    @customUI = PluginManager.installed?("Customizable Battle UI")
    folder = @customUI ? "#{$game_variables[53]}/" : ""
    path = "Graphics/UI/Battle/" + folder
    if USE_GRAPHICS
      @buttonBitmap  = AnimatedBitmap.new(_INTL(path + "cursor_fight"))
      @typeBitmap    = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
      @shiftBitmap   = AnimatedBitmap.new(_INTL(path + "cursor_shift"))
      @actionButtonBitmap = {}
      addSpecialActionButtons(path)
      background = IconSprite.new(0, Graphics.height - 96, viewport)
      background.setBitmap(path + "overlay_fight")
      addSprite("background", background)
total_width = 4 * (@buttonBitmap.width / 2 + 3)  

start_x = (Graphics.width - total_width) / 2

# Create move buttons
@buttons = Array.new(Pokemon::MAX_MOVES) do |i|  
  button = Sprite.new(viewport)
  button.bitmap = @buttonBitmap.bitmap
  button.x = start_x + i * (@buttonBitmap.width / 2 + 4)  
  button.y = self.y + 4                                   
  button.src_rect.width = @buttonBitmap.width / 2
  button.src_rect.height = @buttonBitmap.height / 19
  addSprite("button_#{i}", button)
  next button
end
      @overlay = BitmapSprite.new(Graphics.width, Graphics.height - self.y, viewport)
      @overlay.x = self.x
      @overlay.y = self.y
      pbSetNarrowFont(@overlay.bitmap)
      addSprite("overlay", @overlay)
      @infoOverlay = BitmapSprite.new(Graphics.width, Graphics.height - self.y, viewport)
      @infoOverlay.x = self.x
      @infoOverlay.y = self.y
      pbSetNarrowFont(@infoOverlay.bitmap)
      addSprite("infoOverlay", @infoOverlay)
      @typeIcon = Sprite.new(viewport)
      @typeIcon.bitmap = @typeBitmap.bitmap
      @typeIcon.x      = self.x + 416
      @typeIcon.y      = self.y + 20
      @typeIcon.src_rect.height = TYPE_ICON_HEIGHT
      addSprite("typeIcon", @typeIcon)
      @actionButton = Sprite.new(viewport)
      addSprite("actionButton", @actionButton)
      @shiftButton = Sprite.new(viewport)
      @shiftButton.bitmap = @shiftBitmap.bitmap
      @shiftButton.x      = self.x + 4
      @shiftButton.y      = self.y - @shiftBitmap.height
      addSprite("shiftButton", @shiftButton)
    else
      @msgBox = Window_AdvancedTextPokemon.newWithSize(
        "", self.x + 320, self.y, Graphics.width - 320, Graphics.height - self.y, viewport
      )
      @msgBox.baseColor   = @customUI ? @base_color   : TEXT_BASE_COLOR
      @msgBox.shadowColor = @customUI ? @shadow_color : TEXT_SHADOW_COLOR
      pbSetNarrowFont(@msgBox.contents)
      addSprite("msgBox", @msgBox)
      @cmdWindow = Window_CommandPokemon.newWithSize(
        [], self.x, self.y, 320, Graphics.height - self.y, viewport
      )
      @cmdWindow.columns       = 2
      @cmdWindow.columnSpacing = 4
      @cmdWindow.ignore_input  = true
      pbSetNarrowFont(@cmdWindow.contents)
      addSprite("cmdWindow", @cmdWindow)
    end
    self.z = z
  end

  def refreshSpecialActionButton
    return if !USE_GRAPHICS
    button = @actionButtonBitmap[@chosenButton]
    if !button
      @visibility["actionButton"] = false
    else
      buttonCount, buttonMode = getButtonSettings
      @actionButton.bitmap = button.bitmap    
      @actionButton.x = self.x + ((@shiftMode > 0) ? 204 : 120)
      @actionButton.y = self.y - (button.height / buttonCount)
      @actionButton.src_rect.height = button.height / buttonCount
      @actionButton.src_rect.y = buttonMode * button.height / buttonCount
      @actionButton.z = self.z - 1
      @visibility["actionButton"] = (@mode > 0)
    end
  end
  
  def refreshButtonNames
    moves = (@battler) ? @battler.moves : []
    if !USE_GRAPHICS
      commands = []
      [4, moves.length].max.times do |i|
        commands.push((moves[i]) ? moves[i].name : "-")
      end
      @cmdWindow.commands = commands
      return
    end
    @overlay.bitmap.clear
    textPos = []
    @buttons.each_with_index do |button, i|
      next if !@visibility["button_#{i}"]
      x = button.x - self.x + (button.src_rect.width / 2)
      y = button.y - self.y + 20
      moveNameBase = TEXT_BASE_COLOR
      moveNameShadow = TEXT_SHADOW_COLOR
      if GET_MOVE_TEXT_COLOR_FROM_MOVE_BUTTON && moves[i].display_type(@battler)
        moveNameBase = button.bitmap.get_pixel(10, button.src_rect.y + 5)
        moveNameShadow = button.bitmap.get_pixel(10, button.src_rect.y + 7)
      end
      base   = @customUI ? @base_color   : moveNameBase
      shadow = @customUI ? @shadow_color : moveNameShadow
      
   
      move_name = moves[i].short_name.split(" ")
      if move_name.length > 1
        first_line = move_name[0]
        second_line = move_name[1]
        textPos.push([first_line, x, y-10, :center, base, shadow,:outline])
        textPos.push([second_line, x, y + 10, :center, base, shadow,:outline]) 
      else
        textPos.push([moves[i].short_name, x, y, :center, base, shadow,:outline])
      end
      if move_name.length > 2
        first_line = move_name[0]
        second_line = move_name[1]
        thirt_line = move_name[2]
        textPos.push([first_line, x, y- 10, :center, base, shadow,:outline])
        textPos.push([second_line, x, y + 10, :center, base, shadow,:outline])
        textPos.push([thirt_line, x, y + 30, :center, base, shadow,:outline])  
      else
        if move_name.length > 1
          first_line = move_name[0]
          second_line = move_name[1]
          textPos.push([first_line, x, y-10, :center, base, shadow,:outline])
          textPos.push([second_line, x, y + 10, :center, base, shadow,:outline]) 
        else
          textPos.push([moves[i].short_name, x, y, :center, base, shadow,:outline])
      end
    end
    end
    pbDrawTextPositions(@overlay.bitmap, textPos)
    
  end

  def refresh
    return if !@battler
    refreshSelection
    refreshSpecialActionButton
    refreshShiftButton
    refreshButtonNames
  end
  def refreshMoveData(move)
  # Write PP and type of the selected move
  if !USE_GRAPHICS
    return if !move
    moveType = GameData::Type.get(move.display_type(@battler)).name
    if move.total_pp <= 0
      @msgBox.text = _INTL("PP: ---<br>TIPO/{1}", moveType)
    else
      @msgBox.text = _ISPRINTF("PP: {1: 2d}/{2: 2d}<br>TIPO/{3:s}",
                               move.pp, move.total_pp, moveType)
    end
    return
  end
  @infoOverlay.bitmap.clear
  if !move
    @visibility["typeIcon"] = false
    return
  end
  @visibility["typeIcon"] = true
  # Type icon
  type_number = GameData::Type.get(move.display_type(@battler)).icon_position
  @typeIcon.src_rect.y = type_number * TYPE_ICON_HEIGHT
  type_icon_width = @typeIcon.bitmap.width  
  # PP text
  if move.total_pp > 0
    ppFraction = [(4.0 * move.pp / move.total_pp).ceil, 3].min
    pp_text = _INTL("PP: {1}/{2}", move.pp, move.total_pp)
    pp_width = @infoOverlay.bitmap.text_size(pp_text).width
    total_width = pp_width + type_icon_width + 5 
  
    type_icon_x = (Graphics.width - total_width) / 2 - 0 
    pp_text_x = type_icon_x + type_icon_width + 45
    
    type_icon_y = 356
    pp_text_y = 72
    @typeIcon.x = type_icon_x
    @typeIcon.y = type_icon_y
    textPos = [[pp_text,
                pp_text_x, pp_text_y, :center, PP_COLORS[ppFraction * 2], PP_COLORS[(ppFraction * 2) + 1]]]
    pbDrawTextPositions(@infoOverlay.bitmap, textPos)
  end
end
  def refreshSelection
    moves = (@battler) ? @battler.moves : []
    if USE_GRAPHICS
      # Choose appropriate button graphics and z positions
      @buttons.each_with_index do |button, i|
        if !moves[i]
          @visibility["button_#{i}"] = false
          next
        end
        @visibility["button_#{i}"] = true
        button.src_rect.x = (i == @index) ? @buttonBitmap.width / 2 : 0
        button.src_rect.y = GameData::Type.get(moves[i].display_type(@battler)).icon_position * @buttonBitmap.height / 19
        button.z          = self.z + ((i == @index) ? 4 : 3)
      end
    end
    refreshMoveData(moves[@index])
  end
end
class Battle::Scene
  def pbFightMenu(idxBattler, specialAction = nil)
    battler = @battle.battlers[idxBattler]
    cw = @sprites["fightWindow"]
    cw.battler = battler
    moveIndex = 0
    if battler.moves[@lastMove[idxBattler]]&.id
      moveIndex = @lastMove[idxBattler]
    end
    cw.setIndexAndMode(moveIndex, (!specialAction.nil?) ? 1 : 0)
    pbSetSpecialActionModes(idxBattler, specialAction, cw)
    cw.refresh
    needFullRefresh = true
    needRefresh = false
    #button3 = pbAddSprite("button3", 6, 242, "Graphics/UI/Battle/DBK/boton3", @viewport)
    #button3.z = 250
    loop do
      if needFullRefresh
        #pbShowButtons(true)
        pbShowWindow(FIGHT_BOX)
        pbSelectBattler(idxBattler)
        needFullRefresh = false
      end
      if needRefresh
        newMode = (@battle.pbBattleMechanicIsRegistered?(idxBattler, specialAction)) ? 2 : 1
        if newMode != cw.mode
          cw.mode = newMode 
          pbFightMenu_Update(battler, specialAction, cw)
        end
        needRefresh = false
      end
      oldIndex = cw.index
      pbUpdate(cw)
      if Input.trigger?(Input::LEFT)
        cw.index -= 1 if (cw.index > 0)
      elsif Input.trigger?(Input::RIGHT)
        cw.index += 1 if (cw.index < battler.moves.length - 1)
      end
      if cw.index != oldIndex
        pbPlayCursorSE
        pbFightMenu_Update(battler, specialAction, cw)		
      end
      if Input.trigger?(Input::USE)
        pbPlayDecisionSE
        #pbHideButtons
        break if yield pbFightMenu_Confirm(battler, specialAction, cw)
        needFullRefresh = true
        needRefresh = true
      elsif Input.trigger?(Input::BACK)
        #button3.visible = false
        break if yield pbFightMenu_Cancel(battler, specialAction, cw)
        needRefresh = true
      elsif Input.trigger?(Input::ACTION)
        if specialAction
          needFullRefresh = pbFightMenu_Action(battler, specialAction, cw)
          break if yield specialAction
          needRefresh = true
        end
      elsif Input.trigger?(Input::SPECIAL)
        if cw.shiftMode > 0
          break if yield pbFightMenu_Shift(battler, cw)
          needRefresh = true
        end
      end
      pbFightMenu_Extra(battler, specialAction, cw)
    end
    pbFightMenu_End(battler, specialAction, cw)
    @lastMove[idxBattler] = cw.index
  end
end