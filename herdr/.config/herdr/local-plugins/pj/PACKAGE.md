# Local PJ Herdr plugin

This tracked local plugin replaces the upstream PJ plugin so the fzf preview
uses absolute system paths for `eza`, `tree`, and `ls`. It avoids a Herdr/fzf
preview-shell lookup failure while preserving PJ's workspace picker behavior.
