{
  name-prefix ? "loongson-jdk",
  brand-name ? "Loongson JDK",
  sourcePerArch,
  jmodsSourcePreArch ? null,
  knownVulnerabilities ? [ ],
}:

{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  setJavaClassPath,
  cacert,
  jre-generate-cacerts,
  # regenerate lib/security/cacerts from cacert; needs a runnable keytool
  regenerateCacerts ? stdenv.buildPlatform.canExecute stdenv.hostPlatform,
  # minimum dependencies
  alsa-lib,
  fontconfig,
  freetype,
  libffi,
  libxtst,
  libxrender,
  libxi,
  libxext,
  libx11,
  libxxf86vm,
  zlib,
  # runtime dependencies
  cups,
  # runtime dependencies for GTK+ Look and Feel
  # TODO(@sternenseemann): gtk3 fails to evaluate in pkgsCross.ghcjs.buildPackages
  # which should be fixable, this is a no-rebuild workaround for GHC.
  gtkSupport ? !stdenv.targetPlatform.isGhcjs,
  cairo,
  glib,
  gtk2,
  gtk3,
  atk,
  gdk-pixbuf,
  harfbuzz,
  pango,
  # multimedia dependencies
  ffmpeg_4,
}:

let
  cpuName = stdenv.hostPlatform.parsed.cpu.name;
  runtimeDependencies = [
    cups
    ffmpeg_4
    cairo
    glib
    gtk3
    atk
    gdk-pixbuf
    harfbuzz
    pango
  ];
  runtimeLibraryPath = lib.makeLibraryPath runtimeDependencies;
  validCpuTypes = builtins.attrNames lib.systems.parse.cpuTypes;
  providedCpuTypes = builtins.filter (arch: builtins.elem arch validCpuTypes) (
    builtins.attrNames sourcePerArch
  );
  # only the JDK 8 tarball keeps its JRE under jre/
  isJdk8 =
    sourcePerArch.packageType == "jdk" && lib.versions.major sourcePerArch.${cpuName}.version == "8";
  result = stdenv.mkDerivation (
    {
      pname =
        if sourcePerArch.packageType == "jdk" then
          "${name-prefix}-bin"
        else
          "${name-prefix}-${sourcePerArch.packageType}-bin";

      version = sourcePerArch.${cpuName}.version or "unsupported";

      srcs = [
        (fetchurl {
          inherit (sourcePerArch.${cpuName}) url sha256;
        })
      ]
      ++ lib.optional (jmodsSourcePreArch != null) (fetchurl {
        inherit (jmodsSourcePreArch.${cpuName}) url sha256;
      });

      sourceRoot = ".";

      buildInputs = [
        alsa-lib # libasound.so wanted by lib/libjsound.so
        fontconfig
        freetype
        (lib.getLib stdenv.cc.cc) # libstdc++.so.6
        libx11
        libxext
        libxi
        libxrender
        libxtst
        libxxf86vm
        zlib
        ffmpeg_4
        cairo
        glib
        gtk3
        atk
        gdk-pixbuf
        harfbuzz
        pango
      ]
      ++ lib.optionals (lib.versionOlder sourcePerArch.${cpuName}.version "21") [
        gtk2
      ]
      ++ lib.optional stdenv.hostPlatform.isAarch32 libffi;

      nativeBuildInputs = [
        autoPatchelfHook
        makeWrapper
      ];

      # See: https://github.com/NixOS/patchelf/issues/10
      dontStrip = 1;

      installPhase = ''
        # compatible semeru jdk
        TARGET_SOURCE=$(find . -maxdepth 1 -type d ! -name "." ! -name "*jmods" -print -quit)

        mv "$TARGET_SOURCE" $out

        ${lib.optionalString (jmodsSourcePreArch != null) "mv */ $out/jmods"}

        # jni.h expects jni_md.h to be in the header search path.
        ln -s $out/include/linux/*_md.h $out/include/

        # Remove some broken manpages.
        # Only for 11 and earlier.
        [ -e "$out/man/ja" ] && rm -r $out/man/ja*

        # Remove embedded freetype to avoid problems like
        # https://github.com/NixOS/nixpkgs/issues/57733
        find "$out" -name 'libfreetype.so*' -delete

        # Propagate the setJavaClassPath setup hook from the JDK so that
        # any package that depends on the JDK has $CLASSPATH set up
        # properly.
        mkdir -p $out/nix-support
        printWords ${setJavaClassPath} > $out/nix-support/propagated-build-inputs

        # Set JAVA_HOME automatically.
        cat <<EOF >> "$out/nix-support/setup-hook"
        if [ -z "\''${JAVA_HOME-}" ]; then export JAVA_HOME=$out; fi
        EOF

        # We cannot use -exec since wrapProgram is a function but not a command.
        #
        # jspawnhelper is executed from JVM, so it doesn't need to wrap it, and it
        # breaks building OpenJDK (#114495).
        for bin in $( find "$out" -executable -type f -not -name jspawnhelper ); do
          if patchelf --print-interpreter "$bin" &> /dev/null; then
            wrapProgram "$bin" --prefix LD_LIBRARY_PATH : "${runtimeLibraryPath}"
          fi
        done
      '';

      preFixup = ''
        find "$out" -name libfontmanager.so -exec \
          patchelf --add-needed libfontconfig.so {} \;
      '';

      autoPatchelfIgnoreMissingDeps =
        lib.optionals (lib.versionOlder sourcePerArch.${cpuName}.version "11")
          [
            "ld.so.1"
          ];

      # FIXME: use multiple outputs or return actual JRE package
      passthru = {
        jre = result;
        home = result;
      };

      meta = {
        license = with lib.licenses; [
          gpl2
          classpathException20
        ];
        sourceProvenance = with lib.sourceTypes; [
          binaryNativeCode
          binaryBytecode
        ];
        description = "${brand-name}, prebuilt OpenJDK binary";
        platforms = map (arch: arch + "-linux") providedCpuTypes; # some inherit jre.meta.platforms
        maintainers = with lib.maintainers; [ taku0 ];
        teams = [
          lib.teams.java
          lib.teams.loongarch64
        ];
        inherit knownVulnerabilities;
        mainProgram = "java";
      };
    }
    // lib.optionalAttrs regenerateCacerts {
      # keytool must already be patched when postFixup regenerates cacerts
      dontAutoPatchelf = true;
      # regenerate the bundled CA keystore from cacert, as openjdk/generic.nix does
      postFixup = ''
        autoPatchelf -- "$out"
        pushd "$out/${lib.optionalString isJdk8 "jre/"}lib/security"
        rm cacerts
        JAVA_TOOL_OPTIONS="-Dkeystore.pkcs12.certProtectionAlgorithm=NONE -Dkeystore.pkcs12.macAlgorithm=NONE" \
          ${jre-generate-cacerts} "$out/bin/keytool" ${cacert}/etc/ssl/certs/ca-bundle.crt
        [ -s cacerts ] || { echo "failed to generate cacerts" >&2; exit 1; }
        popd
      '';
    }
  );
in
result
