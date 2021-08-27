module WebrtcAudio
  module Vad
    # Constants used in LogOfEnergy().
    def self.kLogConst : Int16
      return 24660_i16
    end

    def self.kLogEnergyIntPart : Int16
      return 14336_i16
    end

    # Coefficients used by HighPassFilter, Q14.
    def self.kHpZeroCoefs : Array(Int16)
      return [6631_i16, -13262_i16, 6631_i16]
    end

    def self.kHpPoleCoefs : Array(Int16)
      return [16384_i16, -7756_i16, 5620_i16]
    end

    # Allpass filter coefficients, upper and lower, in Q15.
    # Upper: 0.64, Lower: 0.17
    def self.kAllPassCoefsQ15 : Array(Int16)
      return [20972_i16, 5571_i16]
    end

    # Adjustment for division with two in SplitFilter.
    def self.kOffsetVector : Array(Int16)
      return [368_i16, 368_i16, 272_i16, 176_i16, 176_i16, 176_i16]
    end

    # High pass filtering, with a cut-off frequency at 80 Hz, if the |data_in| is
    # sampled at 500 Hz.
    #
    # - data_in      [i]   : Input audio data sampled at 500 Hz.
    # - data_length  [i]   : Length of input and output data.
    # - filter_state [i/o] : State of the filter.
    # - data_out     [o]   : Output audio data in the frequency interval
    #                        80 - 250 Hz.
    def self.high_pass_filter(data_in : Slice(Int16), data_length : Int32, filter_state : Array(Int16), data_out : Slice(Int16)) : Void
      inPtr = 0
      outPtr = 0
      tmp32 = 0_i32
      # The sum of the absolute values of the impulse response:
      # The zero/pole-filter has a max amplification of a single sample of: 1.4546
      # Impulse response: 0.4047 -0.6179 -0.0266  0.1993  0.1035  -0.0194
      # The all-zero section has a max amplification of a single sample of: 1.6189
      # Impulse response: 0.4047 -0.8094  0.4047  0   00
      # The all-pole section has a max amplification of a single sample of: 1.9931
      # Impulse response: 1.0000  0.4734 -0.1189 -0.2187 -0.0627   0.04532
      (0...data_length).each { |i|
        # All-zero section (filter coefficients in Q14).
        tmp32 = (kHpZeroCoefs()[0].to_i32 &* data_in[inPtr].to_i32).to_i32!
        tmp32 = (tmp32.to_i32 + kHpZeroCoefs()[1].to_i32 * filter_state[0].to_i32).to_i32
        tmp32 = (tmp32.to_i32 + kHpZeroCoefs()[2].to_i32 * filter_state[1].to_i32).to_i32
        filter_state[1] = filter_state[0]
        filter_state[0] = data_in[inPtr]
        inPtr += 1
        # All-pole section (filter coefficients in Q14).
        tmp32 = (tmp32.to_i32 - kHpPoleCoefs()[1].to_i32 &* filter_state[2].to_i32).to_i32!
        tmp32 = (tmp32.to_i32 - kHpPoleCoefs()[2].to_i32 &* filter_state[3].to_i32).to_i32!

        filter_state[3] = filter_state[2]
        filter_state[2] = (tmp32.to_i32 >> 14).to_i16!
        data_out[outPtr] = filter_state[2]
        outPtr += 1
      }
    end

    # All pass filtering of |data_in|, used before splitting the signal into two
    # frequency bands (low pass vs high pass).
    # Note that |data_in| and |data_out| can NOT correspond to the same address.
    #
    # - data_in            [i]   : Input audio signal given in Q0.
    # - data_length        [i]   : Length of input and output data.
    # - filter_coefficient [i]   : Given in Q15.
    # - filter_state       [i/o] : State of the filter given in Q(-1).
    # - data_out           [o]   : Output audio signal given in Q(-1).
    def self.all_pass_filter(data_in : Slice(Int16), data_length : Int32, filter_coefficient : Int16, filter_state : Pointer(Int16), data_out : Slice(Int16)) : Void
      # The filter can only cause overflow (in the w16 output variable)
      # if more than 4 consecutive input numbers are of maximum value and
      # has the the same sign as the impulse responses first taps.
      # First 6 taps of the impulse response:
      # 0.6399 0.5905 -0.3779 0.2418 -0.1547 0.0990
      tmp16 = 0_i16
      tmp32 = 0_i32
      inPtr = 0
      outPtr = 0
      state32 = ((filter_state.value.to_i32!) * (1 << 16)).to_i32! # Q15
      (0...data_length).each { |i|
        tmp32 = (state32.to_i32! &+ (filter_coefficient.to_i32! &* (data_in[inPtr]).to_i32!)).to_i32!
        tmp16 = (tmp32.to_i32 >> 16).to_i16! # Q(-1)
        data_out[outPtr] = tmp16
        outPtr += 1
        state32 = ((data_in[inPtr].to_i32! &* (1 << 14)) &- filter_coefficient.to_i32 &* tmp16.to_i32).to_i32! # Q14
        state32 = (state32 &* 2).to_i32! # Q15.
        inPtr += 2
      }
      filter_state.value = (state32.to_i32 >> 16).to_i16! # Q(-1)
    end

    # Splits |data_in| into |hp_data_out| and |lp_data_out| corresponding to
    # an upper (high pass) part and a lower (low pass) part respectively.
    #
    # - data_in      [i]   : Input audio data to be split into two frequency bands.
    # - data_length  [i]   : Length of |data_in|.
    # - upper_state  [i/o] : State of the upper filter, given in Q(-1).
    # - lower_state  [i/o] : State of the lower filter, given in Q(-1).
    # - hp_data_out  [o]   : Output audio data of the upper half of the spectrum.
    #                        The length is |data_length| / 2.
    # - lp_data_out  [o]   : Output audio data of the lower half of the spectrum.
    #                        The length is |data_length| / 2.

    def self.split_filter(data_in : Slice(Int16), data_length : Int32, upper_state : Pointer(Int16), lower_state : Pointer(Int16), hp_data_out : Array(Int16), lp_data_out : Array(Int16)) : Void
      half_length = data_length >> 1 # Downsampling by 2.
      tmp_out = 0_i16
      # All-pass filtering upper branch.
      hp_data_out_slice = Slice(Int16).new(hp_data_out.to_unsafe, hp_data_out.size)
      lp_data_out_slice = Slice(Int16).new(lp_data_out.to_unsafe, lp_data_out.size)
      self.all_pass_filter(data_in, half_length, kAllPassCoefsQ15()[0], upper_state, hp_data_out_slice)
      # All-pass filtering lower branch.
      self.all_pass_filter(data_in + 1, half_length, kAllPassCoefsQ15()[1], lower_state, lp_data_out_slice)
      houtPtr = 0
      loutPtr = 0
      # Make LP and HP signals.
      (0...half_length).each { |i|
        tmp_out = hp_data_out[houtPtr]
        hp_data_out[houtPtr] = (hp_data_out[houtPtr] &- lp_data_out[loutPtr]).to_i16!
        houtPtr += 1
        lp_data_out[loutPtr] = (lp_data_out[loutPtr] &+ tmp_out).to_i16!
        loutPtr += 1
      }
    end

    # Calculates the energy of |data_in| in dB, and also updates an overall
    # |total_energy| if necessary.
    #
    # - data_in      [i]   : Input audio data for energy calculation.
    # - data_length  [i]   : Length of input data.
    # - offset       [i]   : Offset value added to |log_energy|.
    # - total_energy [i/o] : An external energy updated with the energy of
    #                        |data_in|.
    #                        NOTE: |total_energy| is only updated if
    #                        |total_energy| <= |kMinEnergy|.
    # - log_energy   [o]   : 10 * log10("energy of |data_in|") given in Q4.
    def self.log_of_energy(data_in : Slice(Int16), data_length : Int32, offset : Int16, total_energy : Pointer(Int16), log_energy : Array(Int16), log_energy_index : Int32) : Void
      # |tot_rshifts| accumulates the number of right shifts performed on |energy|.
      tot_rshifts = 0_i32
      # The |energy| will be normalized to 15 bits. We use unsigned integer because
      # we eventually will mask out the fractional part.
      energy = 0_u32
      rc = WebrtcAudio::SignalProcessing.energy(data_in, data_length)
      energy = rc[0]
      tot_rshifts = rc[1]

      if (energy != 0)
        # By construction, normalizing to 15 bits is equivalent with 17 leading
        # zeros of an unsigned 32 bit value.
        normalizing_rshifts = (17 - (energy == 0 ? 32 : energy.leading_zeros_count))
        # In a 15 bit representation the leading bit is 2^14. log2(2^14) in Q10 is
        # (14 << 10), which is what we initialize |log2_energy| with. For a more
        # detailed derivations, see below.
        log2_energy = kLogEnergyIntPart()
        tot_rshifts += normalizing_rshifts
        # Normalize |energy| to 15 bits.
        # |tot_rshifts| is now the total number of right shifts performed on
        # |energy| after normalization. This means that |energy| is in
        # Q(-tot_rshifts).
        if normalizing_rshifts < 0
          energy = (energy << -normalizing_rshifts).to_i32!
        else
          energy = (energy >> normalizing_rshifts).to_i32!
        end
        # Calculate the energy of |data_in| in dB, in Q4.
        #
        # 10 * log10("true energy") in Q4 = 2^4 * 10 * log10("true energy") =
        # 160 * log10(|energy| * 2^|tot_rshifts|) =
        # 160 * log10(2) * log2(|energy| * 2^|tot_rshifts|) =
        # 160 * log10(2) * (log2(|energy|) + log2(2^|tot_rshifts|)) =
        # (160 * log10(2)) * (log2(|energy|) + |tot_rshifts|) =
        # |kLogConst| * (|log2_energy| + |tot_rshifts|)
        #
        # We know by construction that |energy| is normalized to 15 bits. Hence,
        # |energy| = 2^14 + frac_Q15, where frac_Q15 is a fractional part in Q15.
        # Further, we'd like |log2_energy| in Q10
        # log2(|energy|) in Q10 = 2^10 * log2(2^14 + frac_Q15) =
        # 2^10 * log2(2^14 * (1 + frac_Q15 * 2^-14)) =
        # 2^10 * (14 + log2(1 + frac_Q15 * 2^-14)) ~=
        # (14 << 10) + 2^10 * (frac_Q15 * 2^-14) =
        # (14 << 10) + (frac_Q15 * 2^-4) = (14 << 10) + (frac_Q15 >> 4)
        #
        # Note that frac_Q15 = (|energy| & 0x00003FFF)
        # Calculate and add the fractional part to |log2_energy|.
        log2_energy += ((energy & 0x00003FFF) >> 4).to_i16
        # |kLogConst| is in Q9, |log2_energy| in Q10 and |tot_rshifts| in Q0.
        # Note that we in our derivation above have accounted for an output in Q4.
        ax = (((kLogConst().to_i32 * log2_energy)) >> 19).to_i32
        bx = (((tot_rshifts.to_i32 * kLogConst())) >> 9).to_i32
        fx = (ax + bx).to_i16!
        log_energy_t = fx
        log_energy[log_energy_index] = fx
        if (log_energy[log_energy_index] < 0)
          log_energy[log_energy_index] = 0
        end
      else
        log_energy[log_energy_index] = offset
        return
      end
      log_energy[log_energy_index] += offset
      # Update the approximate |total_energy| with the energy of |data_in|, if
      # |total_energy| has not exceeded |kMinEnergy|. |total_energy| is used as an
      # energy indicator in WebRtcVad_GmmProbability() in vad_core.c.
      if (total_energy.value <= WebrtcAudio.kMinEnergy)
        if (tot_rshifts >= 0)
          # We know by construction that the |energy| > |kMinEnergy| in Q0, so add
          # an arbitrary value such that |total_energy| exceeds |kMinEnergy|.
          total_energy.value = total_energy.value + WebrtcAudio.kMinEnergy + 1
        else
          # By construction |energy| is represented by 15 bits, hence any number of
          # right shifted |energy| will fit in an int16_t. In addition, adding the
          # value to |total_energy| is wrap around safe as long as
          # |kMinEnergy| < 8192.
          total_energy.value = total_energy.value + (energy.to_i32 >> -tot_rshifts.to_i32).to_i16! # Q0.
        end
      end
    end

    def self.calculate_features(inst : VadInstance, data_in : Slice(Int16), data_length : Int32, features : Array(Int16)) : Int16
      total_energy = 0_i16
      # We expect |data_length| to be 80, 160 or 240 samples, which corresponds to
      # 10, 20 or 30 ms in 8 kHz. Therefore, the intermediate downsampled data will
      # have at most 120 samples after the first split and at most 60 samples after
      # the second split.
      hp_120 = Array(Int16).new(120, 0)
      hp_120_slice = Slice(Int16).new(hp_120.to_unsafe, 120)
      #
      lp_120 = Array(Int16).new(120, 0)
      lp_120_slice = Slice(Int16).new(lp_120.to_unsafe, 120)
      #
      hp_60 = Array(Int16).new(60, 0)
      hp_60_slice = Slice(Int16).new(hp_60.to_unsafe, 60)
      #
      lp_60 = Array(Int16).new(60, 0)
      lp_60_slice = Slice(Int16).new(lp_60.to_unsafe, 60)

      half_data_length = data_length >> 1
      length = half_data_length # |data_length| / 2, corresponds to
      # bandwidth = 2000 Hz after downsampling.
      # Initialize variables for the first SplitFilter().
      frequency_band = 0_i32
      # Split at 2000 Hz and downsample.
      upper_freq = inst.upper_state[frequency_band]
      upper_pointer = pointerof(upper_freq)
      lower_freq = inst.lower_state[frequency_band]
      lower_pointer = pointerof(lower_freq)
      energy_pointer = pointerof(total_energy)
      self.split_filter(data_in, data_length, upper_pointer, lower_pointer, hp_120, lp_120)
      inst.upper_state[frequency_band] = upper_pointer.value
      inst.lower_state[frequency_band] = lower_pointer.value

      # For the upper band (2000 Hz - 4000 Hz) split at 3000 Hz and downsample.
      frequency_band = 1
      upper_freq = inst.upper_state[frequency_band]
      upper_pointer = pointerof(upper_freq)
      lower_freq = inst.lower_state[frequency_band]
      lower_pointer = pointerof(lower_freq)

      self.split_filter(hp_120_slice, length, upper_pointer, lower_pointer, hp_60, lp_60)
      inst.upper_state[frequency_band] = upper_pointer.value
      inst.lower_state[frequency_band] = lower_pointer.value
      # Energy in 3000 Hz - 4000 Hz.
      length /= 2 # |data_length| / 4 <=> bandwidth = 1000 Hz.


      self.log_of_energy(hp_60_slice, length.round.to_i32, kOffsetVector()[5], energy_pointer, features, 5)
      # Energy in 2000 Hz - 3000 Hz.
      self.log_of_energy(lp_60_slice, length.round.to_i32, kOffsetVector()[4], energy_pointer, features, 4)
      # For the lower band (0 Hz - 2000 Hz) split at 1000 Hz and downsample.
      frequency_band = 2
      upper_freq = inst.upper_state[frequency_band]
      upper_pointer = pointerof(upper_freq)
      lower_freq = inst.lower_state[frequency_band]
      lower_pointer = pointerof(lower_freq)
      length = half_data_length # |data_length| / 2 <=> bandwidth = 2000 Hz.

      self.split_filter(lp_120_slice, length.round.to_i32, upper_pointer, lower_pointer, hp_60, lp_60)
      inst.upper_state[frequency_band] = upper_pointer.value
      inst.lower_state[frequency_band] = lower_pointer.value
      # Energy in 1000 Hz - 2000 Hz.
      length /= 2 # |data_length| / 4 <=> bandwidth = 1000 Hz.
      self.log_of_energy(hp_60_slice, length.round.to_i32, kOffsetVector()[3], energy_pointer, features, 3)
      # For the lower band (0 Hz - 1000 Hz) split at 500 Hz and downsample.
      frequency_band = 3

      upper_freq = inst.upper_state[frequency_band]
      upper_pointer = pointerof(upper_freq)
      lower_freq = inst.lower_state[frequency_band]
      lower_pointer = pointerof(lower_freq)
      # length = half_data_length # |data_length| / 2 <=> bandwidth = 2000 Hz.

      self.split_filter(lp_60_slice, length.round.to_i32, upper_pointer, lower_pointer, hp_120, lp_120)
      inst.upper_state[frequency_band] = upper_pointer.value
      inst.lower_state[frequency_band] = lower_pointer.value
      # Energy in 500 Hz - 1000 Hz.
      length /= 2 # |data_length| / 8 <=> bandwidth = 500 Hz.
      self.log_of_energy(hp_120_slice, length.round.to_i32, kOffsetVector()[2], energy_pointer, features, 2)
      # For the lower band (0 Hz - 500 Hz) split at 250 Hz and downsample.
      frequency_band = 4

      upper_freq = inst.upper_state[frequency_band]
      upper_pointer = pointerof(upper_freq)
      lower_freq = inst.lower_state[frequency_band]
      lower_pointer = pointerof(lower_freq)
      # length = half_data_length # |data_length| / 2 <=> bandwidth = 2000 Hz.

      self.split_filter(lp_120_slice, length.round.to_i32, upper_pointer, lower_pointer, hp_60, lp_60)
      inst.upper_state[frequency_band] = upper_pointer.value
      inst.lower_state[frequency_band] = lower_pointer.value
      # Energy in 250 Hz - 500 Hz.
      length /= 2 # |data_length| / 16 <=> bandwidth = 250 Hz.
      self.log_of_energy(hp_60_slice, length.round.to_i32, kOffsetVector()[1], energy_pointer, features, 1)
      # Remove 0 Hz - 80 Hz, by high pass filtering the lower band.
      m = inst.hp_filter_state
      self.high_pass_filter(lp_60_slice, length.round.to_i32, m, hp_120_slice)
      # Energy in 80 Hz - 250 Hz.
      self.log_of_energy(hp_120_slice, length.round.to_i32, kOffsetVector()[0], energy_pointer, features, 0)
      return total_energy
    end
  end
end
