require "./spec_helper"

describe WebrtcAudio::Vad do
  it "Should pass all filter tests" do
    inst = WebrtcAudio::VadInstance.new
    kNumValidFrameLengths = 3
    kReference = [48_i16, 11_i16, 11_i16]
    kFeatures = [
      1213_i16, 759_i16, 587_i16, 462_i16, 434_i16, 272_i16,
      1479_i16, 1385_i16, 1291_i16, 1200_i16, 1103_i16, 1099_i16,
      1732_i16, 1692_i16, 1681_i16, 1629_i16, 1436_i16, 1436_i16,
    ]
    kOffsetVector = [
      368_i16, 368_i16, 272_i16, 176_i16, 176_i16, 176_i16,
    ]
    features = Array(Int16).new(WebrtcAudio.kNumChannels, 0)
    # Construct a speech signal that will trigger the VAD in all modes. It is
    # known that (i * i) will wrap around, but that doesn't matter in this case.
    speech = Array(Int16).new(KMaxFrameLength, 0)
    (0...KMaxFrameLength).each { |i|
      tmp = i &* i
      # convert i to u16, then back to i 16
      speech[i] = tmp.to_i16!
    }
    speech_slice = Slice(Int16).new(speech.to_unsafe, KMaxFrameLength)
    frame_length_index = 0_i32
    WebrtcAudio::Vad.init_core(inst)
    (0...KFrameLengthsSize).each { |j|
      if validRatesAndFrameLengths(8000, KFrameLengths[j])
        WebrtcAudio::Vad.calculate_features(inst, speech_slice, KFrameLengths[j], features).should eq(kReference[frame_length_index])
        (0...WebrtcAudio.kNumChannels).each { |k|
          features[k].should eq(kFeatures[k + frame_length_index * WebrtcAudio.kNumChannels])
        }
        frame_length_index += 1
      end
    }
    frame_length_index.should eq(kNumValidFrameLengths)
    # Verify that all zeros in gives kOffsetVector out.
    speech.fill(0)
    WebrtcAudio::Vad.init_core(inst)
    (0...KFrameLengthsSize).each { |j|
      if validRatesAndFrameLengths(8000, KFrameLengths[j])
        WebrtcAudio::Vad.calculate_features(inst, speech_slice, KFrameLengths[j], features).should eq(0)
        (0...WebrtcAudio.kNumChannels).each { |k|
          features[k].should eq(kOffsetVector[k])
        }
      end
    }
    # Verify that all ones in gives kOffsetVector out. Any other constant input
    # will have a small impact in the sub bands.
    (0...KMaxFrameLength).each { |i|
      speech[i] = 1_i16
    }
    (0...KFrameLengthsSize).each { |j|
      if validRatesAndFrameLengths(8000, KFrameLengths[j])
        WebrtcAudio::Vad.init_core(inst)
        WebrtcAudio::Vad.calculate_features(inst, speech_slice, KFrameLengths[j], features).should eq(0)
        (0...WebrtcAudio.kNumChannels).each { |k|
          features[k].should eq(kOffsetVector[k])
        }
      end
    }
  end
end
