{
  stdenv,
  lib,
  callPackage,
}:
# TODO: assert stdenv.hostPlatform.isLoongarch64
let
  sources = (lib.importJSON ./sources.json).hotspot.linux;
  common = opts: callPackage (import ./jdk-linux-base.nix opts) { };
in
{
  jdk-8 = common { sourcePerArch = sources.jdk.openjdk8; };

  jdk-11 = common { sourcePerArch = sources.jdk.openjdk11; };

  jdk-17 = common { sourcePerArch = sources.jdk.openjdk17; };

  jdk-21 = common { sourcePerArch = sources.jdk.openjdk21; };

  jdk-25 = common { sourcePerArch = sources.jdk.openjdk25; };
}
