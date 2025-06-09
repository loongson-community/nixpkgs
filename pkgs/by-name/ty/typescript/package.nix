{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  versionCheckHook,
  writeShellApplication,
  nodejs,
  gnutar,
  nix-update,
  prefetch-npm-deps,
  gnused,
}:

buildNpmPackage (finalAttrs: {
  pname = "typescript";
  version = "5.8.2";

  src = fetchFromGitHub {
    owner = "microsoft";
    repo = "TypeScript";
    tag = "v${finalAttrs.version}";
    hash = "sha256-fOA5IblxUd+C9ST3oI8IUmTTRL3exC63MPqW5hoWN0M=";
  };

  patches = [
    ./disable-dprint.patch
  ];

  npmDepsHash = "sha256-1Ygmw2EvjhMtQSYcwDQB/tj+01v6EGRcWT6wvtiO1KI=";

  nativeInstallCheckInputs = [
    versionCheckHook
  ];
  doInstallCheck = true;
  versionCheckProgram = "${placeholder "out"}/bin/tsc";
  versionCheckProgramArg = "--version";

  passthru = {
    updateScript = lib.getExe (writeShellApplication {
      name = "${finalAttrs.pname}-updater";
      runtimeInputs = [
        nodejs
        gnutar
        nix-update
        prefetch-npm-deps
        gnused
      ];
      runtimeEnv = {
        PNAME = finalAttrs.pname;
        PKG_DIR = builtins.toString ./.;
      };
      text = builtins.readFile ./update.bash;
    });
  };

  meta = {
    description = "Superset of JavaScript that compiles to clean JavaScript output";
    homepage = "https://www.typescriptlang.org/";
    changelog = "https://github.com/microsoft/TypeScript/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [
      kachick
    ];
    mainProgram = "tsc";
  };
})
