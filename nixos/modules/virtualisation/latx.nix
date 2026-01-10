{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
let
  cfg = config.virtualisation.latx;
in
{
  options = {
    virtualisation.latx = {
      enable = lib.mkEnableOption "Loongson Architecture Translator for x86 applications";

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.pkgsStatic.latx;
        defaultText = lib.literalExpression "pkgs.pkgsStatic.latx";
        description = ''
          The LATX package to use. The binfmt interpreter requires a statically
          linked binary, so the default uses pkgsStatic.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isLoongArch64;
        message = "LATX is only supported on LoongArch64 systems";
      }
      {
        # https://github.com/lat-opensource/lat/blob/5f6d966ed4b123c815f9b249baec88f3ebe61a15/latxbuild/build-release.sh#L95
        assertion = (config.boot.kernel.sysctl."vm.mmap_min_addr" or 65536) >= 65536;
        message = "LATX requires vm.mmap_min_addr >= 65536 for compatibility";
      }
      {
        assertion = !(builtins.elem "x86_64-linux" config.boot.binfmt.emulatedSystems);
        message = "Cannot use both LATX and boot.binfmt.emulatedSystems for x86_64-linux. Choose one.";
      }
      {
        assertion = !(builtins.elem "i686-linux" config.boot.binfmt.emulatedSystems);
        message = "Cannot use both LATX and boot.binfmt.emulatedSystems for i686-linux. Choose one.";
      }
    ];

    environment.systemPackages = [ cfg.package ];

    nix.settings = {
      extra-platforms = [
        "x86_64-linux"
        "i686-linux"
      ];
      extra-sandbox-paths = [
        "/run/binfmt"
        "${cfg.package}"
      ];
    };

    boot.binfmt.registrations.latx-x86_64 = {
      inherit (utils.binfmtMagics.x86_64-linux) magicOrExtension mask;
      interpreter = lib.getExe' cfg.package "latx-x86_64";
      interpreterSandboxPath = cfg.package;
      fixBinary = true;
      preserveArgvZero = true;
      wrapInterpreterInShell = false;
    };

    boot.binfmt.registrations.latx-i386 = {
      inherit (utils.binfmtMagics.i386-linux) magicOrExtension mask;
      interpreter = lib.getExe' cfg.package "latx-i386";
      interpreterSandboxPath = cfg.package;
      fixBinary = true;
      preserveArgvZero = true;
      wrapInterpreterInShell = false;
    };
  };
}
