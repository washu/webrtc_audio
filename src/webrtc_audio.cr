# TODO: Write documentation for `WebrtcAudio`
module WebrtcAudio
  VERSION               = "1.0.1"
  WEBRTC_SPL_WORD16_MAX = Int16::MAX
  WEBRTC_SPL_WORD16_MIN = Int16::MIN
  WEBRTC_SPL_WORD32_MAX = Int32::MAX
  WEBRTC_SPL_WORD32_MIN = Int32::MIN

  def self.kNumChannels : Int32
    return 6
  end

  def self.kNumGaussians : Int32
    return 2
  end

  def self.kTableSize : Int32
    return self.kNumChannels * self.kNumGaussians
  end

  def self.kMinEnergy : Int32
    return 10
  end

  # Returns the number of leading zero bits in the argument
  def self.count_leading_zeros32(n : UInt32) : Int32
    return n == 0 ? 32 : n.leading_zeros_count
  end

  def self.count_leading_zeros32(n : Int32) : Int32
    return n == 0 ? 32 : (n.leading_zeros_count)
  end

  def self.get_size_in_bits(n : UInt32) : Int16
    return (32 - self.count_leading_zeros32(n)).to_i16
  end

  def self.get_size_in_bits(n : Int32) : Int16
    return (32 - self.count_leading_zeros32(n.to_u32)).to_i16
  end

  # Return the number of steps a can be left-shifted without overflow
  def self.norm_w32(a : Int32) : Int16
    return a == 0 ? 0_i16 : (self.count_leading_zeros32((a < 0 ? ~a : a).to_u32) - 1).to_i16
  end

  # Return the number of steps a can be left-shifted without overflow
  def self.norm_w32(a : UInt32) : Int16
    return a == 0 ? 0_i16 : self.count_leading_zeros32(a).to_i16
  end

  def self.spl_mul(a : Int, b : Int) : Int32
    g = a &* b
    if !g.is_a?(Int32)
      if g > Int32::MAX
        return Int32::MAX
      elsif g < Int32::MIN
        return Int32::MIN
      end
      return g.to_i32
    end
    return g
  end
end
