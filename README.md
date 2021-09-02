# webrtc_audio
[![Crystal CI](https://github.com/washu/webrtc_audio/actions/workflows/crystal.yml/badge.svg)](https://github.com/washu/webrtc_audio/actions/workflows/crystal.yml)
This is a pure crystal port of libvad (https://github.com/dpirch/libfvad)

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     webrtc_audio:
       github: washu/webrtc_audio
   ```

2. Run `shards install`

## Usage

```crystal
require "webrtc_audio"
vad = WebrtcAudio::WebRtcVad.new
vad.set_mode(WebrtcAudio::WebRtcVad::Aggressiveness::VeryAggress)
vad.set_sample_rate(16000)
has_voice = vad.process(input, input.size)_
```

Be saure you pass the correct size values to the processor or it will return false.

## Development

check it out, crystal spec 

## Contributing

1. Fork it (<https://github.com/your-github-user/webrtc_audio/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Sal Scotto](https://github.com/washu) - creator and maintainer
