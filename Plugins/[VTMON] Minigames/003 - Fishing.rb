class PescaMinigame
    attr_accessor :success
  
    def initialize(viewport)
      @viewport = viewport
      reset_game
      @exclaim_triggered = false  # Controla si la exclamación ya fue disparada
      @combat_triggered = false  # Controla si el combate ya fue disparado
      @victory_checked = false   # Comprobador de victoria que se reinicia al regresar al overworld
    end
  
    def reset_game
      # Inicializar variables y sprites del minijuego
      @background = Sprite.new(@viewport)
      @background.bitmap = pbBitmap("Graphics/UI/FishingMinigame/bg_fishing")
  
      @bar = Sprite.new(@viewport)
      @bar.bitmap = pbBitmap("Graphics/UI/FishingMinigame/bar_vertical")
      @bar.x = 230
      @bar.y = 90
  
      @zone_green = Sprite.new(@viewport)
      @zone_green.bitmap = pbBitmap("Graphics/UI/FishingMinigame/zone_green")
      @zone_green.x = 230
      @zone_green.y = @bar.y + rand(@bar.bitmap.height - @zone_green.bitmap.height) # Posición aleatoria inicial
  
      @marker = Sprite.new(@viewport)
      @marker.bitmap = pbBitmap("Graphics/UI/FishingMinigame/marker")
      @marker.x = 230
      @marker.y = @bar.y + @bar.bitmap.height / 2 - @marker.bitmap.height / 2
  
      @progress_bar = Sprite.new(@viewport)
      @progress_bar.bitmap = pbBitmap("Graphics/UI/FishingMinigame/progress_bar")
      @progress_bar.x = 100
      @progress_bar.y = 330
  
      @progress_fill = Sprite.new(@viewport)
      @progress_fill.bitmap = pbBitmap("Graphics/UI/FishingMinigame/progress_fill")
      @progress_fill.x = @progress_bar.x
      @progress_fill.y = @progress_bar.y
      @progress_fill.zoom_x = 0.0
  
      @success_icon = Sprite.new(@viewport)
      @success_icon.bitmap = pbBitmap("Graphics/UI/FishingMinigame/success_icon")
      @success_icon.visible = false
  
      @fail_icon = Sprite.new(@viewport)
      @fail_icon.bitmap = pbBitmap("Graphics/UI/FishingMinigame/fail_icon")
      @fail_icon.visible = false
  
      # Estado del juego
      @success = false
      @progress = 0.0
      @marker_speed = 4 # Reducir la velocidad del marcador
      @timer = 400 # Aumentar el tiempo del temporizador
  
      fade_in # Desvanecimiento inicial
      pbSEPlay("PC Access")
    end
  
    def update
      return if disposed?
  
      handle_input
      check_marker_in_zone
      update_progress_bar
  
      # Movimiento de la zona verde de forma dinámica, con más rango de movimiento
      move_zone_green
  
      # Actualización del temporizador
      @timer -= 1
  
      # Condiciones de fin de juego
      if @timer <= 0
        fail_minigame
      elsif @progress >= 1.0
        win_minigame
      end
    end
  
    # Función para mover el marcador sin sobrepasar el borde gris de la barra
    def handle_input
      # Movimiento del marcador según la entrada del jugador
      if Input.press?(Input::UP)
        # Asegurarse de que no se mueva fuera de la parte gris de la barra
        @marker.y -= @marker_speed unless @marker.y <= @bar.y + 12
      elsif Input.press?(Input::DOWN)
        # Asegurarse de que no se mueva fuera de la parte gris de la barra
        @marker.y += @marker_speed unless @marker.y + @marker.bitmap.height >= @bar.y + @bar.bitmap.height - 12
      end
    end
  
    def check_marker_in_zone
      if @marker.y.between?(@zone_green.y, @zone_green.y + @zone_green.bitmap.height - @marker.bitmap.height)
        @progress += 0.005 # Reducir la ganancia de progreso dentro de la zona verde
      else
        @progress -= 0.01 # Aumentar la penalización cuando fuera de la zona verde
      end
    end
  
    def update_progress_bar
      @progress = [[@progress, 0.0].max, 1.0].min
      @progress_fill.zoom_x = @progress
    end
  
    def win_minigame
      @success = true
      pbSEPlay("Safari Zone end")
      @success_icon.visible = true
  
      wait_and_exit
    end
  
    def fail_minigame
      @success = false
      pbSEPlay("Anim/Buzzer")
      @fail_icon.visible = true
      wait_and_exit
    end
  
    def wait_and_exit
      pbWait(1) # Reducir el tiempo de espera a 2 frames
      fade_out_before_overworld
    end
  
    def disposed?
      [@background, @bar, @zone_green, @marker, @progress_bar, @progress_fill, @success_icon, @fail_icon].all?(&:disposed?)
    end
  
    def dispose
      return if disposed?
      [@background, @bar, @zone_green, @marker, @progress_bar, @progress_fill, @success_icon, @fail_icon].each do |sprite|
        sprite.dispose unless sprite.disposed?
      end
    end
  
    def run
      loop do
        Graphics.update
        Input.update
        update
        break if disposed? || @success || @timer <= 0
      end
      return @success
    end
  
    # Función para mover la zona verde de forma dinámica sin sobrepasar los límites de la barra gris
    def move_zone_green
      # Inicializa la zona verde en el centro solo una vez
      if @zone_green.y.nil?
        @zone_green.y = @bar.y + @bar.bitmap.height / 2 - @zone_green.bitmap.height / 2
      end
  
      # Movimiento aleatorio hacia arriba o abajo con una dirección aleatoria
      movement_direction = rand(2) == 0 ? -1 : 1  # Aleatorio entre -1 (arriba) y 1 (abajo)
      movement_range = rand(1..2)  # Movimiento aleatorio entre 1 y 2 píxeles
  
      # Calcular la nueva posición Y con movimiento errático
      target_y = @zone_green.y + movement_direction * movement_range
  
      # Limitar el movimiento para que la zona verde no sobrepase los límites de la barra
      # Limite superior
      target_y = [target_y, @bar.y + 12].max
      # Limite inferior
      target_y = [target_y, @bar.y + @bar.bitmap.height - @zone_green.bitmap.height - 12].min
  
      # Establecer la nueva posición directamente, sin interpolación suave
      @zone_green.y = target_y
    end
  
    # Desvanecimiento de entrada
    def fade_in
      (0..15).each do |i|
        @viewport.color = Color.new(0, 0, 0, (15 - i) * 16)
        Graphics.update
      end
      @viewport.color = Color.new(0, 0, 0, 0)
    end
  
    # Desvanecimiento de salida (modificado para una transición rápida a overworld)
    def fade_out_before_overworld
      (0..7).each do |i| # Hacerlo más rápido
        @viewport.color = Color.new(0, 0, 0, i * 32) # No dejar la pantalla completamente negra
        Graphics.update
      end
      @viewport.color = Color.new(0, 0, 0, 0) # Volver completamente transparente
      # Ahora se verifica si el jugador ganó el minijuego
      trigger_exclaim_animation if @success && !@victory_checked
    end
  
    def trigger_exclaim_animation
      # Descartar los objetos del minijuego antes de la animación de exclamación
      dispose
  
      # Crear la animación de exclamación
      spriteset = $scene.spriteset
      spriteset.addUserAnimation(003, $game_player.x, $game_player.y, true)
  
      # Esperar que termine la animación
      pbWait(1) # Ajusta el tiempo de espera según lo necesites
  
      # Iniciar el combate solo si no ha iniciado previamente y si el jugador ha ganado
      if !$game_temp.in_battle && @success && !@combat_triggered
        @combat_triggered = true
        trigger_wild_battle
      end
  
      # Aquí se obtiene el objeto con un 20% de probabilidad
      if @success && rand(100) < 20
        give_random_item
      end
  
      # Reiniciar la comprobación de victoria para que no se ejecute de nuevo
      @victory_checked = true
    end
  
    # Iniciar combate con Pokémon salvajes
    def trigger_wild_battle
      pbEncounter(:SuperRod)
    end
  
    def give_random_item
      # Lista de objetos y probabilidades
      items = [
        [:BIGPEARL, 15],    # Big Pearl
        [:HEARTSCALE, 20],  # Heart Scale
        [:PEARL, 30],       # Pearl
        [:PEARLSTRING, 15], # Pearl String
        [:PRISMSCALE, 5],   # Prism Scale (5% de probabilidad)
        [:STICKYBARB, 20]   # Sticky Barb
      ]
  
      # Determinar el objeto basado en la probabilidad
      total_probability = items.sum { |item| item[1] }
      roll = rand(total_probability)
  
      cumulative_probability = 0
      selected_item = nil
      items.each do |item, probability|
        cumulative_probability += probability
        if roll < cumulative_probability
          selected_item = item
          break
        end
      end
  
      # Dar el objeto al jugador
      pbItemBall(selected_item)
    end
  end
  
  # Llamada al minijuego (fuera de la clase)
  def pbPescaMinigame
    viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    viewport.z = 99999
    minigame = PescaMinigame.new(viewport)
    success = minigame.run
    viewport.dispose
    return success
  end
  