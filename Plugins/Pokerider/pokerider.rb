ADD_POKERIDER_SHORTCUT_IN_MENU = true
ItemHandlers::UseFromBag.add(:POKERIDER, proc { |item|
  pokerider(true)
  next ($game_temp.fly_destination) ? 2 : 0
})

ItemHandlers::UseInField.add(:POKERIDER, proc { |item|
  pbShowMap(-1, false) if $game_temp.fly_destination.nil?
  pbFlyToNewLocation
  next true
})

def pokerider(bag = false)
    ret = false
    pbFadeOutIn do
        scene = PokemonRegionMap_Scene.new(-1, false)
        screen = PokemonRegionMapScreen.new(scene)
        ret = screen.pbStartFlyScreen
        $game_temp.fly_destination = ret if ret
        next 99999 if (ret && bag)   # Ugly hack to make Bag scene not reappear if flying
    end
    return (ret) ? true : false
    # return pbFlyToNewLocation
end

if ADD_POKERIDER_SHORTCUT_IN_MENU
    class PokemonPauseMenu_Scene
        alias pbStartScene_old pbStartScene
        def pbStartScene
            pbStartScene_old
            draw_fly_shortcut if $bag.has?(:POKERIDER)
        end
        
        def draw_fly_shortcut
            # Color base del texto mostrado
            base_color = Color.new(250, 250, 250)
    
            # Color de sombra del texto mostrado
            shadow_color = Color.new(75,75,75)
            bitmap = pbBitmap("Graphics/Items/POKERIDER")
            @sprites["pokerider_container"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
            @sprites["pokerider"] = Sprite.new(@viewport)
            @sprites["pokerider"].bitmap = bitmap
            @sprites["pokerider"].x = 5
            @sprites["pokerider"].y = 5
            pbDrawTextPositions(@sprites["pokerider_container"].bitmap, [
                ["[D] Volar",105,17,2,base_color,shadow_color, true]
            ])
        end

        def pbShowCommands(commands)
            ret = -1
            cmdwindow = @sprites["cmdwindow"]
            cmdwindow.commands = commands
            cmdwindow.index    = $game_temp.menu_last_choice
            cmdwindow.resizeToFit(commands)
            cmdwindow.x        = Graphics.width - cmdwindow.width
            cmdwindow.y        = 0
            cmdwindow.visible  = true
            loop do
            cmdwindow.update
            Graphics.update
            Input.update
            pbUpdateSceneMap
            if Input.trigger?(Input::SPECIAL) && $bag.has?(:POKERIDER)
                pbPlayDecisionSE
                if pokerider()
                    pbFlyToNewLocation
                    ret = -2
                    break
                end
            end
            if Input.trigger?(Input::BACK) || Input.trigger?(Input::ACTION)
                ret = -1
                break
            elsif Input.trigger?(Input::USE)
                ret = cmdwindow.index
                $game_temp.menu_last_choice = ret
                break
            end
            end
            return ret
        end
    end
end