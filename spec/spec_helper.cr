require "spec"
require "../src/webrtc_audio"
require "../src/webrtc_vad"
require "../src/models/*"
require "../src/signal_processing/*"
require "../src/vad/*"

KModes     = [0, 1, 2, 3]
KModesSize = 4
# Rates we support.
KRates     = [8000, 12000, 16000, 24000, 32000, 48000]
KRatesSize = 6

# Frame lengths we support.
KMaxFrameLength   = 1440
KFrameLengths     = [80, 120, 160, 240, 320, 480, 640, 960, 1440]
KFrameLengthsSize = 9

# Returns true if the rate and frame length combination is valid.
def validRatesAndFrameLengths(rate : Int32, frame_length : Int32) : Bool
  if (rate == 8000)
    if (frame_length == 80 || frame_length == 160 || frame_length == 240)
      return true
    end
    return false
  elsif (rate == 16000)
    if (frame_length == 160 || frame_length == 320 || frame_length == 480)
      return true
    end
    return false
  elsif (rate == 32000)
    if (frame_length == 320 || frame_length == 640 || frame_length == 960)
      return true
    end
    return false
  elsif (rate == 48000)
    if (frame_length == 480 || frame_length == 960 || frame_length == 1440)
      return true
    end
    return false
  end
  return false
end
