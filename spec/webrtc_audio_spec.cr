require "./spec_helper"

describe WebrtcAudio do
  # TODO: Write tests

  it "test teh api" do
    # This API test runs through the APIs for all possible valid and invalid
    # combinations.
    api = WebrtcAudio::WebRtcVad.new
    zeros = Array(Int16).new(KMaxFrameLength, 0)
    zeros_slice = Slice(Int16).new(zeros.to_unsafe, KMaxFrameLength)
    speech = Array(Int16).new(KMaxFrameLength, 0)
    speech_slice = Slice(Int16).new(speech.to_unsafe, KMaxFrameLength)

    # Construct a speech signal that will trigger the VAD in all modes. It is
    # known that (i * i) will wrap around, but that doesn't matter in this case.
    (0...KMaxFrameLength).each { |i|
      tmp = i &* i
      # convert i to u16, then back to i 16
      speech[i] = tmp.to_i16!
    }
    # fvad_set_mode() invalid modes tests. Tries smallest supported value
    # minus one and largest supported value plus one.
    api.set_mode(-1).should eq(false)
    api.set_mode(4).should eq(false)

    # Invalid sampling rate
    api.set_sample_rate(9999).should eq(false)

    # fvad_process() tests
    # All zeros as input should work
    api.set_sample_rate(KRates[0]).should eq(true)
    api.process(zeros_slice, KFrameLengths[0]).should eq(true)

    (0...KModesSize).each { |k|
      # Test valid modes
      api.set_mode(KModes[k]).should eq(true)
      # Loop through sampling rate and frame length combinations
      (0...KRatesSize).each { |i|
        (0...KFrameLengthsSize).each { |j|
          if (validRatesAndFrameLengths(KRates[i], KFrameLengths[j]))
            api.set_sample_rate(KRates[i]).should eq(true)
            api.process(speech_slice, KFrameLengths[j]).should eq(true)
          elsif (validRatesAndFrameLengths(KRates[i], (KRates[i] / 100).round.to_i32))
            api.set_sample_rate(KRates[i]).should eq(true)
            api.process(speech_slice, KFrameLengths[j]).should eq(false)
          else
            api.set_sample_rate(KRates[i]).should eq(false)
          end
        }
      }
    }
  end
end
