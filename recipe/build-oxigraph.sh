#!/usr/bin/env bash
set -eux

export RUST_BACKTRACE=1

export CARGO_HOME="$BUILD_PREFIX/cargo"
export PATH="${PATH}:${CARGO_HOME}/bin"

export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=$CC
export CARGO_TARGET_X86_64_APPLE_DARWIN_LINKER=$CC
export CARGO_TARGET_AARCH64_APPLE_DARWIN_LINKER=$CC

rustc --version

mkdir -p "${CARGO_HOME}"

if [[ $PKG_NAME == "oxigraph-server" ]]; then
    cd "${SRC_DIR}/server"
    cargo-bundle-licenses \
        --format yaml \
        --output "${SRC_DIR}/THIRDPARTY.yml"
    cargo install --root "${PREFIX}" --path .
fi

if [[ $PKG_NAME == "pyoxigraph" ]]; then
    cd "${SRC_DIR}/python"
    cargo-bundle-licenses \
        --format yaml \
        --output "${SRC_DIR}/THIRDPARTY.yml"
    maturin develop -m Cargo.toml
    "${PYTHON}" generate_stubs.py pyoxigraph pyoxigraph.pyi --black
    maturin build -strip --manylinux off --interpreter="${PYTHON}"
    "${PYTHON}" -m pip install \
        -vv \
        --ignore-installed \
        --force-reinstall \
        --no-index \
        --no-deps \
        --find-links "${SRC_DIR}/target/wheels" \
        $PKG_NAME
fi

rm -f "${PREFIX}/.crates.toml"
rm -f "${PREFIX}/.crates2.json"
