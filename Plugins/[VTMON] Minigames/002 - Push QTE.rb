class QTEButton
  def initialize(correct_button, time_limit)
    @correct_button = mapped_input(correct_button)
    @time_limit = time_limit
    @start_time = System.uptime
    @success = false
    @fade_out = false
    @show_success_image = false
    @fail_time = false
    @incorrect_pressed = false

    # Fondo negro semitransparente
    @background = Sprite.new
    @background.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @background.bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0, 128))
    @background.opacity = 0  # Inicialmente invisible

    # Configuración de otros elementos (botón y barra de tiempo)
    @sprites = setup_sprites(correct_button)

    # Temporizador de alternancia de imágenes
    @image_swap_timer = 0  # Este temporizador controlará la alternancia entre las imágenes
  end

  def update
    elapsed_time = System.uptime - @start_time
    update_sprites(elapsed_time)

    # Aparecer gradualmente el fondo más rápido
    if elapsed_time < 0.5
      @background.opacity += 20
      @sprites[:button].opacity += 12
      @sprites[:timer].opacity += 12
    end

    # Alternar imágenes de los botones
    @image_swap_timer += 1
    if @image_swap_timer >= 20  # Cambiar cada 20 actualizaciones
      swap_button_image
      @image_swap_timer = 0  # Reiniciar temporizador
    end

    if @fade_out
      handle_fade_out
      return false
    end

    # Si el tiempo se agota y no hay éxito, se marca el fallo
    if elapsed_time >= @time_limit && !@success
      @fail_time = true
      show_wrong_image
      initiate_fade_out
      $game_variables[27] = 0  # Fail
      puts "Tiempo agotado. Fallo!"  # Mostrar mensaje de consola
      return true
    end

    # Si el jugador presiona el botón correcto
    if Input.trigger?(@correct_button)
      @success = true
      show_success_image
      initiate_fade_out
      $game_variables[27] = 1  # Success
      puts "¡Botón correcto presionado!"
      return true
    end

    # Si el jugador presiona un botón incorrecto
    if !@incorrect_pressed && incorrect_button_pressed? && !@success
      @incorrect_pressed = true
      show_wrong_image
      initiate_fade_out
      $game_variables[27] = 0  # Fail
      puts "Botón incorrecto presionado!"
      return true
    end

    false
  end

  def incorrect_button_pressed?
    # Verifica si se presionó un botón incorrecto
    incorrect_buttons = [Input::ACTION, Input::USE, Input::SPECIAL] - [@correct_button]
    incorrect_buttons.any? { |btn| Input.trigger?(btn) } && !@success && !@fail_time
  end

  def success?
    @success
  end

  def exited?
    @fail_time || @success
  end

  def mapped_input(button)
    case button
    when :action then Input::ACTION
    when :use then Input::USE
    when :special then Input::SPECIAL
    else
      raise "Tipo de input no válido"
    end
  end

  def setup_sprites(button)
    sprites = {}
    sprite_name = case button
                  when :action then "action"
                  when :use then "use"
                  when :special then "special"
                  else "default"
                  end
    sprites[:button] = Sprite.new
    sprites[:button].bitmap = load_graphic("Quick Botton/#{sprite_name}")
    sprites[:button].x = 80
    sprites[:button].y = 120

    # Barra de tiempo más delgada (altura ajustada a 10 píxeles)
    sprites[:timer] = Sprite.new
    sprites[:timer].bitmap = Bitmap.new(200, 10)  # Aquí cambiamos 20 a 10 para hacerla más delgada
    sprites[:timer].x = 30
    sprites[:timer].y = 180
    sprites
  end

  def load_graphic(path)
    full_path = "Graphics/UI/#{path}.png"
    if File.exist?(full_path)
      return RPG::Cache.ui(path)
    else
      return Bitmap.new(100, 100)
    end
  end

  def update_sprites(elapsed_time)
    remaining_time = @time_limit - elapsed_time
    width = [(remaining_time / @time_limit) * 200, 0].max.to_i
    @sprites[:timer].bitmap.clear
    @sprites[:timer].bitmap.fill_rect(0, 0, width, 20, Color.new(255, 255, 255))  # Cambiar el color a blanco

    if @show_success_image
      @fade_out = true
      @show_success_image = false
    end

    if @fade_out
      fade_out_button
      @sprites[:timer].opacity = 0  # Hacer que la barra de tiempo desaparezca
    end
  end

  def swap_button_image
    sprite_name = case @correct_button
                  when Input::ACTION then "action"
                  when Input::USE then "use"
                  when Input::SPECIAL then "special"
                  else "default"
                  end
    if @sprites[:button].bitmap == load_graphic("Quick Botton/#{sprite_name}")
      @sprites[:button].bitmap = load_graphic("Quick Botton/push_#{sprite_name}")
    else
      @sprites[:button].bitmap = load_graphic("Quick Botton/#{sprite_name}")
    end
  end

  def show_success_image
    sprite_name = case @correct_button
                  when Input::ACTION then "ch_action"
                  when Input::USE then "ch_use"
                  when Input::SPECIAL then "ch_special"
                  else "ch_default"
                  end
    @sprites[:button].bitmap = load_graphic("Quick Botton/#{sprite_name}")
    Audio.se_play('Audio/SE/Mining reveal', 80, 100)
    fade_out_button
  end

  def show_wrong_image
    sprite_name = case @correct_button
                  when Input::ACTION then "wrong_action"
                  when Input::USE then "wrong_use"
                  when Input::SPECIAL then "wrong_special"
                  else "wrong_default"
                  end
    @sprites[:button].bitmap = load_graphic("Quick Botton/#{sprite_name}")
    Audio.se_play('Audio/SE/Anim/buzzer', 80, 100)
    fade_out_button
  end

  def fade_out_button
    return if @sprites[:button].disposed?  # Prevenir errores si el sprite ya ha sido eliminado

    iterations = 20
    iterations.times do
      @sprites[:button].opacity -= 12
      @sprites[:timer].opacity -= 12  # Desvanecer la barra de tiempo
      @background.opacity -= 12  # Desvanecer el fondo negro
      Graphics.update
    end

    # Eliminar los sprites una vez que se ha completado el desvanecimiento
    @sprites[:button].dispose unless @sprites[:button].disposed?
    @sprites[:timer].dispose unless @sprites[:timer].disposed?  # Eliminar barra de tiempo
    @background.dispose unless @background.disposed?  # Eliminar fondo negro
  end

  def dispose_sprites
    @sprites.each_value(&:dispose)
  end
end

def initiate_fade_out
  @fade_out = true
  # Aquí puedes llamar al método para desvanecer los elementos
  fade_out_button
end

module QTECommands
  def self.pbStartPushQTE(correct_button, time_limit)
    qte = QTEButton.new(correct_button, time_limit)
    loop do
      Graphics.update
      Input.update
      break if qte.update
    end
    return :exit if qte.exited?
    qte.success?
  end
end
