require "./spec_helper"

describe WebrtcAudio::Vad do
  it "Inits an instance" do
    g = WebrtcAudio::VadInstance.new
    WebrtcAudio::Vad.init_core(g).should eq(0)
    g.init_flag.should eq(42)
  end
  it "set teh instance mode" do
    g = WebrtcAudio::VadInstance.new
    WebrtcAudio::Vad.init_core(g).should eq(0)
    WebrtcAudio::Vad.set_mode_core(g, -1).should eq(-1)
    WebrtcAudio::Vad.set_mode_core(g, 1000).should eq(-1)
    KModes.each { |i|
      WebrtcAudio::Vad.set_mode_core(g, i).should eq(0)
    }
  end
  it "should calc vad" do
    g = WebrtcAudio::VadInstance.new
    speech = Array(Int16).new(KMaxFrameLength, 0)
    speech_slice = Slice(Int16).new(speech.to_unsafe, KMaxFrameLength)
    # Test WebRtcVad_CalcVadXXkhz()
    # Verify that all zeros in gives VAD = 0 out.
    WebrtcAudio::Vad.init_core(g).should eq(0)
    speech.fill(0)
    (0...KFrameLengthsSize).each { |j|
      if (validRatesAndFrameLengths(8000, KFrameLengths[j]))
        WebrtcAudio::Vad.calc_vad_8khz(g, speech_slice, KFrameLengths[j]).should eq(0)
      end
      if (validRatesAndFrameLengths(16000, KFrameLengths[j]))
        WebrtcAudio::Vad.calc_vad_16khz(g, speech_slice, KFrameLengths[j]).should eq(0)
      end
      if (validRatesAndFrameLengths(32000, KFrameLengths[j]))
        WebrtcAudio::Vad.calc_vad_32khz(g, speech_slice, KFrameLengths[j]).should eq(0)
      end
      if (validRatesAndFrameLengths(48000, KFrameLengths[j]))
        WebrtcAudio::Vad.calc_vad_48khz(g, speech_slice, KFrameLengths[j]).should eq(0)
      end
    }
    # Construct a speech signal that will trigger the VAD in all modes. It is
    # known that (i * i) will wrap around, but that doesn't matter in this case.
    (0...KMaxFrameLength).each { |i|
      tmp = i &* i
      # convert i to u16, then back to i 16
      speech[i] = tmp.to_i16!
    }
    speech_slice = Slice(Int16).new(speech.to_unsafe, KMaxFrameLength)
    # test again
    (0...KFrameLengthsSize).each { |j|
      if (validRatesAndFrameLengths(8000, KFrameLengths[j]))
        WebrtcAudio::Vad.calc_vad_8khz(g, speech_slice, KFrameLengths[j]).should eq(1)
      end
      if (validRatesAndFrameLengths(16000, KFrameLengths[j]))
        WebrtcAudio::Vad.calc_vad_16khz(g, speech_slice, KFrameLengths[j]).should eq(1)
      end
      if (validRatesAndFrameLengths(32000, KFrameLengths[j]))
        WebrtcAudio::Vad.calc_vad_32khz(g, speech_slice, KFrameLengths[j]).should eq(1)
      end
      if (validRatesAndFrameLengths(48000, KFrameLengths[j]))
        WebrtcAudio::Vad.calc_vad_48khz(g, speech_slice, KFrameLengths[j]).should eq(1)
      end
    }
  end
end
