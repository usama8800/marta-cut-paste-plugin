# Cut and Paste for Marta

Adds Finder-style cut & paste to the [Marta](https://marta.sh) file manager.

- **Cmd+X**: mark the selected files for moving (also copies them to the clipboard)
- **Cmd+V**: move the marked files into the current folder (normal paste if nothing is marked)
- **Cmd+X twice** on the same selection: move it straight to the other pane's folder
- **Cmd+C**: normal copy, and cancels a pending cut

Existing files are never overwritten; conflicting items are skipped and reported.

## Install

1. Copy `cutpaste.lua` to `~/Library/Application Support/org.yanex.marta/Plugins/`
2. Add to `keyBindings` in `~/Library/Application Support/org.yanex.marta/conf.marco`:

   ```
   "Cmd+x" "cutpaste.cut"
   "Cmd+c" "cutpaste.copy"
   "Cmd+v" "cutpaste.paste"
   ```

3. Restart Marta.
