#===============================================================================
# Quick Time Event (QTE) - Pokémon Essentials v21
#===============================================================================

class QTE
  def initialize(viewport, x, y, width, height, green_width, speed, success_sound, fail_sound)
    @disposed = false # Control de disposición
    @viewport = viewport
    @x = x
    @y = y
    @width = width
    @height = height
    @green_width = green_width
    @speed = speed
    @pointer_x = 0
    @green_start = rand((@width - @green_width))
    @green_end = @green_start + @green_width
    @direction = 1
    @success_sound = success_sound
    @fail_sound = fail_sound
    create_bar
    create_pointer
  end

  def create_bar
    @bar = Sprite.new(@viewport)
    @bar.bitmap = Bitmap.new(@width, @height)
    @bar.bitmap.fill_rect(0, 0, @width, @height, Color.new(0, 0, 0)) # Black outline
    @bar.bitmap.fill_rect(2, 2, @width - 4, @height - 4, Color.new(255, 255, 255)) # White outline
    @bar.bitmap.fill_rect(4, 4, @width - 8, @height - 8, Color.new(187, 52, 58)) # Red (bb343a)
    @bar.bitmap.fill_rect(4 + @green_start, 4, @green_width, @height - 8, Color.new(71, 213, 99)) # Green (47d563)
    @bar.x = @x
    @bar.y = @y
  end

  def create_pointer
    @pointer = Sprite.new(@viewport)
    @pointer.bitmap = Bitmap.new(6, @height)
    @pointer.bitmap.fill_rect(0, 0, 6, @height, Color.new(255, 255, 255)) # White pointer
    @pointer.x = @x + @pointer_x
    @pointer.y = @y
  end

  def update
    return if @disposed # No actualizar si está eliminado
    move_pointer
    @pointer.x = @x + @pointer_x
  end

  def move_pointer
    return if @disposed # No mover si está eliminado
    @pointer_x += @direction * @speed
    if @pointer_x <= 0 || @pointer_x >= @width - 6
      @direction *= -1
    end
  end

  def check_result
    return :fail if @disposed # Si el objeto está eliminado, forzar fallo
    if @pointer_x >= @green_start + 4 && @pointer_x < @green_end + 4
      pbSEPlay(@success_sound) if @success_sound
      return :success
    else
      pbSEPlay(@fail_sound) if @fail_sound
      return :fail
    end
  end

  def dispose
    return if @disposed # Evitar eliminación doble
    @disposed = true
    @bar.bitmap.dispose if @bar&.bitmap
    @bar.dispose if @bar
    @pointer.bitmap.dispose if @pointer&.bitmap
    @pointer.dispose if @pointer
  end

  def disposed?
    @disposed
  end
end

# Start a single QTE
def pbStartQTE(speed = 4, random_green = true, success_sound = nil, fail_sound = "se_fail")
  viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  viewport.z = 99999
  qte = QTE.new(viewport, (Graphics.width - 300) / 2, (Graphics.height - 20) / 2, 300, 20, random_green ? rand(50..100) : 80, speed, success_sound, fail_sound)
  result = nil
  loop do
    Graphics.update
    Input.update
    qte.update
    if Input.trigger?(Input::C)
      result = qte.check_result
      qte.dispose
      viewport.dispose
      $game_variables[26] = result # Store result in variable 26 for global use
      pbMessage(result == :success ? "Success!" : "Fail!")
      break
    end
  end
  result
end

# Start multiple QTEs
def pbStartMultipleQTEs(configs, require_all = false, success_sound = nil, fail_sound = "se_fail")
  return [] if configs.nil? || configs.empty? # Validar configuraciones vacías

  # Reiniciar la variable 26 antes de iniciar los QTEs
  $game_variables[26] = []  # Reiniciar para almacenar nuevos resultados

  viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  viewport.z = 99999
  qtes = configs.map.with_index do |config, i|
    QTE.new(viewport, (Graphics.width - 300) / 2, 100 + i * 50, 300, 20, config[:random_green] ? rand(50..100) : 80, config[:speed], success_sound, fail_sound)
  end
  results = []

  configs.each_with_index do |config, i|
    loop do
      Graphics.update
      Input.update
      break if qtes[i]&.disposed? # No continuar si está eliminado
      qtes[i]&.update
      if Input.trigger?(Input::C)
        result = qtes[i].check_result
        results << result
        qtes[i].dispose
        break if result == :fail && !require_all
        break if result == :success
      end
    end
  end

  qtes.each { |qte| qte.dispose unless qte.disposed? } # Asegurarse de eliminar todo
  viewport.dispose
  $game_variables[26] = results # Store results in variable 26 for global use
  results
end


# Evaluate QTE results with custom scenarios
def pbEvaluateQTEResults(success_threshold, success_message, fail_message, retry_qte = false, qte_configs = nil, success_sound = nil, fail_sound = "se_fail")
  results = $game_variables[26] || [] # Asegurar que existan resultados
  return pbMessage("No QTE results to evaluate.") if results.empty?

  success_count = results.count(:success)
  success_rate = (success_count.to_f / results.size) * 100

  # Establecer el número de éxitos en la variable global
  $game_variables[26] = success_count  # Almacena el número de éxitos

  if success_rate >= success_threshold
    pbMessage(success_message)
  else
    pbMessage(fail_message)
    if retry_qte && qte_configs
      pbStartMultipleQTEs(qte_configs, false, success_sound, fail_sound)
      pbEvaluateQTEResults(success_threshold, success_message, fail_message, retry_qte, qte_configs, success_sound, fail_sound)
    end
  end
end
