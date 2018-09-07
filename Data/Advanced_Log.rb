################################################################################
# ADVANCED LOG - Console Debug expander
# For Pokèmon Essentials v17.2
# ######
# Version: 1.0 (1)
# Date: 03/09/2018
# Original creation date: 30/01/2017
# Developer: Fuji97 (https://github.com/fuji97)
# Original code from Pokémon Cremisi Portals by Hoseki Team
# All right reserved.
################################################################################

################################# REQUIREMENTS #################################
# 
################################################################################

################################### SETTINGS ###################################
# => Set logging filter
# -1 => Absolutly nothing
# 0 => What a Terrible Failure (WTF)
# 1 => WTF, Error
# 2 => WTF, Error, Warning
# 3 => WTF, Error, Warning, Info
# 4 => WTF, Error, Warning, Debug
# 5 => ALL (WTF, Error, Warnign, Debug, Verbose)
LOG_LEVEL = 0
#
# Start the console when the game starts
AUTOSTART_CONSOLE = false
################################################################################

################################################################################
# => Do not touch from here
################################################################################

$isConsoleSetted = false

if AUTOSTART_CONSOLE
	Console::setup_console
	$isConsoleSetted = true
end

class Log
	class << self
		def writeConsole(level,type,tag,text)

			if LOG_LEVEL > level && $DEBUG
				if !$isConsoleSetted
					Console::setup_console
					$isConsoleSetted = true
				end
				echoln("#{type}: [#{tag}] #{text}")
			end
		end

		def wtf(tag,text)
			writeConsole(-1,"WTF",tag,text)
		end

		def e(tag,text)
			writeConsole(0,"Err",tag,text)
		end

		def w(tag,text)
			writeConsole(1,"Wrn",tag,text)
		end

		def i(tag,text)
			writeConsole(2,"Inf",tag,text)
		end

		def d(tag,text)
			writeConsole(3,"Dbg",tag,text)
		end

		def v(tag,text)
			writeConsole(4,"Vrb",tag,text)
		end
	end
end

