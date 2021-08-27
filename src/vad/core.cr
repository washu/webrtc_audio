require "../models/*"
require "../signal_processing/*"

module WebrtcAudio
  module Vad
    def self.kSpectrumWeight : Array(Int16)
      return [6_i16, 8_i16, 10_i16, 12_i16, 14_i16, 16_i16]
    end

    def self.kNoiseUpdateConst : Int16
      return 655_i16
    end

    def self.kSpeechUpdateConst : Int16
      return 6554_i16
    end

    def self.kBackEta : Int16
      return 154_i16
    end

    def self.kMinimumDifference : Array(Int16)
      return [544_i16, 544_i16, 576_i16, 576_i16, 576_i16, 576_i16]
    end

    def self.kMaximumSpeech : Array(Int16)
      return [11392_i16, 11392_i16, 11520_i16, 11520_i16, 11520_i16, 11520_i16]
    end

    def self.kMinimumMean : Array(Int16)
      return [640_i16, 768_i16]
    end

    def self.kMaximumNoise : Array(Int16)
      return [9216_i16, 9088_i16, 8960_i16, 8832_i16, 8704_i16, 8576_i16]
    end

    def self.kNoiseDataWeights : Array(Int16)
      return [34_i16, 62_i16, 72_i16, 66_i16, 53_i16, 25_i16, 94_i16, 66_i16, 56_i16, 62_i16, 75_i16, 103_i16]
    end

    def self.kSpeechDataWeights : Array(Int16)
      return [48_i16, 82_i16, 45_i16, 87_i16, 50_i16, 47_i16, 80_i16, 46_i16, 83_i16, 41_i16, 78_i16, 81_i16]
    end

    def self.kNoiseDataMeans : Array(Int16)
      return [6738_i16, 4892_i16, 7065_i16, 6715_i16, 6771_i16, 3369_i16, 7646_i16, 3863_i16, 7820_i16, 7266_i16, 5020_i16, 4362_i16]
    end

    def self.kSpeechDataMeans : Array(Int16)
      return [8306_i16, 10085_i16, 10078_i16, 11823_i16, 11843_i16, 6309_i16, 9473_i16, 9571_i16, 10879_i16, 7581_i16, 8180_i16, 7483_i16]
    end

    def self.kNoiseDataStds : Array(Int16)
      return [378_i16, 1064_i16, 493_i16, 582_i16, 688_i16, 593_i16, 474_i16, 697_i16, 475_i16, 688_i16, 421_i16, 455_i16]
    end

    def self.kSpeechDataStds : Array(Int16)
      return [555_i16, 505_i16, 567_i16, 524_i16, 585_i16, 1231_i16, 509_i16, 828_i16, 492_i16, 1540_i16, 1079_i16, 850_i16]
    end

    def self.kMaxSpeechFrames : Int16
      return 6_i16
    end

    def self.kMinStd : Int16
      return 384_i16
    end

    def self.kDefaultMode : Int16
      return 0_i16
    end

    def self.kInitCheck : Int32
      return 42
    end

    def self.kOverHangMax1Q : Array(Int16)
      return [8_i16, 4_i16, 3_i16]
    end

    def self.kOverHangMax2Q : Array(Int16)
      return [14_i16, 7_i16, 5_i16]
    end

    def self.kLocalThresholdQ : Array(Int16)
      return [24_i16, 21_i16, 24_i16]
    end

    def self.kGlobalThresholdQ : Array(Int16)
      return [57_i16, 48_i16, 57_i16]
    end

    # Mode 1, Low bitrate.
    def self.kOverHangMax1LBR : Array(Int16)
      return [8_i16, 4_i16, 3_i16]
    end

    def self.kOverHangMax2LBR : Array(Int16)
      return [14_i16, 7_i16, 5_i16]
    end

    def self.kLocalThresholdLBR : Array(Int16)
      return [37_i16, 32_i16, 37_i16]
    end

    def self.kGlobalThresholdLBR : Array(Int16)
      return [100_i16, 80_i16, 100_i16]
    end

    # Mode 2, Aggressive.
    def self.kOverHangMax1AGG : Array(Int16)
      return [6_i16, 3_i16, 2_i16]
    end

    def self.kOverHangMax2AGG : Array(Int16)
      return [9_i16, 5_i16, 3_i16]
    end

    def self.kLocalThresholdAGG : Array(Int16)
      return [82_i16, 78_i16, 82_i16]
    end

    def self.kGlobalThresholdAGG : Array(Int16)
      return [285_i16, 260_i16, 285_i16]
    end

    # Mode 3, Very aggressive.
    def self.kOverHangMax1VAG : Array(Int16)
      return [6_i16, 3_i16, 2_i16]
    end

    def self.kOverHangMax2VAG : Array(Int16)
      return [9_i16, 5_i16, 3_i16]
    end

    def self.kLocalThresholdVAG : Array(Int16)
      return [94_i16, 94_i16, 94_i16]
    end

    def self.kGlobalThresholdVAG : Array(Int16)
      return [1100_i16, 1050_i16, 1100_i16]
    end

    # Calculates the weighted average w.r.t. number of Gaussians. The |data| are
    # updated with an |offset| before averaging.
    #
    # - data     [i/o] : Data to average.
    # - offset   [i]   : An offset added to |data|.
    # - weights  [i]   : Weights used for averaging.
    #
    # returns          : The weighted average.
    def self.weighted_average(data : Slice(Int16), offset : Int16, weights : Array(Int16)) : Int32
      weighted_average = 0_i32
      (0...WebrtcAudio.kNumGaussians).each { |k|
        data[k * WebrtcAudio.kNumChannels] += offset
        weighted_average = (weighted_average.to_i32! &+ data[k &* WebrtcAudio.kNumChannels].to_i32! &* weights[k * WebrtcAudio.kNumChannels].to_i32!).to_i32!
      }
      return weighted_average.to_i32!
    end

    # An s16 x s32 -> s32 multiplication that's allowed to overflow. (It's still
    # undefined behavior, so not a good idea; this just makes UBSan ignore the
    # violation, so that our old code can continue to do what it's always been
    # doing.)
    def self.overflowing_muls16_by_s32_to_s32(a : Int16, b : Int32) : Int32
      (a.to_i32 &* b.to_i32).to_i32!
    end

    # Calculates the probabilities for both speech and background noise using
    # Gaussian Mixture Models (GMM). A hypothesis-test is performed to decide which
    # type of signal is most probable.
    #
    # - self           [i/o] : Pointer to VAD instance
    # - features       [i]   : Feature vector of length |kNumChannels|
    #                          = log10(energy in frequency band)
    # - total_power    [i]   : Total power in audio frame.
    # - frame_length   [i]   : Number of input samples
    #
    # - returns              : the VAD decision (0 - noise, 1 - speech).
    def self.gmm_probability(inst : VadInstance, features : Array(Int16), total_power : Int16, frame_length : Int32) : Int16
      channel = k = 0_i32
      feature_minimum = 0_i16
      h0 = h1 = 0_i16
      log_likelihood_ratio = 0_i16
      vadflag = 0
      shifts_h0 = shifts_h1 = 0_i16
      tmp_s16 = tmp1_s16 = tmp2_s16 = 0_i16
      diff = 0_i16
      gaussian = 0_i32
      nmk = nmk2 = nmk3 = smk = smk2 = nsk = ssk = 0_i16
      delt = ndelt = 0_i16
      maxspe = maxmu = 0_i16
      deltaN = Array(Int16).new(WebrtcAudio.kTableSize, 0)
      deltaN_slice = Slice(Int16).new(deltaN.to_unsafe, WebrtcAudio.kTableSize)

      deltaS = Array(Int16).new(WebrtcAudio.kTableSize, 0)
      deltaS_slice = Slice(Int16).new(deltaS.to_unsafe, WebrtcAudio.kTableSize)

      ngprvec = Array(Int16).new(WebrtcAudio.kTableSize, 0) # Conditional probability = 0.
      sgprvec = Array(Int16).new(WebrtcAudio.kTableSize, 0) # Conditional probability = 0.

      h0_test = h1_test = 0_i32
      tmp1_s32 = tmp2_s32 = 0_i32
      sum_log_likelihood_ratios = 0_i32
      noise_global_mean = speech_global_mean = 0_i32
      noise_probability = Array(Int32).new(WebrtcAudio.kNumGaussians, 0)
      speech_probability = Array(Int32).new(WebrtcAudio.kNumGaussians, 0)
      overhead1 = overhead2 = individualTest = totalTest = 0_i16
      # Set various thresholds based on frame lengths (80, 160 or 240 samples).
      if (frame_length == 80)
        overhead1 = inst.over_hang_max_1[0]
        overhead2 = inst.over_hang_max_2[0]
        individualTest = inst.individual[0]
        totalTest = inst.total[0]
      elsif (frame_length == 160)
        overhead1 = inst.over_hang_max_1[1]
        overhead2 = inst.over_hang_max_2[1]
        individualTest = inst.individual[1]
        totalTest = inst.total[1]
      else
        overhead1 = inst.over_hang_max_1[2]
        overhead2 = inst.over_hang_max_2[2]
        individualTest = inst.individual[2]
        totalTest = inst.total[2]
      end
      if (total_power > WebrtcAudio.kMinEnergy)
        # The signal power of current frame is large enough for processing. The
        # processing consists of two parts:
        # 1) Calculating the likelihood of speech and thereby a VAD decision.
        # 2) Updating the underlying model, w.r.t., the decision made.

        # The detection scheme is an LRT with hypothesis
        # H0: Noise
        # H1: Speech
        #
        # We combine a global LRT with local tests, for each frequency sub-band,
        # here defined as |channel|.
        (0...WebrtcAudio.kNumChannels).each { |channel|
          # For each channel we model the probability with a GMM consisting of
          # |kNumGaussians|, with different means and standard deviations depending
          # on H0 or H1.
          h0_test = 0
          h1_test = 0
          (0...WebrtcAudio.kNumGaussians).each { |k|
            gaussian = channel + k * WebrtcAudio.kNumChannels
            # Probability under H0, that is, probability of frame being noise.
            # Value given in Q27 = Q7 * Q20.
            tmp1_s32 = self.gaussian_probability(features[channel], inst.noise_means[gaussian], inst.noise_stds[gaussian], deltaN_slice + gaussian)
            noise_probability[k] = (kNoiseDataWeights()[gaussian].to_i32 &* tmp1_s32.to_i32).to_i32!
            h0_test += noise_probability[k].to_i32! # Q27
            # Probability under H1, that is, probability of frame being speech.
            # Value given in Q27 = Q7 * Q20.
            tmp1_s32 = self.gaussian_probability(features[channel], inst.speech_means[gaussian], inst.speech_stds[gaussian], deltaS_slice + gaussian)
            speech_probability[k] = (kSpeechDataWeights()[gaussian].to_i32 &* tmp1_s32.to_i32).to_i32!
            h1_test += speech_probability[k].to_i32! # Q27
          }
          # Calculate the log likelihood ratio: log2(Pr{X|H1} / Pr{X|H1}).
          # Approximation:
          # log2(Pr{X|H1} / Pr{X|H1}) = log2(Pr{X|H1}*2^Q) - log2(Pr{X|H1}*2^Q)
          #                           = log2(h1_test) - log2(h0_test)
          #                           = log2(2^(31-shifts_h1)*(1+b1))
          #                             - log2(2^(31-shifts_h0)*(1+b0))
          #                           = shifts_h0 - shifts_h1
          #                             + log2(1+b1) - log2(1+b0)
          #                          ~= shifts_h0 - shifts_h1
          # Note that b0 and b1 are values less than 1, hence, 0 <= log2(1+b0) < 1.
          # Further, b0 and b1 are independent and on the average the two terms
          # cancel.
          shifts_h0 = WebrtcAudio.norm_w32(h0_test)
          shifts_h1 = WebrtcAudio.norm_w32(h1_test)
          if (h0_test == 0)
            shifts_h0 = 31_i16
          end
          if (h1_test == 0)
            shifts_h1 = 31_i16
          end
          log_likelihood_ratio = shifts_h0 &- shifts_h1
          # Update |sum_log_likelihood_ratios| with spectrum weighting. This is
          # used for the global VAD decision.
          sum_log_likelihood_ratios += (log_likelihood_ratio * kSpectrumWeight()[channel]).to_i32!
          # Local VAD decision.
          if ((log_likelihood_ratio * 4) > individualTest)
            vadflag = 1
          end
          # TODO(bjornv): The conditional probabilities below are applied on the
          # hard coded number of Gaussians set to two. Find a way to generalize.
          # Calculate local noise probabilities used later when updating the GMM.
          h0 = (h0_test >> 12).to_i16! # Q15
          if (h0 > 0)
            # High probability of noise. Assign conditional probabilities for each
            # Gaussian in the GMM.
            tmp1_s32 = (noise_probability[0] & 0xFFFFF000) << 2                                # Q29
            ngprvec[channel] = WebrtcAudio::SignalProcessing.div_w32_w16(tmp1_s32, h0).to_i16! # Q14
            ngprvec[channel + WebrtcAudio.kNumChannels] = (16384 - ngprvec[channel]).to_i16!
          else
            # Low noise probability. Assign conditional probability 1 to the first
            # Gaussian and 0 to the rest (which is already set at initialization).
            ngprvec[channel] = 16384_i16
          end
          # Calculate local speech probabilities used later when updating the GMM.
          h1 = (h1_test >> 12).to_i16! # Q15
          if (h1 > 0)
            # High probability of speech. Assign conditional probabilities for each
            # Gaussian in the GMM. Otherwise use the initialized values, i.e., 0.
            tmp1_s32 = (speech_probability[0] & 0xFFFFF000) << 2                               # Q29
            sgprvec[channel] = WebrtcAudio::SignalProcessing.div_w32_w16(tmp1_s32, h1).to_i16! # Q14
            sgprvec[channel + WebrtcAudio.kNumChannels] = (16384 - sgprvec[channel]).to_i16!
          end
        }

        # Make a global VAD decision.
        vadflag = (vadflag.to_i32 | ((sum_log_likelihood_ratios >= totalTest) ? 1 : 0)).to_i32!
        # Update the model parameters.
        maxspe = 12800
        (0...WebrtcAudio.kNumChannels).each { |channel|
          # Get minimum value in past which is used for long term correction in Q4.
          feature_minimum = self.find_minimum(inst, features[channel], channel)
          # Compute the "global" mean, that is the sum of the two means weighted.
          # noice means to slice
          means_slice = Slice(Int16).new(inst.noise_means.to_unsafe, inst.noise_means.size)
          sArray = kNoiseDataWeights()[channel, 12]
          noise_global_mean = self.weighted_average(means_slice + channel, 0, sArray)
          tmp1_s16 = (noise_global_mean >> 6).to_i16! # Q8
          (0...WebrtcAudio.kNumGaussians).each { |k|
            gaussian = channel + k * WebrtcAudio.kNumChannels

            nmk = inst.noise_means[gaussian]
            smk = inst.speech_means[gaussian]
            nsk = inst.noise_stds[gaussian]
            ssk = inst.speech_stds[gaussian]
            # Update noise mean vector if the frame consists of noise only.
            nmk2 = nmk
            if !vadflag
              # deltaN = (x-mu)/sigma^2
              # ngprvec[k] = |noise_probability[k]| /
              #   (|noise_probability[0]| + |noise_probability[1]|)
              # (Q14 * Q11 >> 11) = Q14.
              delt = ((ngprvec[gaussian] &* deltaN[gaussian]) >> 11).to_i16!
              # Q7 + (Q14 * Q15 >> 22) = Q7.
              puts "Q7 + (Q14 * Q15 >> 22) = Q7 (#{nmk} + (#{delt} * #{kNoiseUpdateConst}) >> 22)"
              nmk2 = (nmk.to_i32 + ((delt.to_i32 &* kNoiseUpdateConst).to_i32 >> 22).to_i16!).to_i16!
            end
            puts "Noise update #{nmk} #{smk} #{nsk} #{ssk}, #{delt} #{nmk2}"
            # Long term correction of the noise mean.
            # Q8 - Q8 = Q8.
            ndelt = ((feature_minimum.to_i32 << 4).to_i32! - tmp1_s16.to_i32!).to_i16!
            # Q7 + (Q8 * Q8) >> 9 = Q7.
            puts "#{nmk2} + (#{ndelt} * #{kBackEta}) >> 9 OR #{(ndelt.to_i32 &* kBackEta().to_i32)} or  #{(ndelt.to_i32 &* kBackEta().to_i32) >> 9}"
            nmk3 = (nmk2 + ((ndelt.to_i32 &* kBackEta().to_i32) >> 9).to_i16!)
            puts "Q8-Q7 #{ndelt} #{nmk3} (fmin: #{feature_minimum.to_i32} kb:#{kBackEta}) ts:#{tmp1_s16}"
            # Control that the noise mean does not drift to much.
            tmp_s16 = ((k &+ 5) << 7).to_i16!
            if (nmk3 < tmp_s16)
              nmk3 = tmp_s16
            end
            puts "tmp16 drift 1 #{tmp_s16} #{nmk3}"
            tmp_s16 = ((72 &+ k &- channel) << 7).to_i16!
            if (nmk3 > tmp_s16)
              nmk3 = tmp_s16
            end
            puts "tmp16 drift 2 #{tmp_s16} #{nmk3}"
            inst.noise_means[gaussian] = nmk3

            if (vadflag)
              # Update speech mean vector:
              # |deltaS| = (x-mu)/sigma^2
              # sgprvec[k] = |speech_probability[k]| /
              #   (|speech_probability[0]| + |speech_probability[1]|)
              # (Q14 * Q11) >> 11 = Q14.
              delt = ((sgprvec[gaussian].to_i32 &* deltaS[gaussian].to_i32) >> 11).to_i16!
              # Q14 * Q15 >> 21 = Q8.
              tmp_s16 = ((delt.to_i32! &* kSpeechUpdateConst().to_i32!).to_i32! >> 21).to_i16!
              # Q7 + (Q8 >> 1) = Q7. With rounding.
              smk2 = smk + ((tmp_s16.to_i32 &+ 1) >> 1).to_i16!
              puts "Q14 #{delt} #{tmp_s16} #{smk2} (#{delt &* kSpeechUpdateConst})"
              # Control that the speech mean does not drift to much.
              maxmu = maxspe + 640
              if (smk2 < kMinimumMean()[k])
                smk2 = kMinimumMean()[k]
              end
              if (smk2 > maxmu)
                smk2 = maxmu
              end
              puts "Pre q7 #{smk2} #{maxmu}"
              inst.speech_means[gaussian] = smk2.to_i16 # Q7.

              # (Q7 >> 3) = Q4. With rounding.
              tmp_s16 = ((smk &+ 4) >> 3)
              puts "Q4 rounding #{tmp_s16}"

              tmp_s16 = features[channel] &- tmp_s16 # Q4
              puts "Q4 end #{tmp_s16} (#{features[channel]})"
              # (Q11 * Q4 >> 3) = Q12.
              tmp1_s32 = ((deltaS[gaussian].to_i32! &* tmp_s16.to_i32!).to_i32! >> 3).to_i32
              puts "Q12 #{tmp1_s32} (#{deltaS[gaussian]}) #{(deltaS[gaussian].to_i32! &* tmp_s16.to_i32!).to_i32!}"
              tmp2_s32 = (tmp1_s32 &- 4096).to_i32!
              puts "Q12 end #{tmp2_s32}"

              tmp_s16 = (sgprvec[gaussian].to_i32 >> 2).to_i16!
              puts "Q12 extra #{tmp_s16} (#{sgprvec[gaussian]})"
              # (Q14 >> 2) * Q12 = Q24.
              tmp1_s32 = (tmp_s16.to_i32! &* tmp2_s32.to_i32!).to_i32!
              puts "Q24 #{tmp1_s32}"
              tmp2_s32 = (tmp1_s32 >> 4).to_i32! # Q20
              puts "Q20 #{tmp2_s32}"
              # 0.1 * Q20 / Q7 = Q13.
              if (tmp2_s32 > 0)
                tmp_s16 = WebrtcAudio::SignalProcessing.div_w32_w16(tmp2_s32.to_i32, ssk * 10).to_i16!
              else
                tmp_s16 = WebrtcAudio::SignalProcessing.div_w32_w16(-tmp2_s32.to_i32, ssk * 10).to_i16!
                tmp_s16 = -tmp_s16
              end
              puts "Q13 #{tmp_s16}"
              # Divide by 4 giving an update factor of 0.025 (= 0.1 / 4).
              # Note that division by 4 equals shift by 2, hence,
              # (Q13 >> 8) = (Q13 >> 6) / 4 = Q7.
              tmp_s16 += 128 # Rounding.
              ssk += (tmp_s16 >> 8)
              if (ssk < kMinStd)
                ssk = kMinStd
              end
              puts "Q7 #{tmp_s16} #{ssk}"
              inst.speech_stds[gaussian] = ssk
            else
              # Update GMM variance vectors.
              # deltaN * (features[channel] - nmk) - 1
              # Q4 - (Q7 >> 3) = Q4.
              tmp_s16 = (features[channel] &- (nmk.to_i32 >> 3)).to_i16!
              puts "Q4 #{tmp_s16} (#{features[channel]} - #{nmk})"
              # (Q11 * Q4 >> 3) = Q12.
              tmp1_s32 = ((deltaN[gaussian] &* tmp_s16).to_i32 >> 3).to_i32!
              tmp1_s32 = (tmp1_s32 &- 4096).to_i32!
              puts "Q12 #{tmp1_s32} #{deltaN[gaussian]}"
              # (Q14 >> 2) * Q12 = Q24.
              tmp_s16 = ((ngprvec[gaussian] &+ 2).to_i32 >> 2).to_i16!
              tmp2_s32 = self.overflowing_muls16_by_s32_to_s32(tmp_s16.to_i16!, tmp1_s32.to_i32!)
              puts "Q24 #{tmp_s16} #{tmp1_s32} :#{tmp2_s32}"
              # Q20  * approx 0.001 (2^-10=0.0009766), hence,
              # (Q24 >> 14) = (Q24 >> 4) / 2^10 = Q20.
              tmp1_s32 = tmp2_s32 >> 14
              puts "Q20 #{tmp1_s32}"
              # Q20 / Q7 = Q13.
              if (tmp1_s32 > 0)
                tmp_s16 = WebrtcAudio::SignalProcessing.div_w32_w16(tmp1_s32, nsk).to_i16!
              else
                tmp_s16 = WebrtcAudio::SignalProcessing.div_w32_w16(-tmp1_s32, nsk).to_i16!
                tmp_s16 = -tmp_s16
              end
              puts "Q13 #tmp_s16)"
              tmp_s16 += 32       # Rounding
              nsk += tmp_s16 >> 6 # Q13 >> 6 = Q7.
              if (nsk < kMinStd)
                nsk = kMinStd
              end
              puts "Q7 #{tmp_s16},#{nsk}"
              inst.noise_stds[gaussian] = nsk
            end
          }

          # Separate models if they are too close.
          # |noise_global_mean| in Q14 (= Q7 * Q7).
          means_slice = Slice(Int16).new(inst.noise_means.to_unsafe, inst.noise_means.size)
          sArray = kNoiseDataWeights()[channel, 12]

          noise_global_mean = self.weighted_average(means_slice + channel, 0, sArray)

          means_slice = Slice(Int16).new(inst.speech_means.to_unsafe, inst.noise_means.size)
          sArray = kSpeechDataWeights()[channel, 12]
          # |speech_global_mean| in Q14 (= Q7 * Q7).
          speech_global_mean = self.weighted_average(means_slice + channel, 0, sArray)
          # |diff| = "global" speech mean - "global" noise mean.
          # (Q14 >> 9) - (Q14 >> 9) = Q5.
          diff = ((speech_global_mean >> 9).to_i16! &- (noise_global_mean >> 9).to_i16!).to_i16!
          puts "Q5 #{diff} #{(speech_global_mean >> 9).to_i16!} - #{(noise_global_mean >> 9).to_i16!}"
          if (diff < kMinimumDifference()[channel])
            tmp_s16 = kMinimumDifference()[channel] - diff
            # |tmp1_s16| = ~0.8 * (kMinimumDifference - diff) in Q7.
            # |tmp2_s16| = ~0.2 * (kMinimumDifference - diff) in Q7.
            tmp1_s16 = ((13 &* tmp_s16) >> 2).to_i16!
            tmp2_s16 = ((3 &* tmp_s16) >> 2).to_i16!
            # Move Gaussian means for speech model by |tmp1_s16| and update
            # |speech_global_mean|. Note that |inst.speech_means[channel]| is
            # changed after the call.
            mean_slice = Slice(Int16).new(inst.speech_means.to_unsafe, inst.noise_means.size)
            sArray = kSpeechDataWeights()[channel, 12]
            speech_global_mean = self.weighted_average(mean_slice + channel, tmp1_s16, sArray)
            # Move Gaussian means for noise model by -|tmp2_s16| and update
            # |noise_global_mean|. Note that |inst.noise_means[channel]| is
            # changed after the call.
            mean_slice = Slice(Int16).new(inst.noise_means.to_unsafe, inst.noise_means.size)
            sArray = kNoiseDataWeights()[channel, 12]
            noise_global_mean = self.weighted_average(mean_slice + channel, -tmp2_s16, sArray)
          end
          # Control that the speech & noise means do not drift to much.
          maxspe = kMaximumSpeech()[channel]
          tmp2_s16 = (speech_global_mean >> 7).to_i16!
          if (tmp2_s16 > maxspe)
            # Upper limit of speech model.
            tmp2_s16 -= maxspe
            (0...WebrtcAudio.kNumGaussians).each { |k|
              inst.speech_means[channel + k * WebrtcAudio.kNumChannels] -= tmp2_s16
            }
          end

          tmp2_s16 &= (noise_global_mean >> 7).to_i16!
          if (tmp2_s16 > kMaximumNoise()[channel])
            tmp2_s16 -= kMaximumNoise()[channel]
            (0...WebrtcAudio.kNumGaussians).each { |k|
              inst.noise_means[channel + k * WebrtcAudio.kNumChannels] -= tmp2_s16
            }
          end
        }
        inst.frame_count += 1
      end

      # Smooth with respect to transition hysteresis.
      if (!vadflag)
        if (inst.over_hang > 0)
          vadflag = 2 + inst.over_hang
          inst.over_hang -= 1
        end
        inst.num_of_speech = 0
      else
        inst.num_of_speech += 1
        if (inst.num_of_speech > kMaxSpeechFrames())
          inst.num_of_speech = kMaxSpeechFrames()
          inst.over_hang = overhead2
        else
          inst.over_hang = overhead1
        end
      end
      return vadflag.to_i16
    end

    # Initialize the VAD. Set aggressiveness mode to default value.
    def self.init_core(inst : VadInstance) : Int16
      # Initialization of general struct variables.
      inst.vad = 1 # Speech active (=1).
      inst.frame_count = 0
      inst.over_hang = 0
      inst.num_of_speech = 0
      inst.downsampling_filter_states.fill(0)
      # Initialization of 48 to 8 kHz downsampling.
      WebrtcAudio::SignalProcessing.reset_resample_48khz_to_8khz(inst.state_48_to_8)
      # Read initial PDF parameters.
      (0...WebrtcAudio.kTableSize).each { |i|
        inst.noise_means[i] = kNoiseDataMeans()[i]
        inst.speech_means[i] = kSpeechDataMeans()[i]
        inst.noise_stds[i] = kNoiseDataStds()[i]
        inst.speech_stds[i] = kSpeechDataStds()[i]
      }
      (0...(16 * WebrtcAudio.kNumChannels)).each { |i|
        inst.low_value_vector[i] = 10000
        inst.age_vector[i] = 0
      }
      # Initialize splitting filter states.
      inst.upper_state.fill(0)
      inst.lower_state.fill(0)

      # Initialize high pass filter states.
      inst.hp_filter_state.fill(0)
      # Initialize mean value memory, for WebRtcVad_FindMinimum().
      (0...WebrtcAudio.kNumChannels).each { |i|
        inst.median[i] = 1600
      }
      # Set aggressiveness mode to default (=|kDefaultMode|).
      if (self.set_mode_core(inst, kDefaultMode().to_i32) != 0)
        return -1_i16
      end
      inst.init_flag = kInitCheck()
      return 0_i16
    end

    # Set aggressiveness mode
    def self.set_mode_core(inst : VadInstance, mode : Int32) : Int32
      return_value = 0_i32
      case mode
      when 0
        # Quality mode.
        inst.over_hang_max_1 = kOverHangMax1Q().dup
        inst.over_hang_max_2 = kOverHangMax2Q().dup
        inst.individual = kLocalThresholdQ().dup
        inst.total = kGlobalThresholdQ().dup
      when 1
        # Low bitrate mode.
        inst.over_hang_max_1 = kOverHangMax1LBR().dup
        inst.over_hang_max_2 = kOverHangMax2LBR().dup
        inst.individual = kLocalThresholdLBR().dup
        inst.total = kGlobalThresholdLBR().dup
      when 2
        # Aggressive mode.
        inst.over_hang_max_1 = kOverHangMax1AGG().dup
        inst.over_hang_max_2 = kOverHangMax2AGG().dup
        inst.individual = kLocalThresholdAGG().dup
        inst.total = kGlobalThresholdAGG().dup
      when 3
        # Very aggressive mode.
        inst.over_hang_max_1 = kOverHangMax1VAG().dup
        inst.over_hang_max_2 = kOverHangMax2VAG().dup
        inst.individual = kLocalThresholdVAG().dup
        inst.total = kGlobalThresholdVAG().dup
      else
        return_value = -1
      end
      return return_value
    end

    # Calculate VAD decision by first extracting feature values and then calculate
    # probability for both speech and background noise.

    def self.calc_vad_48khz(inst : VadInstance, speech_frame : Slice(Int16), frame_length : Int32) : Int32
      vad = 0_i32
      speech_nb = Array(Int16).new(240, 0) # Downsampled speech frame: 480 samples (30ms in WB)
      speech_nb_slice = Slice(Int16).new(speech_nb.to_unsafe, 240)
      # |tmp_mem| is a temporary memory used by resample function, length is
      # frame length in 10 ms (480 samples) + 256 extra.
      tmp_mem = Array(Int32).new(480 + 256, 0) # Downsampled speech frame: 480 samples (30ms in WB)
      tmp_mem_slice = Slice(Int32).new(tmp_mem.to_unsafe, 480 + 256)
      kFrameLen10ms48khz = 480
      kFrameLen10ms8khz = 80
      num_10ms_frames = frame_length / kFrameLen10ms48khz
      (0...num_10ms_frames).each { |i|
        WebrtcAudio::SignalProcessing.resample_48khz_to_8khz(speech_frame, speech_nb_slice + (i * kFrameLen10ms8khz), inst.state_48_to_8, tmp_mem_slice)
      }
      # Do VAD on an 8 kHz signal
      vad = self.calc_vad_8khz(inst, speech_nb_slice, ((frame_length / 6).round).to_i32)
      return vad.to_i32
    end

    def self.calc_vad_32khz(inst : VadInstance, speech_frame : Slice(Int16), frame_length : Int32) : Int32
      vad = 0_i32
      speechWB = Array(Int16).new(480, 0) # Downsampled speech frame: 960 samples (30ms in SWB)
      speechWB_slice = Slice(Int16).new(speechWB.to_unsafe, 480)
      speechNB = Array(Int16).new(240, 0) # Downsampled speech frame: 480 samples (30ms in WB)
      speechNB_slice = Slice(Int16).new(speechNB.to_unsafe, 240)
      t_state = [inst.downsampling_filter_states[2], inst.downsampling_filter_states[3]]
      # Downsample signal 32->16->8 before doing VAD
      self.downsampling(speech_frame, speechWB_slice, t_state, frame_length)
      len = (frame_length / 2).round.to_i32
      inst.downsampling_filter_states[2] = t_state[0]
      inst.downsampling_filter_states[3] = t_state[1]
      self.downsampling(speechWB_slice, speechNB_slice, inst.downsampling_filter_states, len)
      len /= 2
      # Do VAD on an 8 kHz signal
      vad = self.calc_vad_8khz(inst, speechNB_slice, len.round.to_i32)
      return vad.to_i32
    end

    def self.calc_vad_16khz(inst : VadInstance, speech_frame : Slice(Int16), frame_length : Int32) : Int32
      vad = 0_i32
      speechNB = Array(Int16).new(240, 0) # Downsampled speech frame: 480 samples (30ms in WB)
      speechNB_slice = Slice(Int16).new(speechNB.to_unsafe, 240)
      # Wideband: Downsample signal before doing VAD
      self.downsampling(speech_frame, speechNB_slice, inst.downsampling_filter_states, frame_length)
      len = (frame_length / 2).round.to_i32
      vad = self.calc_vad_8khz(inst, speechNB_slice, len.to_i32)
      return vad.to_i32
    end

    def self.calc_vad_8khz(inst : VadInstance, speech_frame : Slice(Int16), frame_length : Int32) : Int32
      feature_vector = Array(Int16).new(WebrtcAudio.kNumChannels, 0)
      # Get power in the bands
      total_power = self.calculate_features(inst, speech_frame, frame_length, feature_vector)
      puts "calc vad 8khz total power #{total_power}"
      # Make a VAD
      inst.vad = self.gmm_probability(inst, feature_vector, total_power, frame_length)
      return inst.vad.to_i32
    end
  end
end
