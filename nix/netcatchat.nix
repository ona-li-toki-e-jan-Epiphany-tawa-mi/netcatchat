{ stdenv
, fetchFromGitHub
, bash
, netcat-openbsd
, makeWrapper
, lib
}:

stdenv.mkDerivation rec {
  pname   = "netcatchat";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "ona-li-toki-e-jan-Epiphany-tawa-mi";
    repo  = "netcatchat";
    rev   = "RELEASE-V${version}";
    hash  = "sha256-e30hvGcFbyH9Jc7Vq+FqBgtL+fB+EK4Rz9bCCiW9MHM=";
  };

  buildInputs       = [ bash netcat-openbsd ];
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp netcatchat.sh $out/bin/netcatchat
    wrapProgram $out/bin/netcatchat --prefix PATH : ${lib.makeBinPath [ netcat-openbsd ]}

    runHook postInstall
  '';
}
