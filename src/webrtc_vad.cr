require "./webrtc_audio"
require "./models/*"
require "./signal_processing/*"
require "./vad/*"

module WebrtcAudio
  class WebRtcVad
    ValidRates      = [8, 16, 32, 48]
    ValidFrameTimes = [10, 20, 30]
    enum Aggressiveness
      Quality     = 0
      LowBitrate  = 1
      Aggressive  = 2
      VeryAggress = 3
    end

    def initialize
      @instance = WebrtcAudio::VadInstance.new
      @idx = 0
    end
	
	def reset_state
		old_mode = @instance.sample_mode
		WebrtcAudio::Vad.init_core(@instance)
		WebrtcAudio::Vad.set_mode_core(@instance, old_mode)
		@idx = old_mode
	end
	
    def reset
      WebrtcAudio::Vad.init_core(@instance)
      @idx = 0
    end

    def set_mode(nm : Aggressiveness) : Bool
      return WebrtcAudio::Vad.set_mode_core(@instance, nm.to_i) >= 0
    end

    def set_mode(nm : Int32) : Bool
      return WebrtcAudio::Vad.set_mode_core(@instance, nm) >= 0
    end

    def set_sample_rate(rate : Int32) : Bool
      (0...ValidRates.size).each { |i|
        if ValidRates[i] * 1000 == rate
          @idx = i
          return true
        end
      }
      return false
    end

    def valid_length(length : Int32) : Bool
      samples_per_ms = ValidRates[@idx]
      (0...ValidFrameTimes.size).each { |i|
        if ((ValidFrameTimes[i] &* samples_per_ms) == length)
          return true
        end
      }
      return false
    end

    def process(input : Slice(Int16), length : Int32) : Bool
      if !valid_length(length)
        return false
      end
      case @idx
      when 0
        return WebrtcAudio::Vad.calc_vad_8khz(@instance, input, length) >= 0
      when 1
        return WebrtcAudio::Vad.calc_vad_16khz(@instance, input, length) >= 0
      when 2
        return WebrtcAudio::Vad.calc_vad_32khz(@instance, input, length) >= 0
      when 3
        return WebrtcAudio::Vad.calc_vad_48khz(@instance, input, length) >= 0
      end
      return false
    end
  end
end
