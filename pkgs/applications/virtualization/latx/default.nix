{
  lib,
  stdenv,
  fetchgit,
  pkg-config,
  perl,
  flex,
  bison,
  zlib,
  glib,
  git,
  openssl,
  libdrm,
  pcre2,
  python3,
  ninja,
  meson,
  makeWrapper,
  enableKzt ? !stdenv.hostPlatform.isStatic,
}:

assert lib.assertMsg (
  enableKzt -> !stdenv.hostPlatform.isStatic
) "latx: enableKzt cannot be used with static, as it causes build failures";

stdenv.mkDerivation rec {
  pname = "latx";
  version = "1.6.4";

  src = fetchgit {
    url = "https://github.com/lat-opensource/lat.git";
    rev = version;
    sha256 = "sha256-kSAQbsDuj39lvhMDqraWI4BLPWhduBEU8GW7XRdNRkE=";
    fetchSubmodules = false;
    leaveDotGit = true;
  };

  patches = lib.optionals stdenv.hostPlatform.isStatic [
    ./support-static-musl.patch
  ];

  postPatch = ''
    # Support cross-compilation by using target readelf binary
    substituteInPlace configure \
      --replace-fail "readelf" "${stdenv.cc.targetPrefix}readelf"
  '';

  nativeBuildInputs = [
    makeWrapper
    pkg-config
    git
    flex
    bison
    ninja
    perl
    meson
    python3
    stdenv.cc.bintools
  ];

  buildInputs = [
    zlib
    glib
    openssl
    libdrm
    pcre2
  ]
  ++ lib.optionals stdenv.hostPlatform.isStatic [
    zlib.static
  ];

  configurePhase = ''
    runHook preConfigure

    mkdir -p build32
    pushd build32
    ../configure \
      --target-list=i386-linux-user \
      --extra-ldflags=-ldl \
      --optimize-O1 \
      --disable-debug-info \
      --disable-blobs \
      --disable-docs \
      --disable-werror \
      --disable-pie \
      --disable-gcrypt \
      --disable-linux-io-uring \
      --enable-latx \
      --enable-guest-base-zero \
      ${lib.optionalString stdenv.hostPlatform.isStatic "--static"}
    popd

    mkdir -p build64
    pushd build64
    ../configure \
      --target-list=x86_64-linux-user \
      --extra-ldflags=-ldl \
      --optimize-O1 \
      --disable-debug-info \
      --disable-blobs \
      --disable-docs \
      --disable-werror \
      --disable-linux-io-uring \
      --enable-latx \
      ${lib.optionalString stdenv.hostPlatform.isStatic "--static"} \
      ${lib.optionalString enableKzt "--enable-kzt"}
    popd

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    echo "Building latx-i386..."
    ninja -v -C build32 -j$NIX_BUILD_CORES

    echo "Building latx-x86_64..."
    ninja -v -C build64 -j$NIX_BUILD_CORES

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -Dm755 build32/latx-i386 $out/bin/latx-i386
    install -Dm755 build64/latx-x86_64 $out/bin/latx-x86_64

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://github.com/lat-opensource/lat";
    description = "Loongson Architecture Translator for x86 applications";
    license = licenses.gpl2Plus;
    platforms = platforms.loongarch64;
    maintainers = with maintainers; [ darkyzhou ];
    teams = with teams; [ loongarch64 ];
  };
}
