{
  self,
  callPackage,
  fetchFromGitHub,
  passthruFun,
}:

callPackage ./default.nix {
  # The patch version is the timestamp of the git commit,
  # obtain via `cat $(nix-build -A luajit_2_0.src)/.relver`
  version = "2.1.1749125925";

  src = fetchFromGitHub {
    owner = "loongson";
    repo = "LuaJIT";
    rev = "02579d06dba72769949b0e8660c875a6d20eb6b3";
    hash = "sha256-07U+xUikZYQr+TgQZZtHHTqQUdkoiMc8Umtgh7gZVzA=";
  };

  luaAttr = "luajit_loongson";

  extraMeta = {
    platforms = [ "loongarch64-linux" ];
    badPlatforms = [ ];
  };
  inherit self passthruFun;
}
