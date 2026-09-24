# typed: false
# frozen_string_literal: true

class Grokipedia < Formula
  desc "Unofficial command-line interface for the Grokipedia API"
  homepage "https://github.com/dl-alexandre/Grokipedia-CLI"
  version "0.1.3"
  license "MIT"

  on_macos do
    if Hardware::CPU.intel?
      url "https://github.com/dl-alexandre/Grokipedia-CLI/releases/download/v0.1.3/grokipedia-darwin-amd64.tar.gz"
      sha256 "8ef8f9eaf31b211f8041f5e03a661920cff5ddba6bfa7bb3c0957beafca303f1"

      define_method(:install) do
        bin.install "grokipedia"
      end
    end
    if Hardware::CPU.arm?
      url "https://github.com/dl-alexandre/Grokipedia-CLI/releases/download/v0.1.3/grokipedia-darwin-arm64.tar.gz"
      sha256 "05f9cc2554adb1e311f724ee23af10087963a5e957b4d49c323a7f8fbdb698c3"

      define_method(:install) do
        bin.install "grokipedia"
      end
    end
  end

  on_linux do
    if Hardware::CPU.intel? && Hardware::CPU.is_64_bit?
      url "https://github.com/dl-alexandre/Grokipedia-CLI/releases/download/v0.1.3/grokipedia-linux-amd64.tar.gz"
      sha256 "59f1cb8efd1ce7ba7cc310c45dee8e88343a43024cffc7dcbad6f4970f4f0e11"

      define_method(:install) do
        bin.install "grokipedia"
      end
    end
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/dl-alexandre/Grokipedia-CLI/releases/download/v0.1.3/grokipedia-linux-arm64.tar.gz"
      sha256 "11ebea3a9d47368a7b2c70329836614bb6929dd2049e94dbbba4b4072d499873"

      define_method(:install) do
        bin.install "grokipedia"
      end
    end
  end

  test do
    system "#{bin}/grokipedia", "--help"
  end
end
