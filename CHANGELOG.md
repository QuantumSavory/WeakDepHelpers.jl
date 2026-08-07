# News

## v0.1.3 - 2026-08-07

- Restore styled weak-dependency errors and Julia syntax highlighting. This requires
  Julia 1.12 or later; users of older Julia versions can remain on v0.1.2 with
  plain-text diagnostics.

## v0.1.2 - 2026-08-07

- Add support for Julia 1.10 by removing `StyledStrings` and
  `JuliaSyntaxHighlighting`. Weak-dependency errors and method-error hints now use
  plain text; their diagnostic content and registration behavior are unchanged.
