# typed: false
# frozen_string_literal: true

class Grokipedia < Formula
  desc "Grokipedia CLI - command-line interface for the Grokipedia API"
  homepage "https://github.com/dl-alexandre/Grokipedia-CLI"
  version "v0.1.1"
  license "MIT"

  on_macos do
    if Hardware::CPU.intel?
      url "https://github.com/dl-alexandre/Grokipedia-CLI/releases/download/v0.1.1/grokipedia-darwin-amd64.tar.gz"
      sha256 "e381e0cc18c2f06497bc1893d509e8305bd4ddbec7b194c35fa354e354b92e92"

      define_method(:install) do
        bin.install "grokipedia"
      end
    end
    if Hardware::CPU.arm?
      url "https://github.com/dl-alexandre/Grokipedia-CLI/releases/download/v0.1.1/grokipedia-darwin-arm64.tar.gz"
      sha256 "a5270ab2f28d605787ee51db670c9c0e0d6d36987f8ac9659729bf8b7c13d46c"

      define_method(:install) do
        bin.install "grokipedia"
      end
    end
  end

  on_linux do
    if Hardware::CPU.intel? && Hardware::CPU.is_64_bit?
      url "https://github.com/dl-alexandre/Grokipedia-CLI/releases/download/v0.1.1/grokipedia-linux-amd64.tar.gz"
      sha256 "e0a5b578a05c0e4281b0f26c713d49bcc0a6879fbac327824746a999382d62cc"
      define_method(:install) do
        bin.install "grokipedia"
      end
    end
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/dl-alexandre/Grokipedia-CLI/releases/download/v0.1.1/grokipedia-linux-arm64.tar.gz"
      sha256 "0f6c65ff5ec5346369e6e3563e4a9eb50406bad4dcd03de427c1acfa84304db6"
      define_method(:install) do
        bin.install "grokipedia"
      end
    end
  end

  test do
    system "#{bin}/grokipedia", "--help"
  end
end