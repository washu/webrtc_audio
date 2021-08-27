require "./spec_helper"

describe WebrtcAudio::Vad do
  it "should test the sp code" do
    inst = WebrtcAudio::VadInstance.new
    kMaxFrameLenSp = 960 # Maximum frame length in this unittest.
    zeros = Array(Int16).new(kMaxFrameLenSp, 0)
    state = [0, 0]
    data_in = Array(Int16).new(kMaxFrameLenSp, 0)
    data_out = Array(Int16).new(kMaxFrameLenSp, 0)
    kReferenceMin = [
      1600, 720, 509, 512, 532, 552, 570, 588,
      606, 624, 642, 659, 675, 691, 707, 723,
      1600, 544, 502, 522, 542, 561, 579, 597,
      615, 633, 651, 667, 683, 699, 715, 731,
    ]
    # We expect the first value to be 1600 as long as |frame_counter| is zero,
    # which is true for the first iteration.
    # kReferenceMin = Array(Int16).new(32,0)
    # Construct a speech signal that will trigger the VAD in all modes. It is
    # known that (i * i) will wrap around, but that doesn't matter in this case.
    (0...kMaxFrameLenSp).each { |i|
      tmp = i &* i
      # convert i to u16, then back to i 16
      data_in[i] = tmp.to_i16!
    }
    WebrtcAudio::Vad.downsampling(
      Slice(Int16).new(zeros.to_unsafe, kMaxFrameLenSp),
      Slice(Int16).new(data_out.to_unsafe, kMaxFrameLenSp),
      state, kMaxFrameLenSp
    )
    # Input values all zeros, expect all zeros out.
    state[0].should eq(0)
    state[1].should eq(0)

    (0...((kMaxFrameLenSp/2).round.to_i32)).each { |i|
      data_out[i].should eq(0_i16)
    }
    # Make a simple non-zero data test.
    WebrtcAudio::Vad.downsampling(
      Slice(Int16).new(data_in.to_unsafe, kMaxFrameLenSp),
      Slice(Int16).new(data_out.to_unsafe, kMaxFrameLenSp),
      state, kMaxFrameLenSp
    )
    state[0].should eq(207)
    state[1].should eq(2270)
    WebrtcAudio::Vad.init_core(inst)
    # TODO(bjornv): Replace this part of the test with taking values from an
    # array and calculate the reference value here. Make sure the values are not
    # ordered.
    (0...16).each { |i|
      value = (500 &* (i &+ 1))
      (0...WebrtcAudio.kNumChannels).each { |j|
        mn = WebrtcAudio::Vad.find_minimum(inst, value.to_i16, j)
        mn.should eq(kReferenceMin[i])
        nn = WebrtcAudio::Vad.find_minimum(inst, 12000_i16, j)
        nn.should eq(kReferenceMin[i + 16])
      }
      inst.frame_count += 1
    }
  end
end
