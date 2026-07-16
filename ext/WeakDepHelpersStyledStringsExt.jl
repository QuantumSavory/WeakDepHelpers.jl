module WeakDepHelpersStyledStringsExt

import JuliaSyntaxHighlighting
import WeakDepHelpers: highlight

# Add a more specific method so identifiers in the WeakDepMissingError message are
# syntax-highlighted when JuliaSyntaxHighlighting is available.
highlight(x::AbstractString) = JuliaSyntaxHighlighting.highlight(x)

end # module WeakDepHelpersStyledStringsExt