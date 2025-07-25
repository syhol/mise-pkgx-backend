# mise-pkgx-backend

> [!CAUTION]
> Mega alpha, not really tested, super unstable and incomplete, but sort of works sometimes

A mise backend plugin to install CLI tools from the pkgxdev/pantry registry using native Lua.

## Usage

Install the plugin and use it:

```bash
mise plugin install pkgx https://github.com/syhol/mise-pkgx-backend
mise list-versions pkgx:git-scm.org
mise use pkgx:git-scm.org
```
