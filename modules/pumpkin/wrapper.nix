{
  config,
  lib,
  wlib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types;

  settingsFormat = pkgs.formats.toml {};

  pluginSubmodule = types.submodule ({config, ...}: {
    options = {
      package = mkOption {
        type = types.package;
        description = "Derivation that contains the plugin .wasm.";
      };
      name = mkOption {
        type = types.str;
        default = config.package.passthru.pumpkinPlugin.name or (throw "plugin is missing passthru.pumpkinPlugin.name (or set plugins.*.name)");
        defaultText = lib.literalExpression "package.passthru.pumpkinPlugin.name";
        description = "Plugin name; used for the wasm filename and plugins/data/<name>/.";
      };
      wasmName = mkOption {
        type = types.str;
        default = "${config.name}.wasm";
        defaultText = lib.literalExpression "\"\${name}.wasm\"";
        description = "Filename placed in plugins/.";
      };
      settings = mkOption {
        type = types.submodule {
          freeformType = settingsFormat.type;
        };
        default = {};
        description = ''
          Plugin config written to plugins/data/<name>/config.toml.
        '';
      };
    };
  });

  pluginWasm = spec:
    spec.package.passthru.pumpkinPlugin.wasm or "${spec.package}/${spec.name}.wasm";

  pumpkinToml = settingsFormat.generate "pumpkin.toml" config.settings;

  pluginTomls = lib.listToAttrs (map (spec: {
    name = spec.name;
    value = settingsFormat.generate "${spec.name}-config.toml" spec.settings;
  }) (builtins.filter (spec: spec.settings != {}) config.plugins));

  layout = pkgs.runCommand "pumpkin-layout" {} ''
    mkdir -p "$out/plugins/data"
    cp ${pumpkinToml} "$out/pumpkin.toml"
    ${lib.concatMapStrings (spec: ''
      ln -s ${pluginWasm spec} "$out/plugins/${spec.wasmName}"
      mkdir -p "$out/plugins/data/${spec.name}"
      ${lib.optionalString (spec.settings != {}) ''
        cp ${pluginTomls.${spec.name}} "$out/plugins/data/${spec.name}/config.toml"
      ''}
    '') config.plugins}
  '';

  setup = ''
    data="''${${config.dataDirEnv}:-$PWD}"
    mkdir -p "$data/plugins/data"
    cp -f ${layout}/pumpkin.toml "$data/pumpkin.toml"
    ${lib.concatMapStrings (spec: ''
      ln -sfn ${pluginWasm spec} "$data/plugins/${spec.wasmName}"
      mkdir -p "$data/plugins/data/${spec.name}"
      ${lib.optionalString (spec.settings != {}) ''
        cp -f ${pluginTomls.${spec.name}} "$data/plugins/data/${spec.name}/config.toml"
      ''}
    '') config.plugins}
    cd "$data"
  '';
in {
  imports = [wlib.modules.default];

  options = {
    dataDirEnv = mkOption {
      type = types.str;
      default = "PUMPKIN_DATA_DIR";
      description = ''
        Environment variable naming the writable server directory (cwd for Pumpkin).
        Falls back to the process working directory when unset.
      '';
    };

    plugins = mkOption {
      type = types.listOf (types.coercedTo types.package (package: {inherit package;}) pluginSubmodule);
      default = [];
      description = ''
        WASM plugin derivations to link into plugins/.
        Each item is a package or { package, name?, settings?, wasmName? }.
      '';
    };

    settings = mkOption {
      type = types.submodule {
        freeformType = settingsFormat.type;
        options.plugins = {
          enabled = mkOption {
            type = types.bool;
            default = true;
            description = "Load WASM plugins.";
          };
          allow_unsigned = mkOption {
            type = types.bool;
            default = true;
            description = "Allow unsigned WASM plugins.";
          };
          verify_signatures = mkOption {
            type = types.bool;
            default = false;
            description = "Verify WASM plugin signatures before load.";
          };
          ask_permission_confirmation = mkOption {
            type = types.bool;
            default = false;
            description = "Prompt on the console when a plugin requests permissions.";
          };
          hot_reload = mkOption {
            type = types.bool;
            default = false;
            description = "Watch plugins/ and hot-reload.";
          };
        };
      };
      default = {};
      description = ''
        Structural pumpkin.toml (RFC 42). Nested attrsets become TOML tables.
        See Pumpkin's pumpkin-config crate for keys.
      '';
    };
  };

  config = {
    runShell = [setup];
    passthru.pumpkinLayout = layout;
    passthru.pumpkinToml = pumpkinToml;
  };
}
