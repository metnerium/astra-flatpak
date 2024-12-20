## Манифест для сборки Kcalc 
```json
{
    "app-id": "org.astra.Kcalc",
    "runtime": "org.astra.Qt",
    "runtime-version": "1.8",
    "sdk": "org.astra.qtSdk",
    "command": "kcalc",
    "build-options": {
        "no-debuginfo": true,
        "strip": false
    },
    "finish-args": [
        "--share=ipc",
        "--socket=x11",
        "--socket=wayland",
        "--device=dri",
        "--filesystem=host"
    ],
    "modules": [
        {
            "name": "gmp",
            "sources": [
                {
                    "type": "archive",
                    "url": "https://gmplib.org/download/gmp/gmp-6.2.1.tar.xz",
                    "sha256": "fd4829912cddd12f84181c3451cc752be224643e87fac497b69edddadc49b4f2"
                }
            ]
        },
        {
            "name": "mpfr",
            "sources": [
                {
                    "type": "archive",
                    "url": "https://www.mpfr.org/mpfr-current/mpfr-4.2.1.tar.xz",
                    "sha256": "277807353a6726978996945af13e52829e3abd7a9a5b7fb2793894e18f1fcbb2"
                }
            ]
        },
        {
            "name": "kcalc",
            "buildsystem": "cmake-ninja",
            "config-opts": [
                "-DCMAKE_BUILD_TYPE=Release",
                "-DCMAKE_INSTALL_PREFIX=/app",
                "-DBUILD_TESTING=OFF",
                "-DKDE_SKIP_TEST_SETTINGS=ON",
                "-DKDE_INSTALL_USE_QT_SYS_PATHS=ON"
            ],
            "sources": [
                {
                    "type": "archive",
                    "path": "kcalc-22.12.3.tar.xz",
                    "strip-components": "1"
                }
            ]
        }
    ]
}
```
