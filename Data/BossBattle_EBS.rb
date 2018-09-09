################################################################################
# BOSS BATTLE
# Versione per EBS
# For Pokèmon Essentials v17.2
# ######
# Version: 0.4 (4)
# Date: 07/09/2018
# Developer: Fuji97 (https://github.com/fuji97)
# Based on original code from Pokémon Xenoverse by WEEDle Team
# All rights reserved.
################################################################################

################################# REQUIREMENTS #################################
# Advanced Log
# BossBattle_Core
################################################################################

################################### SETTINGS ###################################
#
# Path to graphics resources
BOSS_EBS_PATH = "Graphics/Pictures/EBS BossBattle/"
#
################################################################################

class NextGenDataBox  <  SpriteWrapper
	alias :initializeBb :initialize
	def initialize(battler,doublebattle,viewport=nil,player=nil,scene=nil,boss=true,bossMul=4)
		initializeBb(battler,doublebattle,viewport,player,scene)
		@boss = @battler.boss
		@bossMultiplier = @battler.hpMultiplier
		@bossPath = BOSS_EBS_PATH
	end
	
	def setUp
    # reset of the set-up procedure
    @loaded = false
    @showing = false
    @second = false
    pbDisposeSpriteHash(@sprites)
    @sprites.clear
    # initializes all the necessary components
		@sprites["bg"] = Sprite.new(@viewport)
		if @battler.boss && !@battler.bossBg.nil?
			@sprites["bg"].bitmap = pbBitmap(@bossPath+"bgs/"+@battler.bossBg)
		end
		
    @sprites["mega"] = Sprite.new(@viewport)
    @sprites["mega"].opacity = 0
    
    @sprites["gender"] = Sprite.new(@viewport)
    
    @sprites["layer1"] = Sprite.new(@viewport)
    @sprites["layer1"].bitmap = pbBitmap(@path+"layer1")
    @sprites["layer1"].src_rect.height = 64 if !@showexp
    @sprites["layer1"].mirror = !@playerpoke
    
    @sprites["shadow"] = Sprite.new(@viewport)
    @sprites["shadow"].bitmap = Bitmap.new(@sprites["layer1"].bitmap.width,@sprites["layer1"].bitmap.height)
    @sprites["shadow"].z = -1
    @sprites["shadow"].opacity = 255*0.25
    @sprites["shadow"].color = Color.new(0,0,0,255)
		
		@hpBarBmp = pbBitmap(@path+"hpBar")
    
		# Boss
		if @boss
			@hpBars = Array.new
			for i in 0...@bossMultiplier
				@hpBars[i] = pbBitmap(@bossPath+"bossBars/"+i.to_s)
			end
			
			@sprites["hp2"] = Sprite.new(@viewport)
			@sprites["hp2"].bitmap = Bitmap.new(@hpBarBmp.width,@hpBarBmp.height)
			@sprites["hp2"].mirror = !@playerpoke
			@sprites["hp2"].opacity = 100
			
			@sprites["hp_point"] = BossArray.new
			@pointsBitmap = Array.new
			@noPointBitmap = pbBitmap(@bossPath+"points/no")
			for i in 0...@bossMultiplier-1
				@pointsBitmap[i] = pbBitmap(@bossPath+"points/"+i.to_s)
				@sprites["hp_point"][i] = Sprite.new(@viewport)
				@sprites["hp_point"][i].bitmap = Bitmap.new(@noPointBitmap.width,@noPointBitmap.height)
			end
		end
		
		@sprites["hp"] = Sprite.new(@viewport)
		@sprites["hp"].bitmap = Bitmap.new(@hpBarBmp.width,@hpBarBmp.height)
		@sprites["hp"].mirror = !@playerpoke
		
		if @boss
			Log.v("BOSS_DRAW","HP: [#{@sprites["hp"].x},#{@sprites["hp"].y}] - HP2: [#{@sprites["hp2"].x},#{@sprites["hp2"].y}]")
		end
    
    @sprites["exp"] = Sprite.new(@viewport)
    @sprites["exp"].bitmap = pbBitmap(@path+"expBar")
    @sprites["exp"].src_rect.y = @sprites["exp"].bitmap.height*-1 if !@showexp
    
    @sprites["text"] = Sprite.new(@viewport)
    @sprites["text"].bitmap = Bitmap.new(@sprites["layer1"].bitmap.width,@sprites["layer1"].bitmap.height)
    @sprites["text"].z = 9
    pbSetSystemFont(@sprites["text"].bitmap)
    
    #self.opacity = 255
  end
	
	def updateHpBar
		if (@boss)
			# updates the current state of the HP bar
			# the bar's colour hue gets dynamically adjusted (i.e. not through sprites)
			# HP bar is mirrored for opposing Pokemon
			#hpbar = @battler.totalhp==0 ? 0 : (1.0*(self.hp % (@bossMultiplier-1)-1)*@sprites["hp"].bitmap.width/(@battler.totalhp / @bossMultiplier)).ceil
			normalHp = (1.0 * @battler.totalhp / @bossMultiplier)
      currHp = self.hp%normalHp==0 ? self.hp / @bossMultiplier : self.hp%normalHp
			hpbar = @battler.totalhp==0 ? 0 : (1.0*currHp*@sprites["hp"].bitmap.width/normalHp).ceil
			remainingPoints = (self.hp / normalHp).ceil.to_i - 1
			
			# ####
			# Update box backgrounds
			# ####
			
			# ####
			# Update dots
			# ####
			@sprites["hp_point"].each_index do |i|
				@sprites["hp_point"][i].bitmap.clear
				if (remainingPoints > i)
					#echoln("Remain: #{remainingPoints.to_s} - i: #{i.to_s} - #{@pointsBitmap[i].to_s}")
					#echoln("Array: #{@pointsBitmap.inspect}")
					@sprites["hp_point"][i].bitmap.blt(0,0,@pointsBitmap[i],Rect.new(0,0,@noPointBitmap.width,@noPointBitmap.height))
				else
					@sprites["hp_point"][i].bitmap.blt(0,0,@noPointBitmap,Rect.new(0,0,@noPointBitmap.width,@noPointBitmap.height))
				end
			end
			
			# ####
			# Update HP bar
			# ####
			@sprites["hp"].src_rect.x = @sprites["hp"].bitmap.width - hpbar if !@playerpoke
			@sprites["hp"].src_rect.width = hpbar
			#hue = (0-120)*(1-(self.hp.to_f/@battler.totalhp))
			@sprites["hp"].bitmap.clear
			@sprites["hp"].bitmap.blt(0,0,@hpBars[remainingPoints],Rect.new(0,0,@hpBarBmp.width,@hpBarBmp.height))
			# @sprites["hp"].bitmap.hue_change(hue)

			# ####
			# Update background bar
			# ####
			# TODO Remove @hpBarBmp cause it's not used
			if remainingPoints > 0
				@sprites["hp2"].src_rect.x = @sprites["hp"].bitmap.width - @hpBarBmp.width if !@playerpoke
				@sprites["hp2"].src_rect.width = @hpBarBmp.width
				#@sprites["hp2"].bitmap.clear
				@sprites["hp2"].bitmap = @hpBars[remainingPoints-1]
				@sprites["hp2"].visible = true
			else
				@sprites["hp2"].visible = false
			end
		else
			# updates the current state of the HP bar
			# the bar's colour hue gets dynamically adjusted (i.e. not through sprites)
			# HP bar is mirrored for opposing Pokemon
			hpbar = @battler.totalhp==0 ? 0 : (1.0*self.hp*@sprites["hp"].bitmap.width/@battler.totalhp).ceil
			@sprites["hp"].src_rect.x = @sprites["hp"].bitmap.width - hpbar if !@playerpoke
			@sprites["hp"].src_rect.width = hpbar
			hue = (0-120)*(1-(self.hp.to_f/@battler.totalhp))
			@sprites["hp"].bitmap.clear
			@sprites["hp"].bitmap.blt(0,0,@hpBarBmp,Rect.new(0,0,@hpBarBmp.width,@hpBarBmp.height))
			@sprites["hp"].bitmap.hue_change(hue)
		end
		
		# Disabled, too slow
		#~ for i in 0...46
			#~ next if @sprites["chr#{i}"].nil? 
      #~ @sprites["chr#{i}"].zoom_x = (i >= (46*(self.hp.to_f/@battler.totalhp)).floor) ? 0 : 1
      #~ @sprites["chr#{i}"].zoom_x = 0 if !@charged
    #~ end
  end
	
	alias :x_old :x=
	def x=(val)
		return if !@loaded
		x_old(val)
		if @boss
			@sprites["bg"].x = @sprites["layer1"].x
			@sprites["hp2"].x = @sprites["layer1"].x + 28 + (!@playerpoke ? 4 : 0)
			@sprites["hp_point"].each_index do |i|
				@sprites["hp_point"][i].x = @sprites["layer1"].x + 28 + (!@playerpoke ? 4 : 0) + (i * 18)
			end
		end
	end
	
	alias :y_old :y=
	def y=(val)
		return if !@loaded
		y_old(val)
		if @boss
			@sprites["bg"].y = @sprites["layer1"].y
			@sprites["hp2"].y = @sprites["layer1"].y + 46
			@sprites["hp_point"].each_index do |i|
				@sprites["hp_point"][i].y = @sprites["layer1"].y + 64
			end
		end
	end
	
end

class BossArray < Array
	def visible=(val)
		self.each_index do |key|
      next if !self[key]
      self[key].visible = val
    end
	end
	
	def color=(val)
		self.each_index do |key|
      next if !self[key]
      self[key].color = val
    end
	end
  
  def disposed?
    self.each_index do |i|
      self[i].dispose
    end
  end
	
	def opacity=(val)
		self.each_index do |key|
      #@next if key=="mega" && !@battler.isMega?
      next if !self[key]
      self[key].opacity = val
      self[key].opacity *= 0.25 if key=="shadow"
    end
	end
end