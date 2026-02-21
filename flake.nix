{
  description = "NixOS configuration for System76 Serval WS 13 with Boneless hardened browser";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };

    # Boneless - Maximum hardened Chromium browser
    # No WebRTC, No MDM, No Remote Debug, No Telemetry
    boneless = pkgs.ungoogled-chromium.override {
      commandLineArgs = [
        # WebRTC completely disabled
        "--disable-webrtc"
        "--webrtc-ip-handling-policy=disable_non_proxied_udp"
        "--enforce-webrtc-ip-permission-check"
        "--disable-features=WebRTC,WebRTCPipeWireCapturer"
        # Remote debugging blocked
        "--disable-remote-debugging"
        "--remote-debugging-port=-1"
        # Sync/translate/background networking disabled
        "--disable-sync"
        "--disable-translate"
        "--disable-background-networking"
        "--disable-default-apps"
        "--disable-client-side-phishing-detection"
        "--no-pings"
        # Field trials (A/B testing) disabled
        "--disable-field-trial-config"
        "--disable-features=OptimizationHints,MediaRouter,Translate,TranslateUI"
        # Autofill server communication disabled
        "--disable-features=AutofillServerCommunication"
        # Privacy Sandbox completely disabled
        "--disable-features=PrivacySandboxSettings4,InterestFeedV2"
        "--disable-features=FlocId,Topics,Fledge,AttributionReporting"
        "--disable-features=BrowsingTopics,AdMeasurement,ConversionMeasurement"
        # Fingerprinting protection
        "--fingerprinting-canvas-image-data-noise"
        "--fingerprinting-canvas-measuretext-noise"
        "--fingerprinting-client-rects-noise"
        # Extra hardening
        "--disable-breakpad"
        "--disable-component-extensions-with-background-pages"
        "--disable-features=UsernameFirstFlow"
        # Password store - use basic (no keyring)
        "--password-store=basic"
        # Performance
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
      ];
    };
  in {
    # Expose boneless package for standalone use:
    # nix build .#boneless
    # nix run .#boneless
    packages.${system} = {
      inherit boneless;
      default = boneless;
    };

    # NixOS configuration (requires hardware-configuration.nix)
    # Usage: sudo nixos-rebuild switch --flake .#sys76
    nixosConfigurations.sys76 = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./configuration.nix
      ];
    };
  };
}
