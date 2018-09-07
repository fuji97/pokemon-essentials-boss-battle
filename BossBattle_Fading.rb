################################################################################
# BOSS BATTLE FADING
# For Pokèmon Essentials v17.2
# ######
# Version: 0.1 (1)
# Date: 07/09/2018
# Developer: Fuji97 (https://github.com/fuji97)
# All rights reserved.
################################################################################

################################# REQUIREMENTS #################################
# EAM_Classes
# # EAM_Sprite
# # # EAM_Core
# Fuji's Utilities
# Advanced Log
################################################################################

################################### SETTINGS ###################################
#
# 
FLASH_DURATION = 6
FLASH_WAIT_DURATION = 8
AUDIO_EFFECTS_PATH = "Audio/SE/BossBattle Fading"
BARS_PATH = "Graphics/Pictures/BossBattle Fading"

STARTING_ANIMATION_DURATION = 100
STARTING_ANIMATION_FADE_DURATION = 40
STARTING_ANIMATION_ZOOM_DURATION = 60
WHITE_SCREEN_FADE_DURATION = 20
STARTING_ANIMATION_SPEED = Graphics.width * 6

LINE_HEIGHT = 7
LINE_OVERLAP = 2
#
################################################################################

module BossBattle_Fading
	@@counter = 0
	@@flash = nil
	@@callback = nil
	
	def self.triggerHit(arg, arg2)
		@@counter = @@counter + 1
		if @@counter >= FLASH_DURATION
			@@flash.opacity = 0
			@@flash.update
			@@flash.dispose
			@@counter = 0
			Graphics.afterUpdate -= self.method(:triggerHit)
			
			# Call callback
			if @@callback != nil
				Log.d("BOSS_FADE", "Calling callback #{@@callback.inspect}")
				@@calback.call(self)
			end
		end
	end
	
	def self.triggerDoubleHit(arg, arg2)
		@@counter = @@counter + 1
		
		# Third phase
		if @@counter >= FLASH_DURATION * 2 + FLASH_WAIT_DURATION
			@@flash.opacity = 0
			@@flash.update
			@@flash.dispose
			@@counter = 0
			Graphics.afterUpdate -= self.method(:triggerDoubleHit)
			
			# Call callback
			if @@callback != nil
				Log.d("BOSS_FADE", "Calling callback #{@@callback.inspect}")
				@@calback.call(self)
			end
			
		# Second phase
		elsif @@counter >= FLASH_DURATION + FLASH_WAIT_DURATION
			@@flash.opacity = 255
			@@flash.update
			
		# First Phase
		elsif @@counter >= FLASH_DURATION
			@@flash.opacity = 0
			@@flash.update
		end
	end
	
	def self.hit(async=false, callback=nil)
		@@flash = Sprite.new
		@@flash.opacity = 0
		@@flash.z = 9999999
		@@flash.bitmap = Bitmap.new(Graphics.width, Graphics.height)
		@@flash.bitmap.fill_rect(0,0,Graphics.width, Graphics.height, Color.new(255,255,255))
		
		Audio.se_play("#{AUDIO_EFFECTS_PATH}/hit.ogg")
		@@flash.opacity = 255
		@@flash.update
		if async
			if @@counter != 0
				raise "[BossBattle_Fading] Can't launch another hit when the previous is still executing."
			end
			
			@@callback = callback
			Graphics.afterUpdate += self.method(:triggerHit)
		else
			FLASH_DURATION.times do
				Graphics.update
				Input.update
			end
			
			@@flash.opacity = 0
			@@flash.update
			Graphics.update
			Input.update
			@@flash.dispose
		end
	end
	
	def self.doubleHit(async=false, callback=nil)
		@@flash = Sprite.new
		@@flash.opacity = 0
		@@flash.z = 9999999
		@@flash.bitmap = Bitmap.new(Graphics.width, Graphics.height)
		@@flash.bitmap.fill_rect(0,0,Graphics.width, Graphics.height, Color.new(255,255,255))
		
		Audio.se_play("#{AUDIO_EFFECTS_PATH}/double_hit.ogg")
		@@flash.opacity = 255
		@@flash.update
		if async
			if @@counter != 0
				raise "[BossBattle_Fading] Can't launch another hit when the previous is still executing."
			end
			
			@@callback = callback
			Graphics.afterUpdate += self.method(:triggerDoubleHit)
		else
			FLASH_DURATION.times do
				Graphics.update
				Input.update
			end
			
			@@flash.opacity = 0
			@@flash.update
			
			FLASH_WAIT_DURATION.times do
				Graphics.update
				Input.update
			end
			
			@@flash.opacity = 255
			@@flash.update
			
			FLASH_DURATION.times do
				Graphics.update
				Input.update
			end
			@@flash.opacity = 0
			@@flash.update
			Graphics.update
			Input.update
			@@flash.dispose
		end
	end
	
	def self.startBattle(async=false, callback=nil)
		bars = [ Bitmap.new("#{BARS_PATH}/maxi.png"),
			Bitmap.new("#{BARS_PATH}/maxi-med.png"),
			Bitmap.new("#{BARS_PATH}/med.png"),
			Bitmap.new("#{BARS_PATH}/med-mini.png"),
			Bitmap.new("#{BARS_PATH}/mini.png") ]
		
		viewport = newFullViewport(99999999)
		lines = Graphics.height / (LINE_HEIGHT - LINE_OVERLAP)
		#rows = (lines / 3.0).ceil
		index = 0
		sprites = []
		lines.times do
			width = 0
			bitmap = Bitmap.new(STARTING_ANIMATION_SPEED, LINE_HEIGHT)
			while width < STARTING_ANIMATION_SPEED
				# Randomize padding
				width += rand(200) + 30
				# Choose a random bar and add to the bitmap
				choice = bars[rand(4)]
				bitmap.blt(width, 0, choice, choice.rect)
				width += choice.width
			end
			sprites[index] = EAMSprite.new(viewport)
			sprites[index].bitmap = bitmap
			if index % 2 == 1
				sprites[index].ox = sprites[index].bitmap.width
				sprites[index].x = Graphics.width
			else
				sprites[index].ox = 0
			end
			
			sprites[index].y = (index * (LINE_HEIGHT - LINE_OVERLAP)) + LINE_HEIGHT / 2
			sprites[index].oy = LINE_HEIGHT / 2
			sprites[index].zoom_x = 0.5
			sprites[index].zoom_y = 0.2
			sprites[index].opacity = 0
			index += 1
		end
		
		whiteScreen = EAMSprite.new(viewport)
		whiteScreen.bitmap = Bitmap.new(Graphics.width, Graphics.height)
		whiteScreen.bitmap.fill_rect(0,0,Graphics.width, Graphics.height, Color.new(255,255,255))
		whiteScreen.opacity = 0
		
		#composition = EAMSprite_Composition.new(sprites, viewport=viewport)
		
		#Start Animation
		Audio.se_play("#{AUDIO_EFFECTS_PATH}/start_battle.ogg")
		index = 0
		sprites.length.times do
			sprite = sprites[index]
			if index % 2 == 0
				sprite.move(-STARTING_ANIMATION_SPEED + Graphics.width, sprite.y, 
					STARTING_ANIMATION_DURATION)
			else
				sprite.move(STARTING_ANIMATION_SPEED, sprite.y, 
					STARTING_ANIMATION_DURATION)
			end
			sprite.fade(255, STARTING_ANIMATION_FADE_DURATION)
			sprite.zoom(1.0, 1.0, STARTING_ANIMATION_ZOOM_DURATION, :ease_out_quad)
			index += 1
		end
		
		whiteScreen.fade(255, WHITE_SCREEN_FADE_DURATION)
		
		#composition.fade(255, STARTING_ANIMATION_DURATION, :ease_in_quad)
		#composition.zoom(1.0, 1.0, STARTING_ANIMATION_DURATION, :ease_in_quad)
		
		# Start loop
		framesTimer = STARTING_ANIMATION_DURATION - WHITE_SCREEN_FADE_DURATION
		while sprites[0].isAnimating?
			Graphics.update
			Input.update
			sprites.each {|sprite| sprite.update}
			Log.v("BOSS_FADE", "Updating - x: #{sprites[0].x}/#{sprites[1].x} zoom: #{sprites[0].zoom_x} - opacity: #{sprites[0].opacity}")
			
			# Delay the white screen animation
			if framesTimer > 0
				framesTimer -= 1
			else
				whiteScreen.update
			end
		end
		
		
		sprites.each {|sprite| sprite.opacity = 0; sprite.dispose}
		
		yield
		
		whiteScreen.opacity = 0
		whiteScreen.dispose
	end
	
end
