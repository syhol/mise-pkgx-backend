# mise-pkgx-backend

A mise backend plugin to install CLI tools from the pkgxdev/pantry registry using native Lua.

## Usage

Install the plugin (linked or from Luarocks). Then:

```bash
mise plugin install path/to/mise-pkgx-backend
mise list-versions pkgx:node
mise use pkgx:node@16.18.1

