class Unifi < Formula
  desc "Local UniFi Controller CLI"
  homepage "https://github.com/dl-alexandre/Local-UniFi-CLI"
  version "v1.1.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/dl-alexandre/Local-UniFi-CLI/releases/download/v0.0.2/unifi-darwin-arm64.tar.gz"
      sha256 "746f706e96a4bb877027e274a059018fe7658733707b4fff609f3fa2fb0a296f"

      def install
        bin.install "unifi"
      end
    end
    if Hardware::CPU.intel?
      url "https://github.com/dl-alexandre/Local-UniFi-CLI/releases/download/v0.0.2/unifi-darwin-amd64.tar.gz"
      sha256 "e1c481bc34aec8b295acb2facf9431bcab9078801d843174a753dea70f80561a"

      def install
        bin.install "unifi"
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/dl-alexandre/Local-UniFi-CLI/releases/download/v0.0.2/unifi-linux-arm64.tar.gz"
      sha256 "167e3b87758476872fd0307206846ef9c1823980d123c14d975d6abbc1c2307c"

      def install
        bin.install "unifi"
      end
    end
    if Hardware::CPU.intel? && Hardware::CPU.is_64_bit?
      url "https://github.com/dl-alexandre/Local-UniFi-CLI/releases/download/v0.0.2/unifi-linux-amd64.tar.gz"
      sha256 "24e3bf4f960b073aef143c4a745d10cd3ff6eee768b9e9737274088620ca0ff6"

      def install
        bin.install "unifi"
      end
    end
  end

  test do
    system "#{bin}/unifi", "version"
  end
end
