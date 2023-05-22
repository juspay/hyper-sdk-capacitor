# Contributing

Contributions are always welcome, no matter how large or small!

We want this community to be friendly and respectful to each other. Please follow it in all your interactions with the project. Before contributing, please read the [code of conduct](./CODE_OF_CONDUCT.md).

## Minimum Requirement

This project requires node 16 to run. You can check your current node version using the command `node -v`. If you are using another version, you can install nvm to run different node version across projects.

- Install nvm globally
  ```sh
  brew install nvm
  ```

- Install node version 16 using nvm
  ```sh
  nvm install v16
  ```

- To automatically switch node versions between projects, paste the following snippet in your `~/.bashrc` or `~/.zshrc` file

  ```sh
  # place this after nvm initialization!
  autoload -U add-zsh-hook

  load-nvmrc() {
    local nvmrc_path
    nvmrc_path="$(nvm_find_nvmrc)"

    if [ -n "$nvmrc_path" ]; then
      local nvmrc_node_version
      nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

      if [ "$nvmrc_node_version" = "N/A" ]; then
        nvm install
      elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
        nvm use
      fi
    elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
      echo "Reverting to nvm default version"
      nvm use default
    fi
  }

  add-zsh-hook chpwd load-nvmrc
  load-nvmrc
  ```

  After adding this, restart your terminal or run `source ~/.bashrc` or `source ~/.zshrc` in your terminal.

Check [nvm official github](https://github.com/nvm-sh/nvm) for more information.

## Developing

### Local Setup

1. Fork and clone the repo.
2. Install the dependencies.

    ```shell
    npm run bootstrap
    ```

3. Install SwiftLint if you're on macOS.

    ```shell
    brew install swiftlint
    ```

### Scripts

#### `npm run build`


It will compile the TypeScript code from `src/` into ESM JavaScript in `dist/esm/`. These files are used in apps with bundlers when your plugin is imported.

Then, Rollup will bundle the code into a single file at `dist/plugin.js`. This file is used in apps without bundlers by including it as a script in `index.html`.

#### `npm run verify`

Build and validate the web and native projects.

This is useful to run in CI to verify that the plugin builds for all platforms.

#### `npm run lint` / `npm run fmt`

Check formatting and code quality, autoformat/autofix if possible.

This template is integrated with ESLint, Prettier, and SwiftLint. Using these tools is completely optional, but the [Capacitor Community](https://github.com/capacitor-community/) strives to have consistent code style and structure for easier cooperation.

## Publishing

There is a `prepublishOnly` hook in `package.json` which prepares the plugin before publishing, so all you need to do is run:

```shell
npm publish
```

> **Note**: The [`files`](https://docs.npmjs.com/cli/v7/configuring-npm/package-json#files) array in `package.json` specifies which files get published. If you rename files/directories or add files elsewhere, you may need to update it.

### Base test setup

To setup example project, setup merchant and customer details:
- navigate to [example->src->js->merchant_config.json](./example/src/js/merchant_config.json) and update below values:

```json
{
  "merchantId": "",
  "clientId": "",
  "apiKey": "",
  "privateKey": "",
  "merchantKeyId": ""
}
```
- navigate to [example->src->js->customer_config.json](./example/src/js/customer_config.json) and update below values:

```json
{
  "customerId": "",
  "mobile": "",
  "email": "",
  "amount": ""
}
```

### Sending a pull request

> **Working on your first pull request?** You can learn how from this _free_ series: [How to Contribute to an Open Source Project on GitHub](https://app.egghead.io/playlists/how-to-contribute-to-an-open-source-project-on-github).

When you're sending a pull request:

- Prefer small pull requests focused on one change.
- Verify that linters and tests are passing.
- Review the documentation to make sure it looks good.
- Follow the pull request template when opening a pull request.
- For pull requests that change the API or implementation, discuss with maintainers first by opening an issue.
