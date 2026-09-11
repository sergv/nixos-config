{ pkgs
, name
, version

, shell-script-path
, icon-path
, bundle-identifier # e.g. "com.example.ApplicationName"
, copyright # e.g. "Copyright © 2026 Sergey Vinokurov, All Rights Reserved."
}:
let
  info-string =
    "${version}" +
    (if builtins.stringLength copyright > 0 then ", ${copyright}" else "");
  root = "$out/Applications/${name}.app/Contents";
  exe-name = name; #builtins.baseNameOf shell-script-path + ".command";
in
pkgs.runCommand "${name}-${version}"
  {
    # nativeBuildInputs = [ pkgs.imagemagick ];
  }
  # <key>CFBundleSignature</key>
  # <string>????</string>
  # <key>NSMainNibFile</key>
  # <string>main.nib</string>
  # <key>LSUIElement</key>
  # <true/>
  # <key>CFBundlePackageType</key>
  # <string>BNDL</string>
  ''
    runHook preInstall

    function write_to() {
        local x
        IFS='\n' read -r -d \'\' x || true
        echo "$x" >"$1"
    }

    mkdir -p "${root}/"

    write_to "${root}/Info.plist" <<'EOF'
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
    	<key>CFBundleDevelopmentRegion</key>
    	<string>English</string>
    	<key>CFBundleGetInfoString</key>
    	<string>${info-string}</string>
    	<key>CFBundleIdentifier</key>
    	<string>${bundle-identifier}</string>
    	<key>CFBundleInfoDictionaryVersion</key>
    	<string>6.0</string>
    	<key>CFBundleName</key>
    	<string>${name}</string>
    	<key>CFBundlePackageType</key>
    	<string>APPL</string>
    	<key>CFBundleShortVersionString</key>
    	<string>${version}</string>
    	<key>CFBundleVersion</key>
    	<string>${version}</string>
    	<key>NSHumanReadableCopyright</key>
    	<string>${copyright}</string>
    	<key>NSPrincipalClass</key>
    	<string>${name}App</string>
    	<key>CFBundleExecutable</key>
    	<string>${exe-name}</string>
    	<key>CFBundleIconFile</key>
    	<string>${exe-name}</string>
    	<key>CFBundleSignature</key>
    	<string>EMAx</string>
    	<key>LSArchitecturePriority</key>
    	<array>
    		<string>arm64</string>
    	</array>
    	<key>LSRequiresNativeExecution</key>
    	<true/>
    </dict>
    </plist>
    EOF

    mkdir -p "${root}/MacOS"
    write_to "${root}/MacOS/${exe-name}" <<'EOF'
    #!/bin/sh
    # Padding to 28 bytes.
    "${shell-script-path}" "''${@}"
    EOF
    chmod +x "${root}/MacOS/${exe-name}"

    mkdir -p "${root}/Resources"
    ln -s "${icon-path}" "${root}/Resources/${exe-name}.icns"

    runHook postInstall
  ''

    # magick convert "${icon-path}" "${root}/Resources/Icon.icns"
