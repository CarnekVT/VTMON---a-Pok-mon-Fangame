FLY_MENU_OFF = 71

#===============================================================================
# Menu Custom (Menu Parrilla)
# Script originalmente creado por: Polectron
# Solucion de errores y adaptacion a la V21.1: Maryn
#===============================================================================
class Scene_Map
  alias :original_call_menu :call_menu
  def call_menu
    $game_temp.menu_calling = false
    $game_player.straighten
    $game_map.update
    pbCallMenu2
  end
end

class Menu2
  def initialize
    @selected_item = 0
    @items = []

    if $game_switches[68] # Verificar si el switch para la Pokédex está activado
      @PokedexCmd = addCmd(["pokedex", "Pokédex", "openPokedex", :selectable])
    end

    if $player.party_count > 0 # Verificar si el jugador tiene al menos un Pokémon en el equipo
      @partyCmd = addCmd(["pokeball", "Equipo", "openParty", :selectable])
    end

    @bagCmd = addCmd(["bag", "Mochila", "openBag", :selectable])

    if $game_switches[69] # Verificar si el switch para el PC está activado
      @pcCmd = addCmd(["pc", "PC", "openPC", :selectable])
    end

    @optionsCmd = addCmd(["options", "Opciones", "openOptions", :selectable])
    @saveCmd = addCmd(["save", "Guardar", "openSave", :selectable])

    if $game_switches[66] # Verificar si el switch para el Fly Activo
    @flyCmd = addCmd(["fly", "Pokérider", "openFlyScreen", :non_selectable])
    end

    if $game_switches[65] # Verificar si el switch para el Wild Activo
    @wildCmd = addCmd(["wild", "Salvaje", "pbWildEncounter", :non_selectable])
    end

    @icon_width = 78
    @icon_height = 88

    @n_icons = 2 # Iconos por fila
    @spacing_x = 26 # Espacio en x entre los iconos
    @spacing_y = 16 # Espacio en y entre los iconos

    @menu_width = @n_icons * (@icon_width + @spacing_x) - @spacing_x
    @menu_height = (@items.length / @n_icons.to_f).ceil * (@icon_height + @spacing_y) - @spacing_y

    @x_margin = 328 # Ajustar margen derecho para el panel amarillo
    @y_margin = 36 # Ajustar margen superior para el panel amarillo

    @exit = false
  end

  def pbStartScene
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999

    @sprites["bg"] = Sprite.new(@viewport)
    @sprites["bg"].bitmap = RPG::Cache.ui("Menu Custom/menubg")

    # Agregar paneles de fondo
    if $game_switches[67] # Verificar si el switch para el panel azul está activado
      @sprites["panel_blue"] = Sprite.new(@viewport)
      @sprites["panel_blue"].bitmap = RPG::Cache.ui("Menu Custom/Panel 2")  # Panel azul horizontal de 328x100
      @sprites["panel_blue"].x = (Graphics.width - 512) / 1
      @sprites["panel_blue"].y = -100 # Empieza fuera de la pantalla por arriba
    end

    @sprites["panel_yellow"] = Sprite.new(@viewport)
    @sprites["panel_yellow"].bitmap = RPG::Cache.ui("Menu Custom/Panel 1")  # Panel amarillo vertical de 230x384
    @sprites["panel_yellow"].x = Graphics.width # Empieza fuera de la pantalla por la derecha
    @sprites["panel_yellow"].y = (Graphics.height - 384) / 2

    counter = 0
    @items.each do |item|
      next if (item[0] == "fly" && !$game_switches[66]) || (item[0] == "wild" && !$game_switches[65]) # Ocultar íconos según switches

      @sprites["item_#{counter}"] = Sprite.new(@viewport)
      icon_path = item[0] == "fly" || item[0] == "wild" ? "Menu Custom/Icons/#{item[0]}" : "Menu Custom/#{item[0]}"
      @sprites["item_#{counter}"].bitmap = RPG::Cache.ui(icon_path)

      if item[0] == "fly"
        @sprites["item_#{counter}"].x = 150 # Posición fija para el ícono de Vuelo al extremo izquierdo
        @sprites["item_#{counter}"].y = 4
      elsif item[0] == "wild"
        @sprites["item_#{counter}"].x = 50 # Posición fija para el ícono de Encuentros Salvajes al extremo izquierdo
        @sprites["item_#{counter}"].y = 4
      else
        @sprites["item_#{counter}"].x = @x_margin + ((@icon_width + @spacing_x) * (counter % @n_icons))
        @sprites["item_#{counter}"].y = @y_margin + ((@icon_height + @spacing_y) * (counter / @n_icons))
      end

      @sprites["item_#{counter}"].opacity = 0 # Los íconos comienzan invisibles
      counter += 1
    end

    @sprites["selector"] = Sprite.new(@viewport)
    @sprites["selector"].bitmap = RPG::Cache.ui("Menu Custom/menu_selection")
    @sprites["selector"].z = 99999
    @sprites["selector"].opacity = 0 # El selector comienza invisible

    animateMenuAppearance
    pbSEPlay("menu")
  end

  def animateMenuAppearance
    20.times do
      @sprites["panel_blue"].y += 5 if @sprites["panel_blue"] && @sprites["panel_blue"].y < 0
      @sprites["panel_yellow"].x -= 11 if @sprites["panel_yellow"].x > Graphics.width - 230
      Graphics.update
    end

    # Hacer aparecer los iconos y el selector
    15.times do
      @items.each_with_index do |_, index|
        @sprites["item_#{index}"].opacity += 17 if @sprites["item_#{index}"] && @sprites["item_#{index}"].opacity < 255
      end
      if @sprites["selector"].opacity < 255
        @sprites["selector"].opacity += 17
        redrawSelector # Ajustar el selector en su primera posición
      end
      Graphics.update
    end
  end

  def animateMenuClosure
    return if @items.nil? || @items.empty? || @sprites.nil?  # Validación adicional para evitar problemas con @sprites
  
    # Animación de los items y el selector
    10.times do
      @items.each_with_index do |_, index|
        sprite_key = "item_#{index}"
        sprite = @sprites[sprite_key] if @sprites.key?(sprite_key)  # Verificar si la clave existe
        next unless sprite  # Ignorar si el sprite no existe o es nil
        sprite.opacity -= 25 if sprite.opacity > 0
      end
  
      if @sprites.key?("selector")
        selector = @sprites["selector"]
        selector.opacity -= 25 if selector && selector.opacity > 0
      end
  
      Graphics.update
    end
  
    # Animación de los paneles
    10.times do
      if @sprites.key?("panel_blue")
        panel_blue = @sprites["panel_blue"]
        panel_blue.y -= 10 if panel_blue && panel_blue.y > -100
      end
  
      if @sprites.key?("panel_yellow")
        panel_yellow = @sprites["panel_yellow"]
        panel_yellow.x += 22 if panel_yellow && panel_yellow.x < Graphics.width
      end
  
      Graphics.update
    end
  end
  
  def pbEndScene
    return if @items.empty?  # Evitar problemas si el menú no tiene items
  
    # Solo llamar a la animación si realmente se debe cerrar
    animateMenuClosure
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose if @viewport
  end
  

  def redrawSelector
    return if @items.empty?  # Evitar errores si @items está vacío
  
    # Aseguramos que el selector sólo se mueva si el sprite está inicializado correctamente
    if @sprites["selector"]
      # Ajustar índice a límites válidos
      @selected_item = [[@selected_item, 0].max, @items.length - 1].min
  
      # Saltar ítems no seleccionables sin necesidad de loop infinito
      while @items[@selected_item][3] != :selectable
        # Aseguramos que no se salga de los límites
        @selected_item += 1 if Input.trigger?(Input::RIGHT) || Input.trigger?(Input::DOWN)
        @selected_item -= 1 if Input.trigger?(Input::LEFT) || Input.trigger?(Input::UP)
  
        # Evitar salirse de los límites de la lista
        @selected_item = [@selected_item, 0].max
        @selected_item = [@selected_item, @items.length - 1].min
      end
  
      # Posicionar el selector
      @sprites["selector"].x = @x_margin + ((@icon_width + @spacing_x) * (@selected_item % @n_icons))
      @sprites["selector"].y = @y_margin + ((@icon_height + @spacing_y) * (@selected_item / @n_icons))
    end
  end  
  
  def addCmd(item)
    raise "Comando inválido: #{item}" unless item.is_a?(Array) && item.length >= 4
    @items.push(item).length - 1
  end

  def pbUpdate
    return if @items.empty?  # Evitar errores si @items está vacío

    loop do
      Input.update

      if Input.trigger?(Input::RIGHT)
        @selected_item += 1
      elsif Input.trigger?(Input::LEFT)
        @selected_item -= 1
      elsif Input.trigger?(Input::UP)
        @selected_item -= @n_icons
        @selected_item = 0 if @selected_item < 0
      elsif Input.trigger?(Input::DOWN)
        @selected_item += @n_icons
      elsif Input.trigger?(Input::AUX1) # Salvaje
        pbWildEncounter if $game_switches[65]
      elsif Input.trigger?(Input::AUX2) # Vuelo
        openFlyScreen if $game_switches[66]
      elsif Input.trigger?(Input::ACTION) # Tarjeta de Entrenador
        openTrainerCard
      end

      # Ajustar el índice al rango permitido
      @selected_item = 0 if @selected_item >= @items.length
      @selected_item = @items.length - 1 if @selected_item < 0

      # Saltar comandos no seleccionables
      loop do
        break if @items[@selected_item][3] == :selectable
        @selected_item += 1 if Input.trigger?(Input::RIGHT) || Input.trigger?(Input::DOWN)
        @selected_item -= 1 if Input.trigger?(Input::LEFT) || Input.trigger?(Input::UP)

        # Prevenir bucles infinitos asegurando que no salga del rango
        @selected_item = 0 if @selected_item >= @items.length
        @selected_item = @items.length - 1 if @selected_item < 0
      end

      # Confirmación de selección
      if Input.trigger?(Input::C) && @items[@selected_item][3] == :selectable
        send(@items[@selected_item][2])
      end

      # Salir del menú
      break if Input.trigger?(Input::B) || @exit

      redrawSelector
      Graphics.update
    end
  end
end

def pbCallMenu2
  scene = Menu2.new
  scene.pbStartScene
  scene.pbUpdate
  scene.pbEndScene
end

def exitMenu
  @exit = true
end

def openOptions
  scene = PokemonOption_Scene.new
  screen = PokemonOptionScreen.new(scene)
  pbFadeOutIn { screen.pbStartScreen }
end

def openParty
  if $player.party_count == 0
    pbMessage(_INTL("No tienes la Pokémon en el equipo."))
  else
    hidden_move = nil
    pbFadeOutIn do
      sscene = PokemonParty_Scene.new
      sscreen = PokemonPartyScreen.new(sscene, $player.party)
      hidden_move = sscreen.pbPokemonScreen
    end

    if hidden_move
      pbEndScene
      exitMenu  # Asegura que el menú no se quede abierto o invisible
      $game_temp.menu_calling = false  # Evita futuras llamadas al menú
      pbUseHiddenMove(hidden_move[0], hidden_move[1])
      pbEndScene if @sprites && @sprites.any?  # Asegurarse que no quede nada visible del menú
      @sprites = nil
      @viewport.dispose if @viewport
    end
  end
end

def openBag
  # Abre la mochila sin cerrar el menú
  scene = PokemonBag_Scene.new
  screen = PokemonBagScreen.new(scene, $bag)
  item = nil
  
  pbFadeOutIn do
    item = screen.pbStartScreen  # El ítem seleccionado en la mochila
  end
  
  # Si un item es seleccionado, se usa como objeto clave
  if item
    # Aseguramos que el menú se cierre de inmediato antes de usar el item
    pbEndScene
    exitMenu  # Asegura que el menú no se quede abierto o invisible
    $game_temp.menu_calling = false  # Evita futuras llamadas al menú
    
    # Usamos el item clave después de haber cerrado correctamente el menú
    Kernel.pbUseKeyItemInField(item)
    
    # Limpieza final para asegurarnos de que no quede nada del menú
    pbEndScene if @sprites && @sprites.any?  # Asegurarse que no quede nada visible del menú
    @sprites = nil
    @viewport.dispose if @viewport
  end
end

def openTrainerCard
  scene = PokemonTrainerCard_Scene.new
  screen = PokemonTrainerCardScreen.new(scene)
  pbFadeOutIn { screen.pbStartScreen }
end

def openSave
  scene = PokemonSave_Scene.new
  screen = PokemonSaveScreen.new(scene)
  if screen.pbSaveScreen
    @exit = true
  end
end

def openPokedex
  if $player.has_pokedex
    scene = PokemonPokedex_Scene.new
    screen = PokemonPokedexScreen.new(scene)
    pbFadeOutIn { screen.pbStartScreen }
  else
    pbMessage(_INTL("No tienes la Pokédex."))
  end
end

def pbWildEncounter
  scene = EncounterList_Scene.new
  screen = EncounterList_Screen.new(scene)
  screen.pbStartScreen
end

def openFlyScreen(fuera_de_menu = false)
  pbFadeOutIn do
    # Inicializamos la escena del mapa
    scene = PokemonRegionMap_Scene.new(-1, false)
    screen = PokemonRegionMapScreen.new(scene)
    if fuera_de_menu
      ret = screen.pbStartFlyScreen
    else
      ret = screen.pbStartScreen
    end   
    $game_temp.fly_destination = ret if ret
    ($game_temp.fly_destination) ? exitMenu : return #menu.pbRefresh
    # Si tenemos un destino, cerramos el menú y volamos
    if $game_temp.fly_destination
      pbEndScene
      exitMenu  # Asegura que el menú no se quede abierto o invisible
      $game_temp.menu_calling = false  # Evita futuras llamadas al menú
      pbFlyToNewLocation  # Realiza la acción de vuelo
    else
      pbEndScene if @sprites && @sprites.any?
      @sprites = nil
      @viewport.dispose if @viewport
      # Si no se seleccionó un destino, regresamos al menú de vuelo
      return
    end
  end
end

def openPC
  pbMessage("\\se[PC open]" + _INTL("{1} encendió el PC.", $player.name))

  # Obtener todas las opciones disponibles para el PC
  command_list = []
  commands = []
  MenuHandlers.each_available(:pc_menu) do |option, hash, name|
    command_list.push(name)
    commands.push(hash)
  end

  # Bucle principal para mostrar el menú del PC
  command = 0
  loop do
    choice = pbMessage(_INTL("¿A qué PC quieres acceder?"), command_list, -1, nil, command)
    if choice < 0
      pbPlayCloseMenuSE
      break
    end
    break if commands[choice]["effect"].call
  end

  pbSEPlay("PC close")
end
