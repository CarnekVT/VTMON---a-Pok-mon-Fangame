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

    @bagCmd = addCmd(["bag", "Mochila", "openBag"])
    @partyCmd = addCmd(["pokeball", "Equipo", "openParty"])
    @trainerCmd = addCmd(["trainer", "Tarjeta", "openTrainerCard"])
    @saveCmd = addCmd(["save", "Guardar", "openSave"])
    @optionsCmd = addCmd(["options", "Opciones", "openOptions"])
    @PokedexCmd = addCmd(["pokedex", "Pokédex", "openPokedex"])
    @debugCmd = addCmd(["debug", "Debug", "pbDebugMenu"]) if $DEBUG
    @exitCmd = addCmd(["exit", "Salir", "exitMenu"])

    @icon_width = 66
    @icon_height = 66

    @n_icons = 4 # Iconos por fila
    @spacing_x = 20 # Espacio en x entre los iconos
    @spacing_y = 20 # Espacio en y entre los iconos

    @menu_width = @n_icons * (@icon_width + @spacing_x) - @spacing_x
    @menu_height = (@items.length / @n_icons.to_f).ceil * (@icon_height + @spacing_y) - @spacing_y

    @x_margin = (Graphics.width - @menu_width) / 2 # Separación entre los iconos y el borde izquierdo de la pantalla
    @y_margin = (Graphics.height - @menu_height) / 2 # Separación entre los iconos y el borde superior de la pantalla

    @exit = false
  end

  def pbStartScene
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999

    @sprites["bg"] = Sprite.new(@viewport)
    @sprites["bg"].bitmap = RPG::Cache.ui("Menu Custom/menubg")

    counter = 0
    @items.each do |item|
      @sprites["item_#{counter}"] = Sprite.new(@viewport)
      @sprites["item_#{counter}"].bitmap = RPG::Cache.ui("Menu Custom/#{item[0]}")
      @sprites["item_#{counter}"].x = @x_margin + ((@icon_width + @spacing_x) * (counter % @n_icons))
      @sprites["item_#{counter}"].y = @y_margin + ((@icon_height + @spacing_y) * (counter / @n_icons))
      counter += 1
    end

    @sprites["selector"] = Sprite.new(@viewport)
    @sprites["selector"].bitmap = RPG::Cache.ui("Menu Custom/menu_selection")
    redrawSelector
    @sprites["selector"].z = 99999

    pbSEPlay("menu")
  end

  def pbEndScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose if @viewport
  end

  def redrawSelector
    @sprites["selector"].x = @x_margin + ((@icon_width + @spacing_x) * (@selected_item % @n_icons))
    @sprites["selector"].y = @y_margin + ((@icon_height + @spacing_y) * (@selected_item / @n_icons))
  end

  def addCmd(item)
    @items.push(item).length - 1
  end

  def pbUpdate
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
        @selected_item = @items.length - 1 if @selected_item > @items.length - 1
      end

      @selected_item = @items.length - 1 if @selected_item < 0
      @selected_item = 0 if @selected_item >= @items.length

      if Input.trigger?(Input::C)
        send(@items[@selected_item][2])
      end

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

def openBag
  scene = PokemonBag_Scene.new
  screen = PokemonBagScreen.new(scene, $bag)
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
    $game_temp.in_menu = false
    pbUseHiddenMove(hidden_move[0], hidden_move[1])
  end
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