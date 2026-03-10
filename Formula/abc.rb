class Abc < Formula
  desc "CLI for Apple Business Connect API - manage business presence on Apple Maps"
  homepage "https://github.com/dl-alexandre/Apple-Business-Connect-CLI"
  version "v0.0.2"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/dl-alexandre/Apple-Business-Connect-CLI/releases/download/v0.0.1/abc-darwin-arm64.tar.gz"
      sha256 "TO_BE_UPDATED"
    end
    if Hardware::CPU.intel?
      url "https://github.com/dl-alexandre/Apple-Business-Connect-CLI/releases/download/v0.0.1/abc-darwin-amd64.tar.gz"
      sha256 "TO_BE_UPDATED"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/dl-alexandre/Apple-Business-Connect-CLI/releases/download/v0.0.1/abc-linux-arm64.tar.gz"
      sha256 "TO_BE_UPDATED"
    end
    if Hardware::CPU.intel?
      url "https://github.com/dl-alexandre/Apple-Business-Connect-CLI/releases/download/v0.0.1/abc-linux-amd64.tar.gz"
      sha256 "TO_BE_UPDATED"
    end
  end

  def install
    bin.install "abc"
  end

  test do
    system "#{bin}/abc", "version"
  end
end
