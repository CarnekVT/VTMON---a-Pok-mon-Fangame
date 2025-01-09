class QTEButton
  def initialize(correct_button, time_limit, mash_count)
    @correct_button = mapped_input(correct_button)
    @time_limit = time_limit
    @mash_count = mash_count  # Usamos mash_count para el número de presiones
    @start_time = System.uptime
    @success = false
    @fade_out = false
    @show_success_image = false
    @sprites = setup_sprites(correct_button)
    @fail_time = false
    @incorrect_pressed = false
  end

  def update
    elapsed_time = System.uptime - @start_time
    update_sprites(elapsed_time)

    # Si el tiempo se agota y no hay éxito, se marca el fallo
    if elapsed_time >= @time_limit && !@success
      @fail_time = true
      show_wrong_image
      dispose_sprites
      @fade_out = true
      $game_variables[27] = 0  # Fail
      puts "Tiempo agotado. Fallo!"  # Mostrar mensaje de consola
      return true
    end

    # Si el jugador presiona el botón correcto
    if Input.trigger?(@correct_button) && !@success
      @mash_count -= 1  # Reducir el número de presiones restantes
      show_success_image

      if @mash_count <= 0
        @success = true  # Cuando ya no quedan más presiones, se marca como éxito
        finish_mash
      end

      dispose_sprites
      @fade_out = true
      $game_variables[27] = 1  # Success
      puts "¡Botón correcto presionado!"  # Mostrar mensaje de consola
      return true
    end

    # Si el jugador presiona un botón incorrecto
    if !@incorrect_pressed && incorrect_button_pressed? && !@success
      @incorrect_pressed = true
      show_wrong_image
      dispose_sprites
      @fade_out = true
      $game_variables[27] = 0  # Fail
      puts "Botón incorrecto presionado!"  # Mostrar mensaje de consola
      return true
    end

    false
  end

  def finish_mash
    # Al terminar el mash, este método asegura que el botón deje de ser presionado
    puts "Mash completo. ¡Éxito!"
    @fade_out = true
    dispose_sprites
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
    sprites[:timer] = Sprite.new
    sprites[:timer].bitmap = Bitmap.new(200, 20)
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
    @sprites[:timer].bitmap.fill_rect(0, 0, width, 20, Color.new(255, 0, 0))

    if @show_success_image
      @fade_out = true
      @show_success_image = false
    end

    if @fade_out
      fade_out_button
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
    iterations = 20
    iterations.times do
      @sprites[:button].opacity -= 12
      Graphics.update
    end
    @sprites[:button].dispose
  end

  def dispose_sprites
    @sprites.each_value(&:dispose)
  end
end

module QTECommands
  def self.pbStartPushQTE(correct_button, time_limit, mash_count)
    qte = QTEButton.new(correct_button, time_limit, mash_count)
    loop do
      Graphics.update
      Input.update
      break if qte.update
    end
    return :exit if qte.exited?
    qte.success?
  end
end