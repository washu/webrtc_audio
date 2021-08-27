require "./spec_helper"

describe WebrtcAudio::Vad do
  it "should test the GMM code" do
    delta = 0_i16
    delta_slice = Slice(Int16).new(pointerof(delta), 1)
    # Input value at mean.
    WebrtcAudio::Vad.gaussian_probability(0, 0, 128, delta_slice).should eq(1048576)
    delta.should eq(0)

    WebrtcAudio::Vad.gaussian_probability(16, 128, 128, delta_slice).should eq(1048576)
    delta.should eq(0)

    WebrtcAudio::Vad.gaussian_probability(-16, -128, 128, delta_slice).should eq(1048576)
    delta.should eq(0)

    # Largest possible input to give non-zero probability.
    WebrtcAudio::Vad.gaussian_probability(59, 0, 128, delta_slice).should eq(1024)
    delta.should eq(7552)

    WebrtcAudio::Vad.gaussian_probability(75, 128, 128, delta_slice).should eq(1024)
    delta.should eq(7552)

    WebrtcAudio::Vad.gaussian_probability(-75, -128, 128, delta_slice).should eq(1024)
    delta.should eq(-7552)

    # Too large input, should give zero probability.
    WebrtcAudio::Vad.gaussian_probability(105, 0, 128, delta_slice).should eq(0)
    delta.should eq(13440)
  end
end
