require "./spec_helper"
describe WebrtcAudio::SignalProcessing do
  it "should convert macro call correctly" do
    b = 21
    a = -3
    mx = WebrtcAudio::WEBRTC_SPL_WORD32_MAX

    l = WebrtcAudio.spl_mul(a, b)
    l.should eq(-63)
    l = WebrtcAudio.spl_mul(a, mx)
    l.should eq(-2147483645)
  end

  it "should test spl commands" do
    a32 = 111121_i32
    WebrtcAudio.get_size_in_bits(a32).should eq(17)
    WebrtcAudio.norm_w32(0_i32).should eq(0)
    WebrtcAudio.norm_w32(-1_i32).should eq(31)
    WebrtcAudio.norm_w32(Int32::MIN).should eq(0)
    WebrtcAudio.norm_w32(a32).should eq(14)
    WebrtcAudio.norm_w32(0_u32).should eq(0)
    WebrtcAudio.norm_w32(0xffffffff_u32).should eq(0)
    WebrtcAudio.norm_w32(a32.to_u32).should eq(15)
  end

  it "should test leading zeros" do
    WebrtcAudio.count_leading_zeros32(0).should eq(32)
    (0...32).each { |i|
      single_one = 1_u32 << i
      all_ones = (2 &* single_one &- 1)
      WebrtcAudio.count_leading_zeros32(single_one).should eq(31 - i)
      WebrtcAudio.count_leading_zeros32(all_ones).should eq(31 - i)
    }
  end

  it "should test extra math" do
    num = 117_i32
    den = -5_i32
    WebrtcAudio::SignalProcessing.div_w32_w16(num, den.to_i16).should eq(-23)
  end

  it "should test signal processing logic" do
    kVectorSize = 4_i32
    a = [1_i32, 2_i32, 33_i32, 100_i32]
    b16 = Array(Int16).new(kVectorSize, 0)
    bScale = 0_i32
    (0...kVectorSize).each { |kk|
      b16[kk] = a[kk].to_i16
    }
    rc = WebrtcAudio::SignalProcessing.energy(Slice(Int16).new(b16.to_unsafe, kVectorSize), kVectorSize)
    rc[1].should eq(0)
    rc[0].should eq(11094)
  end

  it "should resample audio" do
    # The test resamples 3*kBlockSize number of samples to 2*kBlockSize number
    # of samples.
    kBlockSize = 16
    # Saturated input vector of 48 samples.
    kVectorSaturated = [
      -32768, -32768, -32768, -32768, -32768, -32768, -32768, -32768,
      -32768, -32768, -32768, -32768, -32768, -32768, -32768, -32768,
      -32768, -32768, -32768, -32768, -32768, -32768, -32768, -32768,
      32767, 32767, 32767, 32767, 32767, 32767, 32767, 32767,
      32767, 32767, 32767, 32767, 32767, 32767, 32767, 32767,
      32767, 32767, 32767, 32767, 32767, 32767, 32767, 32767,
      32767, 32767, 32767, 32767, 32767, 32767, 32767,
    ]
    kv_slice = Slice(Int32).new(kVectorSaturated.to_unsafe, 3 * kBlockSize + 7)
    # All values in |out_vector| should be |kRefValue32kHz|.
    kRefValue32kHz1 = -1077493760_i32
    kRefValue32kHz2 = 1077493645_i32
    # After bit shift with saturation, |out_vector_w16| is saturated.
    # Vector for storing output.
    out_vector = Array(Int32).new(2 * kBlockSize, 0)
    out_slice = Slice(Int32).new(out_vector.to_unsafe, 2 * kBlockSize)

    WebrtcAudio::SignalProcessing.resample_48khz_to_32khz(kv_slice, out_slice, kBlockSize)

    # Comparing output values against references. The values at position
    # 12-15 are skipped to account for the filter lag.
    (0...12).each { |i|
      out_vector[i].should eq(kRefValue32kHz1)
    }
    (16...(2 * kBlockSize)).each { |i|
      out_vector[i].should eq(kRefValue32kHz2)
    }
  end

  it "loads" do
    true.should eq(true)
  end
end
