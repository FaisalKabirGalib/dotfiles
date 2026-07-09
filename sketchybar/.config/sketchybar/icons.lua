-- Nerd Font glyph codepoints, explicit \u{} escapes rather than literal
-- glyph characters (private-use-area characters are too easy to mangle in
-- transit -- see plugins/aerospace.sh's git history in the old bash version
-- of this package for exactly that bug). All Font Awesome glyphs here
-- deliberately, not Material Design Icons -- FA's PUA codepoints have stayed
-- stable across Nerd Font v2->v3, MD's were remapped to the astral plane.
return {
  cpu = "\u{f2db}",      -- nf-fa-microchip
  calendar = "\u{f073}", -- nf-fa-calendar

  volume = {
    _100 = "\u{f028}", -- nf-fa-volume_up
    _66 = "\u{f028}",
    _33 = "\u{f027}",  -- nf-fa-volume_down
    _10 = "\u{f026}",  -- nf-fa-volume_off
    _0 = "\u{f026}",
  },

  wifi = {
    upload = "\u{f062}",       -- nf-fa-arrow_up
    download = "\u{f063}",     -- nf-fa-arrow_down
    connected = "\u{f1eb}",    -- nf-fa-wifi
    disconnected = "\u{f127}", -- nf-fa-chain_broken
  },
}
