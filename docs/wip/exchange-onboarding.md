Table of Contents
=================

   * [Requirements](#requirements)
      * [Nix](#nix)
         * [Optional: Enable IOHK's binary cache](#optional-enable-iohks-binary-cache)
      * [Miscellaneous Utilities](#miscellaneous-utilities)
   * [Mainnet Wallet](#mainnet-wallet)
      * [Backup local state](#backup-local-state)
      * [Fetch latest code](#fetch-latest-code)
      * [Build and run](#build-and-run)
      * [Usage FAQs](#usage-faqs)
         * [How do I customize the wallet configuration?](#how-do-i-customize-the-wallet-configuration)
         * [How do I know when the wallet has fetched all the blocks?](#how-do-i-know-when-the-wallet-has-fetched-all-the-blocks)
         * [Where can I find the API documentation?](#where-can-i-find-the-api-documentation)
         * [How can I inspect runtime metrics and statistics?](#how-can-i-inspect-runtime-metrics-and-statistics)

# Requirements

## Nix

The wallet is built using [nix package manager](https://nixos.org/nix/). To install it on
most Linux distros download and run the installation script.

    curl https://nixos.org/nix/install > install-nix.sh
    . install-nix.sh

Follow the directions and then log out and back in.

### Optional: Enable IOHK's binary cache

Skip this section if you prefer to build all code from IOHK
locally. When the binary cache is enabled build steps will tend
go faster.

    sudo mkdir -p /etc/nix
    cat <<EOF | sudo tee /etc/nix/nix.conf
    binary-caches            = https://cache.nixos.org https://hydra.iohk.io
    binary-cache-public-keys = hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=
    EOF

## Miscellaneous Utilities

Use `nix` to install essential utilities.

    nix-env -i git

# Mainnet Wallet

## Backup local state

Skip to the next section if this is target machine doesn't yet have
`cardano-sl` set up.

To avoid catastrophic data loss, stop the wallet and backup the
local databases, keys, certificates, and logs. By default, the
local state will be in `./state-wallet-mainnet`, but may be
elsewhere (see `stateDir` attribute in `./custom-wallet-config.nix`).

## Fetch latest code

Clone the [cardano-sl repository](https://github.com/input-output-hk/cardano-sl) or `cd` into a preexisting copy.

    git clone https://github.com/input-output-hk/cardano-sl.git
    cd cardano-sl

Switch to the `master` branch and pull the latest code.

    git checkout master
    git pull

Dump the current revision and confirm with IOHK whether it is as
expected.

    git rev-parse HEAD

## Build and run

By default the wallet's local state goes in
`./state-wallet-mainnet`. If you prefer to have this sensitive data
outside the git repository, see the FAQ about supported custom
configuration settings (See section 2.4.1).

Build the wallet and generate the shell script to connect to
mainnet.

    nix-build -A connectScripts.mainnetWallet -o "./launch_$(date -I)_$(git rev-parse --short HEAD)"

After the build finishes the generated connection script is
available as a symlink called `./launch_2018-01-30_0d4f79eea`, or
similar. Run that symlink as a script to start the wallet.

## Usage FAQs

### How do I customize the wallet configuration?


Before building the wallet copy `./sample-wallet-config.nix` to
`./custom-wallet-config.nix` and edit as needed.

Supported options include:

-   **`walletListen`:** Wallet API server
-   **`ekgListen`:** Runtime metrics server
-   **`stateDir`:** Directory for the wallet's local state. Must be
    enclosed in double quotes.
-   **`topologyFile`:** Used to connect to a custom set of nodes on
    the network. When unspecified an appropriate
    default topology is generated.

### How do I know when the wallet has fetched all the blocks?

Monitor the logs in the wallet's local state directory for lines
like

    slot: 18262th slot of 25th epoch

If any of the recent matches are more than a slot lower than the
latest epoch and slot reported by [Cardano Explorer](https://cardanoexplorer.com/), the wallet is
still syncing.

### Where can I find the API documentation?

Run the latest wallet and go to <https://127.0.0.1:8090/docs>.

### How can I inspect runtime metrics and statistics?

Current metrics and stats are available at <http://127.0.0.1:8000/>.
