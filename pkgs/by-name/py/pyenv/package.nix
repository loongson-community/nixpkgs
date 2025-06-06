{
  lib,
  stdenv,
  fetchFromGitHub,
  installShellFiles,
}:

stdenv.mkDerivation rec {
  pname = "pyenv";
  version = "2.5.7";

  src = fetchFromGitHub {
    owner = "pyenv";
    repo = "pyenv";
    tag = "v${version}";
    hash = "sha256-JTD++YQzO84zFVhp9BMBqA8Hln990tAFpfZ8YjmrhvU=";
  };

  nativeBuildInputs = [
    installShellFiles
  ];

  configureScript = "src/configure";

  makeFlags = [
    "-C"
    "src"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -R bin "$out/bin"
    cp -R libexec "$out/libexec"
    cp -R plugins "$out/plugins"

    runHook postInstall
  '';

  postInstall = ''
    installManPage man/man1/pyenv.1
    installShellCompletion completions/pyenv.{bash,fish,zsh}
  '';

  meta = with lib; {
    description = "Simple Python version management";
    homepage = "https://github.com/pyenv/pyenv";
    changelog = "https://github.com/pyenv/pyenv/blob/${src.rev}/CHANGELOG.md";
    license = licenses.mit;
    maintainers = with maintainers; [ tjni ];
    platforms = platforms.all;
    mainProgram = "pyenv";
  };
}
