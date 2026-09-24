# typed: false
# frozen_string_literal: true

class Grokipedia < Formula
  desc "Grokipedia CLI - command-line interface for the Grokipedia API"
  homepage "https://github.com/dl-alexandre/Grokipedia-CLI"
  version "v0.1.2"
  license "MIT"

  on_macos do
    if Hardware::CPU.intel?
      url "https://github.com/dl-alexandre/Grokipedia-CLI/releases/download/v0.1.2/grokipedia-darwin-amd64.tar.gz"
      sha256 "e4a62cdbb0380bcadf7be81f784a47d23021e99f3debf59e7706adc0b30cf18a"

      define_method(:install) do
        bin.install "grokipedia"
      end
    end
    if Hardware::CPU.arm?
      url "https://github.com/dl-alexandre/Grokipedia-CLI/releases/download/v0.1.2/grokipedia-darwin-arm64.tar.gz"
      sha256 "91fdf10750e97ee6c68512e0339de60d292a2046e24e013fffe876f30bffd562"

      define_method(:install) do
        bin.install "grokipedia"
      end
    end
  end

  on_linux do
    if Hardware::CPU.intel? && Hardware::CPU.is_64_bit?
      url "https://github.com/dl-alexandre/Grokipedia-CLI/releases/download/v0.1.2/grokipedia-linux-amd64.tar.gz"
      sha256 "46095ec9e524cf054ba38151d37066e845aa5b627c633f18b6866b1a7f694efc"
      define_method(:install) do
        bin.install "grokipedia"
      end
    end
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/dl-alexandre/Grokipedia-CLI/releases/download/v0.1.2/grokipedia-linux-arm64.tar.gz"
      sha256 "9c6b69a7672da71b74bc5fbf636d93e8755807c130ed2659b484d8e8b763dbdc"
      define_method(:install) do
        bin.install "grokipedia"
      end
    end
  end

  test do
    system "#{bin}/grokipedia", "--help"
  end
end