class Abc < Formula
  desc "CLI for Apple Business Connect API - manage business presence on Apple Maps"
  homepage "https://github.com/dl-alexandre/Apple-Business-Connect-CLI"
  version "v0.0.5"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/dl-alexandre/Apple-Business-Connect-CLI/releases/download/v0.0.4/abc-darwin-arm64.tar.gz"
      sha256 "68ded0424067733cebc2946e94c9dcc961007b7b5fd611191523b0ab584ff6c2"
    end
    if Hardware::CPU.intel?
      url "https://github.com/dl-alexandre/Apple-Business-Connect-CLI/releases/download/v0.0.4/abc-darwin-amd64.tar.gz"
      sha256 "0d4bb22fe714ce8646c0fe1c26c3a4642fc75f6798ea8d5643df734ffd7ee810"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/dl-alexandre/Apple-Business-Connect-CLI/releases/download/v0.0.4/abc-linux-arm64.tar.gz"
      sha256 "d6c97205217929ceaf4eb77c2a2f14eadf29203cfd38b4f798e6a281696ccebe"
    end
    if Hardware::CPU.intel?
      url "https://github.com/dl-alexandre/Apple-Business-Connect-CLI/releases/download/v0.0.4/abc-linux-amd64.tar.gz"
      sha256 "369539508d9d8e6ab4fbb4b61c9e82eba5f42759447257c3e861cd287a72a1ab"
    end
  end

  def install
    bin.install "abc"
  end

  test do
    system "#{bin}/abc", "version"
  end
end
