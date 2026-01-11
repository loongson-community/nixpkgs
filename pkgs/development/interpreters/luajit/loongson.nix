{
  self,
  callPackage,
  fetchFromGitHub,
  passthruFun,
}:

callPackage ./default.nix {
  # The patch version is the timestamp of the git commit,
  # obtain via `cat $(nix-build -A luajit_loongson.src)/.relver`
  version = "2.1.1784017455";

  src = fetchFromGitHub {
    owner = "loongson";
    repo = "LuaJIT";
    rev = "a28f2c7357759a2b9e263147be2dc0780308d558";
    hash = "sha256-vKA0fwp+S0Ga+bLfb9dw9D5D+AMzuWhJPU7ZiwXdgjQ=";
  };

  luaAttr = "luajit_loongson";

  extraMeta = {
    platforms = [ "loongarch64-linux" ];
    badPlatforms = [ ];
  };
  inherit self passthruFun;
}
