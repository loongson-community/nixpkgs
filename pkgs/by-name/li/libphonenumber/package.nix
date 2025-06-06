{
  lib,
  stdenv,
  fetchFromGitHub,
  buildPackages,
  cmake,
  enableTests ? false,
  gtest,
  jre,
  pkg-config,
  boost,
  icu,
  protobuf,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libphonenumber";
  version = "9.0.5";

  src = fetchFromGitHub {
    owner = "google";
    repo = "libphonenumber";
    rev = "v${finalAttrs.version}";
    hash = "sha256-CVT0HBT4WnlTrT8mhapJjyIbd+pp7uxrZxa9ZlXVm3c=";
  };

  patches = [
    # An earlier version of this patch was submitted upstream but did not get
    # any interest there - https://github.com/google/libphonenumber/pull/2921
    ./build-reproducibility.patch
  ];

  nativeBuildInputs =
    [
      cmake
      pkg-config
    ]
    ++ lib.optionals enableTests [
      gtest
      jre
    ];

  buildInputs =
    [
      icu
      protobuf
    ]
    ++ lib.optionals enableTests [
      boost
    ];

  cmakeDir = "../cpp";

  doCheck = enableTests;

  checkTarget = "tests";

  cmakeFlags =
    lib.optionals (!enableTests) [
      (lib.cmakeBool "REGENERATE_METADATA" false)
      (lib.cmakeBool "USE_BOOST" false)
    ]
    ++ lib.optionals (!stdenv.buildPlatform.canExecute stdenv.hostPlatform) [
      (lib.cmakeFeature "CMAKE_CROSSCOMPILING_EMULATOR" (stdenv.hostPlatform.emulator buildPackages))
      (lib.cmakeFeature "PROTOC_BIN" (lib.getExe buildPackages.protobuf))
    ];

  meta = with lib; {
    changelog = "https://github.com/google/libphonenumber/blob/${finalAttrs.src.rev}/release_notes.txt";
    description = "Google's i18n library for parsing and using phone numbers";
    homepage = "https://github.com/google/libphonenumber";
    license = licenses.asl20;
    maintainers = with maintainers; [ illegalprime ];
  };
})
