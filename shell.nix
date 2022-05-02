with (import <nixpkgs> {});
let
  basePackages = [
	pkgs.bashInteractive
	git
	direnv

	erlang
	elixir
	rustc
  ];

  inputs = basePackages
    ++ lib.optional stdenv.isLinux inotify-tools
    ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
        CoreFoundation
        CoreServices
      ]);

in mkShell {
  buildInputs = inputs;
	shellHook =
  ''
  '';
}
