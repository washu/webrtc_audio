require "../models/*"

module WebrtcAudio
  module Vad
    def self.kAllPassCoefsQ13 : Array(Int16)
      return [5243_i16, 1392_i16]
    end

    def self.kSmoothingDown : Int16
      return 6553_i16
    end

    def self.kSmoothingUp : Int16
      return 32439_i16
    end

    def self.downsampling(signal_in : Slice(Int16), signal_out : Slice(Int16), filter_state : Array(Int32), length : Int32) : Void
      tmp16_1 = tmp16_2 = 0_i16
      tmp32_1 = filter_state[0]
      tmp32_2 = filter_state[1]
      in_length = length
      half_length = (in_length >> 1)
      inPtr = 0
      outPtr = 0
      # Filter coefficients in Q13, filter state in Q0.
      (0...half_length).each { |n|
        # All-pass filtering upper branch.
        tmp16_1 = ((tmp32_1 >> 1) &+ ((kAllPassCoefsQ13()[0].to_i32! &* signal_in[inPtr].to_i32!) >> 14)).to_i16!
        signal_out[outPtr] = tmp16_1
        tmp32_1 = (signal_in[inPtr]) &- ((kAllPassCoefsQ13()[0].to_i32! &* tmp16_1.to_i32!) >> 12).to_i32!

        inPtr += 1
        # All-pass filtering lower branch.
        tmp16_2 = ((tmp32_2 >> 1) &+ ((kAllPassCoefsQ13()[1].to_i32! &* signal_in[inPtr].to_i32!) >> 14)).to_i16!
        signal_out[outPtr] = (signal_out[outPtr] &+ tmp16_2).to_i16!
        outPtr += 1
        tmp32_2 = (signal_in[inPtr]) &- ((kAllPassCoefsQ13[1].to_i32! &* tmp16_2.to_i32!) >> 12).to_i32!
        inPtr += 1
      }
      # Store the filter states.
      filter_state[0] = tmp32_1.to_i32!
      filter_state[1] = tmp32_2.to_i32!
    end

    def self.find_minimum(inst : VadInstance, feature_value : Int16, channel : Int32) : Int16
      i = j = 0_i32
      position = -1_i32
      offset = (channel << 4).to_i32
      current_median = 1600_i16
      alpha = 0_i16
      tmp32 = 0_i32
      age = inst.age_vector
      smallest_values = inst.low_value_vector
      # Each value in |smallest_values| is getting 1 loop older. Update |age|, and
      # remove old values.
      i = 0
	  while i < 16
        if (age[offset + i] != 100)
          age[offset + i] += 1
        else
          # Too old value. Remove from memory and shift larger values downwards.
		  j = i
          while j < 16
		    lidx = offset + j
			smallest_values[lidx] = smallest_values[lidx + 1]
			age[lidx] = age[lidx + 1]
			j += 1
		  end
          age[offset + 15] = 101
          smallest_values[offset + 15] = 10000
        end
		i += 1
      end
      # Check if |feature_value| is smaller than any of the values in
      # |smallest_values|. If so, find the |position| where to insert the new value
      # (|feature_value|).
      if (feature_value < smallest_values[offset + 7])
        if (feature_value < smallest_values[offset + 3])
          if (feature_value < smallest_values[offset + 1])
            if (feature_value < smallest_values[offset + 0])
              position = 0
            else
              position = 1
            end
          elsif (feature_value < smallest_values[offset + 2])
            position = 2
          else
            position = 3
          end
        elsif (feature_value < smallest_values[offset + 5])
          if (feature_value < smallest_values[offset + 4])
            position = 4
          else
            position = 5
          end
        elsif (feature_value < smallest_values[offset + 6])
          position = 6
        else
          position = 7
        end
      elsif (feature_value < smallest_values[offset + 15])
        if (feature_value < smallest_values[offset + 11])
          if (feature_value < smallest_values[offset + 9])
            if (feature_value < smallest_values[offset + 8])
              position = 8
            else
              position = 9
            end
          elsif (feature_value < smallest_values[offset + 10])
            position = 10
          else
            position = 11
          end
        elsif (feature_value < smallest_values[offset + 13])
          if (feature_value < smallest_values[offset + 12])
            position = 12
          else
            position = 13
          end
        elsif (feature_value < smallest_values[offset + 14])
          position = 14
        else
          position = 15
        end
      end
      # If we have detected a new small value, insert it at the correct position
      # and shift larger values up.
      if (position > -1)
        i = 15
        while i > position
          smallest_values[offset + i] = smallest_values[offset + (i - 1)]
          age[offset + i] = age[offset + (i - 1)]
          i -= 1
        end
        smallest_values[offset + position] = feature_value
        age[offset + position] = 1
      end
      # Get |current_median|.
      if (inst.frame_count > 2)
        current_median = smallest_values[offset + 2]
      elsif (inst.frame_count > 0)
        current_median = smallest_values[offset + 0]
      end
      # Smooth the median value.
      if inst.frame_count > 0
        if current_median < inst.median[channel]
          alpha = kSmoothingDown() # 0.2 in Q15.
        else
          alpha = kSmoothingUp() # 0.99 in Q15.
        end
      end
      tmp32 = (alpha.to_i32 &+ 1).to_i32! &* inst.median[channel].to_i32!
      tmp32 = (tmp32.to_i32! &+ ((WEBRTC_SPL_WORD16_MAX - alpha).to_i32 &* current_median.to_i32)).to_i32!
      tmp32 += 16384_i32
      inst.median[channel] = (tmp32.to_i32! >> 15).to_i16!
      return inst.median[channel]
    end
  end
end
