  #=============================================================================
   #COMBATE HORIZONTAL
   #CREADO POR MARYN  Maryn @cosmic_pipo(en TW/X)
   #V21.1
  #=============================================================================
class Battle::Scene
  def pbSafariStart
    @briefMessage = false
    @sprites["dataBox_0"] = SafariDataBox.new(@battle, @viewport)
    dataBoxAnim = Animation::DataBoxAppear.new(@sprites, @viewport, 0)
    loop do
      dataBoxAnim.update
      pbUpdate
      break if dataBoxAnim.animDone?
    end
    dataBoxAnim.dispose
    pbRefresh
  end

  def pbSafariCommandMenu(index)
    pbCommandMenuEx(index,
                    [_INTL("", @battle.pbPlayer.name),
                     _INTL("Ball"),
                     _INTL("Cebo"),
                     _INTL("Roca"),
                     _INTL("Huir")], 3)
  end
  def pbCommandMenu(idxBattler, firstAction)
    shadowTrainer = (GameData::Type.exists?(:SHADOW) && @battle.trainerBattle?)
    cmds = [
      _INTL("", @battle.battlers[idxBattler].name),
      _INTL("Luchar"),
      _INTL("Mochila"),
      _INTL("Pokémon"),
      (shadowTrainer) ? _INTL("Llamar") : (firstAction) ? _INTL("Huir") : _INTL("Cancelar")
    ]
    ret = pbCommandMenuEx(idxBattler, cmds, (shadowTrainer) ? 2 : (firstAction) ? 0 : 1)
    ret = 4 if ret == 3 && shadowTrainer   # Convert "Run" to "Call"
    ret = -1 if ret == 3 && !firstAction   # Convert "Run" to "Cancel"
    return ret
  end
  class Battle::Scene::CommandMenu < Battle::Scene::MenuBase
    # If true, displays graphics from Graphics/UI/Battle/overlay_command.png
    #     and Graphics/UI/Battle/cursor_command.png.
    # If false, just displays text and the command window over the graphic
    #     Graphics/UI/Battle/overlay_message.png. You will need to edit def
    #     pbShowWindow to make the graphic appear while the command menu is being
    #     displayed.
    USE_GRAPHICS = true
    # Lists of which button graphics to use in different situations/types of battle.
    MODES = [
      [0, 2, 1, 3],   # 0 = Regular battle
      [0, 2, 1, 9],   # 1 = Regular battle with "Cancel" instead of "Run"
      [0, 2, 1, 4],   # 2 = Regular battle with "Call" instead of "Run"
      [5, 7, 6, 3],   # 3 = Safari Zone
      [0, 8, 1, 3]    # 4 = Bug-Catching Contest
    ]
  
    def initialize(viewport, z)
      super(viewport)
      self.x = 0
      self.y = Graphics.height - 96
      # Create message box (shows "What will X do?")
      @msgBox = Window_UnformattedTextPokemon.newWithSize(
        "", self.x + 16, self.y + 2, 220, Graphics.height - self.y, viewport
      )
      @msgBox.baseColor   = TEXT_BASE_COLOR
      @msgBox.shadowColor = TEXT_SHADOW_COLOR
      @msgBox.windowskin  = nil
      addSprite("msgBox", @msgBox)
      if USE_GRAPHICS
        # Create background graphic
        background = IconSprite.new(self.x, self.y, viewport)
        background.setBitmap("Graphics/UI/Battle/overlay_command")
        addSprite("background", background)
        # Create bitmaps
        @buttonBitmap = AnimatedBitmap.new(_INTL("Graphics/UI/Battle/cursor_command"))
        # Create action buttons
  button_width = 123 / 1 
  button_spacing = 4      
  

  total_button_width = (button_width + button_spacing) * 4 - button_spacing
  

  start_x = self.x + (Graphics.width - total_button_width) / 2
  
  @buttons = Array.new(4) do |i|
        button = Sprite.new(viewport)
        button.bitmap = @buttonBitmap.bitmap
        button.x = start_x + i * (button_width + button_spacing)
        button.y = self.y + Graphics.width - 512 + 6
        button.src_rect.width  = button_width
        button.src_rect.height = 84
      addSprite("button_#{i}", button)
    next button
  end
      else
        # Create command window (shows Fight/Bag/Pokémon/Run)
        @cmdWindow = Window_CommandPokemon.newWithSize(
          [], self.x + Graphics.width - 512, self.y, 512, Graphics.height - 84, viewport
        )
        @cmdWindow.columns       = 0
        @cmdWindow.columnSpacing = 0
        @cmdWindow.ignore_input  = true
        addSprite("cmdWindow", @cmdWindow)
      end
      self.z = z
      refresh
    end
  
    def dispose
      super
      @buttonBitmap&.dispose
    end
  
    def z=(value)
      super
      @msgBox.z    += 1
      @cmdWindow.z += 1 if @cmdWindow
    end
  
    def setTexts(value)
      @msgBox.text = value[0]
      return if USE_GRAPHICS
      commands = []
      (1..4).each { |i| commands.push(value[i]) if value[i] }
      @cmdWindow.commands = commands
    end
  
    def refreshButtons
      return if !USE_GRAPHICS
      @buttons.each_with_index do |button, i|
        button.src_rect.x = (i == @index) ? @buttonBitmap.width / 2 : 0
        button.src_rect.y = MODES[@mode][i] * 84
        button.z          = self.z + ((i == @index) ? 3 : 2)
      end
    end
  
    def refresh
      @msgBox.refresh
      @cmdWindow&.refresh
      refreshButtons
    end
  end
  def pbCommandMenuEx(idxBattler, texts, mode = 0)
    pbRefreshUIPrompt(idxBattler, COMMAND_BOX)
    pbShowWindow(COMMAND_BOX)
    cw = @sprites["commandWindow"]
    cw.setTexts(texts)
    cw.setIndexAndMode(@lastCmd[idxBattler], mode)
    pbSelectBattler(idxBattler)
    ret = -1
    loop do
      oldIndex = cw.index
      pbUpdate(cw)
      if Input.trigger?(Input::LEFT) && (cw.index)!=0
        pbPlayCursorSE()
        cw.index-=1
      elsif Input.trigger?(Input::RIGHT) &&  (cw.index)!=3
        pbPlayCursorSE()
        cw.index+=1
      end
      pbPlayCursorSE if cw.index != oldIndex
      if Input.trigger?(Input::USE)
        pbPlayDecisionSE
        ret = cw.index
        @lastCmd[idxBattler] = ret
        break
      elsif Input.trigger?(Input::BACK) && mode > 0
        pbPlayCancelSE
        break
      elsif Input.trigger?(Input::F9) && $DEBUG
        pbPlayDecisionSE
        pbHideInfoUI
        ret = -2
        break
      elsif Input.trigger?(Input::JUMPUP)
        pbToggleBattleInfo
      elsif Input.trigger?(Input::JUMPDOWN)
        if pbToggleBallInfo(idxBattler)
          ret = 1
          break
        end
      end
    end
    return ret
  end  
end