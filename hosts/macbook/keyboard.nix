{ pkgs, ... } : {
  system.keyboard = {
    enableKeyMapping = true;
    userKeyMapping =
      let
        mkKeyMapping =
          let
            hexToInt = s: pkgs.lib.trivial.fromHexString s;
          in
          src: dst: {
            HIDKeyboardModifierMappingSrc = hexToInt src;
            HIDKeyboardModifierMappingDst = hexToInt dst;
          };
        # Key-map References:
        #   https://developer.apple.com/library/archive/technotes/tn2450/_index.html
        # e.g.
        #   07000 = Keyboard, 000E3 = Left Command
        #     -> 0x7000000E3 = Keyboard Left Command
        # macOS Fn key:
        #   https://apple.stackexchange.com/questions/340607/what-is-the-hex-id-for-fn-key%EF%BC%89
        tilde = "0xFF00000035";
        non-us-extra-key = "0xFF00000064";
      in
      [
        (mkKeyMapping non-us-extra-key tilde)
      ];
  };

}
