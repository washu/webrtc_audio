module WebrtcAudio
  class State48khzTo8khz
    property s_48_24 : Array(Int32) = Array(Int32).new(8, 0)
    property s_24_24 : Array(Int32) = Array(Int32).new(16, 0)
    property s_24_16 : Array(Int32) = Array(Int32).new(8, 0)
    property s_16_8 : Array(Int32) = Array(Int32).new(8, 0)
  end

  class VadInstance
    property vad : Int16 = 0
    property downsampling_filter_states : Array(Int32) = Array(Int32).new(4, 0)
    property state_48_to_8 : State48khzTo8khz = State48khzTo8khz.new
    property noise_means : Array(Int16) = Array(Int16).new(WebrtcAudio.kTableSize, 0)
    property speech_means : Array(Int16) = Array(Int16).new(WebrtcAudio.kTableSize, 0)
    property noise_stds : Array(Int16) = Array(Int16).new(WebrtcAudio.kTableSize, 0)
    property speech_stds : Array(Int16) = Array(Int16).new(WebrtcAudio.kTableSize, 0)
    property frame_count : Int32 = 0
    # Overhang
    property over_hang : Int16 = 0
    property num_of_speech : Int16 = 0
    property age_vector : Array(Int16) = Array(Int16).new(16 * WebrtcAudio.kNumChannels, 0)
    property low_value_vector : Array(Int16) = Array(Int16).new(16 * WebrtcAudio.kNumChannels, 0)
    property median : Array(Int16) = Array(Int16).new(WebrtcAudio.kNumChannels, 0)
    property upper_state : Array(Int16) = Array(Int16).new(5, 0)
    property lower_state : Array(Int16) = Array(Int16).new(5, 0)
    property hp_filter_state : Array(Int16) = Array(Int16).new(4, 0)
    property over_hang_max_1 : Array(Int16) = Array(Int16).new(3, 0)
    property over_hang_max_2 : Array(Int16) = Array(Int16).new(3, 0)
    property individual : Array(Int16) = Array(Int16).new(3, 0)
    property total : Array(Int16) = Array(Int16).new(3, 0)
    property init_flag : Int32 = -1_i32
	property sample_mode : Int32 = 0_i32
  end
end
