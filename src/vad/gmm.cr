require "../models/*"
require "../signal_processing/*"

module WebrtcAudio
  module Vad
    def self.kCompVar : Int32
      return 22005
    end

    def self.kLog2Exp : Int16
      return 5909_i16
    end

    def self.gaussian_probability(input : Int16, mean : Int16, std : Int16, delta : Slice(Int16)) : Int32
      puts "GGG #{input} #{mean} #{std} #{delta[0]}"
      tmp16 = inv_std = inv_std2 = exp_value = 0_i16
      tmp32 = 0_i32
      # Calculate |inv_std| = 1 / s, in Q10.
      # 131072 = 1 in Q17, and (|std| >> 1) is for rounding instead of truncation.
      # Q-domain: Q17 / Q7 = Q10.
      tmp32 = (131072_i32 &+ (std >> 1).to_i32!).to_i32!
      inv_std = WebrtcAudio::SignalProcessing.div_w32_w16(tmp32, std).to_i16!
      # puts "Temp32 is #{tmp32} inv #{inv_std}"
      # Calculate |inv_std2| = 1 / s^2, in Q14.
      tmp16 = (inv_std.to_i32 >> 2).to_i16! # Q10 -> Q8.
      # Q-domain: (Q8 * Q8) >> 2 = Q14.
      inv_std2 = ((tmp16.to_i32 &* tmp16.to_i32) >> 2).to_i16!
      # puts "Temp 16 #{tmp16} inv #{inv_std2}"
      # TODO(bjornv): Investigate if changing to
      # inv_std2 = (int16_t)((inv_std * inv_std) >> 6);
      # gives better accuracy.

      tmp16 = (input << 3).to_i16 # Q4 -> Q7
      # puts "Q4 #{tmp16} mean: #{mean} input: #{input}"
      tmp16 = (tmp16 - mean) # Q7 - Q7 = Q7
      # puts "Temp 16 #{tmp16} :#{inv_std2} post Q7"
      # To be used later, when updating noise/speech model.
      # |delta| = (x - m) / s^2, in Q11.
      # Q-domain: (Q14 * Q7) >> 10 = Q11.
      # puts "Pre delta update #{((inv_std2.to_i32! &* tmp16.to_i32!).to_i32! >> 10).to_i16!}"
      delta[0] = ((inv_std2.to_i32! &* tmp16.to_i32!).to_i32 >> 10).to_i16!
      # puts "Delta update #{delta[0]}"
      # Calculate the exponent |tmp32| = (x - m)^2 / (2 * s^2), in Q10. Replacing
      # division by two with one shift.
      # Q-domain: (Q11 * Q7) >> 8 = Q10.
      tmp32 = ((delta[0].to_i32! &* tmp16.to_i32!).to_i32! >> 9).to_i32!
      # puts "Temp 32 pre comp #{tmp32} #{kCompVar()} #{(delta[0])} #{tmp16}"
      # If the exponent is small enough to give a non-zero probability we calculate
      # |exp_value| ~= exp(-(x - m)^2 / (2 * s^2))
      # ~= exp2(-log2(exp(1)) * |tmp32|).
      if tmp32 < kCompVar()
        # Calculate |tmp16| = log2(exp(1)) * |tmp32|, in Q10.
        # Q-domain: (Q12 * Q10) >> 12 = Q10.
        # puts "Tree 1"
        tmp16 = ((kLog2Exp().to_i32 &* tmp32.to_i32) >> 12).to_i16!
        tmp16 = -tmp16
        # puts "Tree 1: Tmp16 #{tmp16}"
        exp_value = (0x0400_i16 | (tmp16 & 0x03FF_i16)).to_i16
        # puts "Tree 1: Exp value #{exp_value}"
        tmp16 = (tmp16.to_i32 ^ 0xFFFF_u16).to_i16!
        # puts "Tree 1a: #{tmp16}"
        tmp16 = (tmp16.to_i32 >> 10).to_i16!
        # puts "Tree 1b: #{tmp16}"
        tmp16 += 1
        # puts "Tree 1c: #{tmp16}"
        # Get |exp_value| = exp(-|tmp32|) in Q10.
        exp_value = (exp_value.to_i32 >> tmp16).to_i32!
      end
      # puts "Output #{exp_value} delta: #{delta[0]}"
      # Calculate and return (1 / s) * exp(-(x - m)^2 / (2 * s^2)), in Q20.
      # Q-domain: Q10 * Q10 = Q20.
      return (inv_std.to_i32 * exp_value.to_i32).to_i32
    end
  end
end
