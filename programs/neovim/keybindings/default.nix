{ pkgs, lib, ... }:

with lib.strings;

let
  key-mapper = prefix: { key, cmd, silent ? false, plugin ? false}:
      "${prefix}map ${lib.optionalString silent "<silent>"} ${key} " + (if plugin then "<Plug>(${cmd})" else cmd);

  withbody = body: {tabs ? true}:
    if isString body
    then body
    else concatStringsSep (if tabs then "\n  " else "\n") body;

  vimif = predicate: body: block "if" {args=predicate;} body;
  function = name: {args?""}: body: block "function" {args="${name} (${args})";} body;
  block = btype: {args?""}: body:
    concatStringsSep "\n" [
      (btype + " " + args)
      (withbody body {tabs=true;})
      "end${btype}"
    ];

  autocmd = {types?"FileType", middlething?"*"}: function: "autocmd ${types} ${middlething} call ${function}";

  keylib = {
    inherit function autocmd vimif;
    nvim-map = key-mapper "";
    nmap     = key-mapper "n";
    xmap     = key-mapper "x";
    nnoremap = key-mapper "nnore";
    inoremap = key-mapper "inore";
  };
in
{
  lib = keylib;
  leader = "<leader>";
  # TODO: make an attrset so you can find user-defined collisions.
}
