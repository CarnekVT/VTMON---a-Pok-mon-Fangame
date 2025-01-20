module CustomBattleScene
    class Scene < Battle::Scene
      alias_method :old_initialize, :initialize
  
      def initialize
        old_initialize
        @trainer_sprites = [] # Almacena los sprites animados de los entrenadores
      end
  
      unless method_defined?(:pbShowTrainer)
        def pbShowTrainer(idxTrainer)
          # Comportamiento por defecto si no está definido
        end
      end
  
      alias_method :old_pbShowTrainer, :pbShowTrainer
  
      def pbShowTrainer(idxTrainer)
        old_pbShowTrainer(idxTrainer)
        trainer = @battle.pbGetOwner(idxTrainer)
        tr_type = trainer.trainer_type
        sprite_path = GameData::TrainerType.front_sprite_filename(tr_type)
  
        if sprite_path && pbResolveBitmap(sprite_path)
          sprite = AnimatedTrainerSprite.new(@viewport)
          sprite.load_bitmap(sprite_path, trainer)
          sprite.x = Graphics.width - 200
          sprite.y = Graphics.height / 2 - 50
          sprite.z = 50
          sprite.visible = true
          @sprites["trainer_#{idxTrainer}"] = sprite
        else
          pbSEPlay("Error") # Sonido de error si no se encuentra el recurso
        end
      end
  
      class AnimatedTrainerSprite < RPG::Sprite
        attr_accessor :speed, :reversed
  
        def initialize(viewport)
          super(viewport)
          @bitmap = nil
          @frame = 0
          @frame_width = 0
          @frame_height = 0
          @frame_rate = 4 # Velocidad de animación predeterminada
          @speed = 1
          @reversed = false
          self.zoom_x = 2.0 # Escalado del sprite
          self.zoom_y = 2.0
        end
  
        def load_bitmap(file, trainer = nil)
          @bitmap = DeluxeBitmapWrapper.new(file)
          self.bitmap = @bitmap.bitmap
          @frame_width = @bitmap.width / @bitmap.length
          @frame_height = @bitmap.height
  
          if @bitmap.width % @frame_width != 0 || @bitmap.height != @frame_height
            raise "[ERROR] Sprite sheet dimensions are inconsistent: Width=#{@bitmap.width}, Height=#{@bitmap.height}, FrameWidth=#{@frame_width}, FrameHeight=#{@frame_height}"
          end
  
          self.src_rect.set(0, 0, @frame_width, @frame_height)
          apply_metrics(trainer) if trainer
          PBDebug.log("[DEBUG] Sprite loaded: Width=#{@frame_width}, Height=#{@frame_height}, Frames=#{@bitmap.length}")
        end
  
        def apply_metrics(trainer)
          metrics = GameData::SpeciesMetrics.get_species_form(trainer.species, trainer.form, trainer.gender == 1)
          @speed = metrics.front_sprite_speed || 2
          self.zoom_x = metrics.front_sprite_scale || 2.0
          self.zoom_y = metrics.front_sprite_scale || 2.0
          PBDebug.log("[DEBUG] Metrics applied: Speed=#{@speed}, Zoom=#{self.zoom_x}")
        end
  
        def update
          super
          return unless @bitmap && @bitmap.length > 1
  
          @frame += @speed
          if @frame >= @bitmap.length * @frame_rate
            @frame = 0
          end
  
          frame_index = (@frame / @frame_rate).floor
          frame_index = @bitmap.length - 1 - frame_index if @reversed
  
          self.src_rect.set(frame_index * @frame_width, 0, @frame_width, @frame_height)
          self.zoom_x = 2.0
          self.zoom_y = 2.0
  
          # Visualización en pantalla para depuración
          draw_debug_info(frame_index)
        end
  
        def draw_debug_info(frame_index)
          debug_overlay = RPG::Sprite.new(@viewport)
          debug_overlay.bitmap = Bitmap.new(300, 100)
          debug_overlay.bitmap.font.color = Color.new(255, 0, 0)
          debug_overlay.x = 10
          debug_overlay.y = 10
          debug_overlay.z = 999
          debug_overlay.bitmap.clear
          debug_overlay.bitmap.draw_text(0, 0, 300, 20, "Frame Index: #{frame_index}")
          debug_overlay.bitmap.draw_text(0, 20, 300, 20, "SrcRect: #{self.src_rect.inspect}")
          debug_overlay.bitmap.draw_text(0, 40, 300, 20, "Bitmap Size: #{self.bitmap.width}x#{self.bitmap.height}")
        end
  
        def dispose
          @bitmap.dispose if @bitmap
          super
        end
      end
    end
  end
  
  # Clase DeluxeBitmapWrapper para manejar hojas de sprites
  class DeluxeBitmapWrapper
    attr_reader :width, :height, :length
    attr_accessor :bitmap
  
    def initialize(file)
      raise "DeluxeBitmapWrapper filename is nil." if file.nil?
  
      @bitmap = Bitmap.new(file)
      if @bitmap.width > @bitmap.height
        @length = @bitmap.width / @bitmap.height
        @width = @bitmap.width / @length
        @height = @bitmap.height
      else
        @length = 1
        @width = @bitmap.width
        @height = @bitmap.height
      end
      PBDebug.log("[DEBUG] DeluxeBitmapWrapper initialized: Width=#{@width}, Height=#{@height}, Frames=#{@length}")
    end
  
    def dispose
      @bitmap.dispose if @bitmap
    end
  
    def update; end # No se requiere lógica adicional para esta clase
  end
  