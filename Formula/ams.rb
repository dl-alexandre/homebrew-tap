class Ams < Formula
  desc "Apple Maps Server API CLI for location services"
  homepage "https://github.com/dl-alexandre/Apple-Map-Server-CLI"
  version "v0.0.2"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/dl-alexandre/Apple-Map-Server-CLI/releases/download/v0.0.7/ams-darwin-arm64.tar.gz"
      sha256 "TO_BE_UPDATED"

      def install
        bin.install "ams"
      end
    end
    if Hardware::CPU.intel?
      url "https://github.com/dl-alexandre/Apple-Map-Server-CLI/releases/download/v0.0.7/ams-darwin-amd64.tar.gz"
      sha256 "TO_BE_UPDATED"

      def install
        bin.install "ams"
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/dl-alexandre/Apple-Map-Server-CLI/releases/download/v0.0.7/ams-linux-arm64.tar.gz"
      sha256 "TO_BE_UPDATED"

      def install
        bin.install "ams"
      end
    end
    if Hardware::CPU.intel? && Hardware::CPU.is_64_bit?
      url "https://github.com/dl-alexandre/Apple-Map-Server-CLI/releases/download/v0.0.7/ams-linux-amd64.tar.gz"
      sha256 "TO_BE_UPDATED"

      def install
        bin.install "ams"
      end
    end
  end

  test do
    system "#{bin}/ams", "version"
  end
end
