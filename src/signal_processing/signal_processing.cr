require "../models/*"

module WebrtcAudio
  module SignalProcessing
    # resample_by_2_internal
    def self.kResampleAllpass : Array(Array(Int16))
      return [[821_i16, 6110_i16, 12382_i16], [3050_i16, 9368_i16, 15063_i16]]
    end

    # division_operations.c
    def self.div_w32_w16(num : Int32, den : Int16) : Int32
      if den != 0
        return (num / den).to_i32
      else
        return (0x7FFFFFFF).to_i32
      end
    end

    # get_scaling_square.c
    def self.get_scaling_square(in_vector : Slice(Int16), length : Int32, times : Int32) : Int16
      nbits = WebrtcAudio.get_size_in_bits(times.to_u32)
      smax = -1_i16
      sabs = 0_i16
      (0...length).each { |i|
        val = in_vector[i]
        sabs = val.abs
        smax = (sabs > smax ? sabs : smax)
      }
      t = WebrtcAudio.norm_w32(WebrtcAudio.spl_mul(smax, smax))
      if smax == 0
        return 0_i16
      else
        return t > nbits ? 0_i16 : (nbits - t).to_i16
      end
    end

    # energy.c
    def self.energy(vector : Slice(Int16), length : Int32) : Array(Int32)
      rc = [0, 0] of Int32
      en = 0_i32
      scaling = self.get_scaling_square(vector, length, length).to_i32
      (0...length).each { |v|
        en = (en.to_i32! &+ ((vector[v].to_i32 &* vector[v].to_i32).to_i32 >> scaling).to_i32!).to_i32!
      }
      rc[1] = scaling
      rc[0] = en
      return rc
    end

    # resample_by_internal_2.c
    def self.down_by_2_int_to_short(input : Slice(Int32), len : Int32, output : Slice(Int16), state : Array(Int32)) : Void
      len >>= 1
      inPtr = 0
      outPtr = 0
      tmp0 = tmp1 = diff = 0
      (0...len).each { |i|
        tmp0 = input[inPtr + (i << 1)]
        diff = (tmp0 &- state[1]).to_i32!
        # scale down and round
        diff = (diff + (1 << 13)) >> 14
        tmp1 = (state[0] &+ diff &* kResampleAllpass[1][0]).to_i32!
        state[0] = tmp0
        diff = (tmp1 &- state[2]).to_i32!
        # scale down and truncate
        diff = diff >> 14
        if (diff < 0)
          diff += 1
        end
        tmp0 = (state[1] &+ diff &* kResampleAllpass[1][1]).to_i32!
        state[1] = tmp1
        diff = (tmp0 &- state[3]).to_i32!
        # scale down and truncate
        diff = diff >> 14
        if (diff < 0)
          diff += 1
        end
        state[3] = (state[2] &+ diff &* kResampleAllpass[1][2]).to_i32!
        state[2] = tmp0
        # divide by two and store temporarily
        input[inPtr + (i << 1)] = (state[3] >> 1)
      }
      inPtr += 1
      (0...len).each { |i|
        tmp0 = input[inPtr + (i << 1)]
        diff = (tmp0 &- state[5]).to_i32!
        # scale down and round
        diff = (diff + (1 << 13)) >> 14
        tmp1 = (state[4] &+ diff &* kResampleAllpass[0][0]).to_i32!
        state[4] = tmp0
        diff = (tmp1 &- state[6]).to_i32!
        # scale down and round
        diff = diff >> 14
        if (diff < 0)
          diff += 1
        end
        tmp0 = (state[5] &+ diff &* kResampleAllpass[0][1]).to_i32!
        state[5] = tmp1
        diff = (tmp0 &- state[7]).to_i32!
        # scale down and truncate
        diff = diff >> 14
        if (diff < 0)
          diff += 1
        end
        state[7] = (state[6] &+ diff &* kResampleAllpass[0][2]).to_i32!
        state[6] = tmp0
        # divide by two and store temporarily
        input[inPtr + (i << 1)] = (state[7] >> 1)
      }
      inPtr -= 1
      i = 0
      while i < len
        tmp0 = ((input[inPtr + (i << 1)] &+ input[inPtr &+ (i << 1) &+ 1]) >> 15).to_i32!
        tmp1 = ((input[inPtr &+ (i << 1) &+ 2] &+ input[inPtr &+ (i << 1) &+ 3]) >> 15).to_i32!
        output[i] = tmp0.to_i16!
        output[(i + 1)] = tmp1.to_i16!
        i += 2
      end
    end

    def self.down_by_2_short_to_int(input : Slice(Int16), len : Int32, output : Slice(Int32), state : Array(Int32)) : Void
      len >>= 1
      inPtr = 0
      outPtr = 0
      tmp0 = tmp1 = diff = 0
      (0...len).each { |i|
        tmp0 = ((input[inPtr + (i << 1)].to_i32) << 15) + (1 << 14)
        diff = (tmp0 - state[1]).to_i32!
        # scale down and round
        diff = (diff + (1 << 13)) >> 14
        tmp1 = (state[0] &+ diff &* kResampleAllpass[1][0]).to_i32!
        state[0] = tmp0
        diff = (tmp1 &- state[2]).to_i32!
        # scale down and truncate
        diff = diff >> 14
        if (diff < 0)
          diff += 1
        end
        tmp0 = (state[1] &+ diff &* kResampleAllpass[1][1]).to_i32!
        state[1] = tmp1
        diff = (tmp0 &- state[3]).to_i32!
        # scale down and truncate
        diff = diff >> 14
        if (diff < 0)
          diff += 1
        end
        state[3] = (state[2] &+ diff &* kResampleAllpass[1][2]).to_i32!
        state[2] = tmp0
        # divide by two and store temporarily
        output[i] = (state[3] >> 1)
      }
      inPtr += 1
      (0...len).each { |i|
        tmp0 = (input[inPtr + (i << 1)].to_i32 << 15) + (1 << 14)
        diff = tmp0 - state[5]
        # scale down and round
        diff = (diff + (1 << 13)) >> 14
        tmp1 = (state[4] &+ diff &* kResampleAllpass[0][0]).to_i32!
        state[4] = tmp0
        diff = (tmp1 &- state[6]).to_i32!
        # scale down and round
        diff = diff >> 14
        if (diff < 0)
          diff += 1
        end
        tmp0 = (state[5] &+ diff &* kResampleAllpass[0][1]).to_i32!
        state[5] = tmp1
        diff = (tmp0 &- state[7]).to_i32!
        # scale down and truncate
        diff = diff >> 14
        if (diff < 0)
          diff += 1
        end
        state[7] = (state[6] &+ diff &* kResampleAllpass[0][2]).to_i32!
        state[6] = tmp0
        # divide by two and store temporarily
        output[i] += (state[7] >> 1)
      }
    end

    def self.lpb_y2_int_to_int(input : Slice(Int32), len : Int32, output : Slice(Int32), state : Array(Int32)) : Void
      len >>= 1
      inPtr = 1
      outPtr = 0
      tmp0 = tmp1 = diff = 0
      # initial state of polyphase delay element
      tmp0 = state[12]
      # lower allpass filter: odd input -> even output samples
      (0...len).each { |i|
        diff = (tmp0 &- state[1]).to_i32!
        # scale down and round
        diff = (diff + (1 << 13)) >> 14
        tmp1 = (state[0] &+ diff &* kResampleAllpass[1][0]).to_i32!
        state[0] = tmp0
        diff = (tmp1 &- state[2]).to_i32!
        # scale down and truncate
        diff = diff >> 14
        if (diff < 0)
          diff += 1
        end
        tmp0 = (state[1] &+ diff &* kResampleAllpass[1][1]).to_i32!
        state[1] = tmp1
        diff = (tmp0 &- state[3]).to_i32!
        # scale down and truncate
        diff = diff >> 14
        if (diff < 0)
          diff += 1
        end
        state[3] = (state[2] &+ diff &* kResampleAllpass[1][2]).to_i32!
        state[2] = tmp0
        # scale down, round and store
        output[outPtr + (i << 1)] = state[3] >> 1
        tmp0 = input[inPtr + (i << 1)]
      }
      inPtr -= 1
      # upper allpass filter: even input -> even output samples
      (0...len).each { |i|
        tmp0 = input[i << 1]
        diff = (tmp0 &- state[5]).to_i32!
        # scale down and round
        diff = (diff + (1 << 13)) >> 14
        tmp1 = (state[4] &+ diff &* kResampleAllpass[0][0]).to_i32!
        state[4] = tmp0
        diff = (tmp1 &- state[6]).to_i32!
        # scale down and round
        diff = diff >> 14
        if (diff < 0)
          diff += 1
        end
        tmp0 = (state[5] &+ diff &* kResampleAllpass[0][1]).to_i32!
        state[5] = tmp1
        diff = (tmp0 &- state[7]).to_i32!
        # scale down and truncate
        diff = diff >> 14
        if (diff < 0)
          diff += 1
        end
        state[7] = (state[6] &+ diff &* kResampleAllpass[0][2]).to_i32!
        state[6] = tmp0
        # average the two allpass outputs, scale down and store
        output[outPtr + (i << 1)] = (output[outPtr + (i << 1)] + (state[7] >> 1)) >> 15
      }
      outPtr += 1
      # lower allpass filter: even input -> odd output samples
      (0...len).each { |i|
        tmp0 = input[inPtr + (i << 1)]
        diff = (tmp0 &- state[9]).to_i32!
        # scale down and round
        diff = (diff + (1 << 13)) >> 14
        tmp1 = (state[8] &+ diff &* kResampleAllpass[1][0]).to_i32!
        state[8] = tmp0
        diff = (tmp1 &- state[10]).to_i32!
        # scale down and truncate
        diff = diff >> 14
        if (diff < 0)
          diff += 1
        end
        tmp0 = (state[9] &+ diff &* kResampleAllpass[1][1]).to_i32!
        state[9] = tmp1
        diff = (tmp0 &- state[11]).to_i32!
        # scale down and truncate
        diff = diff >> 14
        if (diff < 0)
          diff += 1
        end
        state[11] = (state[10] &+ diff &* kResampleAllpass[1][2]).to_i32!
        state[10] = tmp0
        # scale down, round and store
        output[outPtr + (i << 1)] = state[11] >> 1
      }
      inPtr += 1
      # upper allpass filter: odd input -> odd output samples
      (0...len).each { |i|
        tmp0 = input[inPtr + (i << 1)]
        diff = (tmp0 &- state[13]).to_i32!
        # scale down and round
        diff = (diff + (1 << 13)) >> 14
        tmp1 = (state[12] &+ diff &* kResampleAllpass[0][0]).to_i32!
        state[12] = tmp0
        diff = (tmp1 &- state[14]).to_i32!
        # scale down and round
        diff = diff >> 14
        if (diff < 0)
          diff += 1
        end
        tmp0 = (state[13] &+ diff &* kResampleAllpass[0][1]).to_i32!
        state[13] = tmp1
        diff = (tmp0 &- state[15]).to_i32!
        # scale down and truncate
        diff = diff >> 14
        if (diff < 0)
          diff += 1
        end
        state[15] = (state[14] &+ diff &* kResampleAllpass[0][2]).to_i32!
        state[14] = tmp0
        # average the two allpass outputs, scale down and store
        output[outPtr + (i << 1)] = (output[outPtr + (i << 1)] + (state[15] >> 1)) >> 15
      }
    end

    # resample_48khz.c
    def self.reset_resample_48khz_to_8khz(state : State48khzTo8khz)
      state.s_48_24.fill(0)
      state.s_24_24.fill(0)
      state.s_24_16.fill(0)
      state.s_16_8.fill(0)
    end

    # resample_fractional.c
    def self.kCoefficients48To32 : Array(Array(Int32))
      return [
        [778, -2050, 1087, 23285, 12903, -3783, 441, 222],
        [222, 441, -3783, 12903, 23285, 1087, -2050, 778],
      ]
    end

    def self.resample_48khz_to_32khz(input : Slice(Int32), output : Slice(Int32), k : Int32) : Void
      tmp = 0
      inPtr = 0
      outPrt = 0
      (0...k).each { |m|
        tmp = 1 << 14
        tmp += kCoefficients48To32()[0][0] &* input[inPtr + 0]
        tmp += kCoefficients48To32()[0][1] &* input[inPtr + 1]
        tmp += kCoefficients48To32()[0][2] &* input[inPtr + 2]
        tmp += kCoefficients48To32()[0][3] &* input[inPtr + 3]
        tmp += kCoefficients48To32()[0][4] &* input[inPtr + 4]
        tmp += kCoefficients48To32()[0][5] &* input[inPtr + 5]
        tmp += kCoefficients48To32()[0][6] &* input[inPtr + 6]
        tmp += kCoefficients48To32()[0][7] &* input[inPtr + 7]
        output[outPrt + 0] = tmp.to_i32
        tmp = 1 << 14
        tmp += kCoefficients48To32()[1][0] &* input[inPtr + 1]
        tmp += kCoefficients48To32()[1][1] &* input[inPtr + 2]
        tmp += kCoefficients48To32()[1][2] &* input[inPtr + 3]
        tmp += kCoefficients48To32()[1][3] &* input[inPtr + 4]
        tmp += kCoefficients48To32()[1][4] &* input[inPtr + 5]
        tmp += kCoefficients48To32()[1][5] &* input[inPtr + 6]
        tmp += kCoefficients48To32()[1][6] &* input[inPtr + 7]
        tmp += kCoefficients48To32()[1][7] &* input[inPtr + 8]
        output[outPrt + 1] = tmp.to_i32
        inPtr += 3
        outPrt += 2
      }
    end

    # 48 -> resample
    def self.resample_48khz_to_8khz(input : Slice(Int16), output : Slice(Int16), state : State48khzTo8khz, temp_mem : Slice(Int32)) : Void
      # /// 48 --> 24 /////
      # int16_t  in[480]
      # int32_t out[240]
      self.down_by_2_short_to_int(input, 480, temp_mem + 256, state.s_48_24)
      # /// 24 --> 24(LP) /////
      # int32_t  in[240]
      # int32_t out[240]
      self.lpb_y2_int_to_int(temp_mem + 256, 240, temp_mem + 16, state.s_24_24)
      # /// 24 --> 16 /////
      # int32_t  in[240]
      # int32_t out[160]
      # copy state to and from input array
      (0...8).each { |i|
        temp_mem[i + 8] = state.s_24_16[i]
      }
      (0...8).each { |i|
        state.s_24_16[i] = temp_mem[248 + i]
      }
      self.resample_48khz_to_32khz(temp_mem + 8, temp_mem, 80)
      # /// 16 --> 8 /////
      # int32_t  in[160]
      # int16_t out[80]
      self.down_by_2_int_to_short(temp_mem, 160, output, state.s_16_8)
    end
  end
end
