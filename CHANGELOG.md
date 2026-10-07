# Changelog

## [1.0.1](https://github.com/radhasgrl/data-ingestion-raw/compare/v1.0.0...v1.0.1) (2026-10-07)


### Bug Fixes

* **ingestion:** remove unescaped apostrophe from TEST params comment ([#13](https://github.com/radhasgrl/data-ingestion-raw/issues/13)) ([f27596c](https://github.com/radhasgrl/data-ingestion-raw/commit/f27596cc38d79faa45fae7cad0a6f2730f643edb))

## 1.0.0 (2026-10-07)


### Features

* add PR-based SQL validation, fix fragile Snowpipe polling, remove debug step ([#1](https://github.com/radhasgrl/data-ingestion-raw/issues/1)) ([c6e93e6](https://github.com/radhasgrl/data-ingestion-raw/commit/c6e93e65fa9a96147d9697eb10de39f2b1154d4f))
* add Reset Demo Data workflow for repeatable demo runs ([0e6eff5](https://github.com/radhasgrl/data-ingestion-raw/commit/0e6eff5d6bae4c30bb63d2628defedd4b2b8a19a))
* **ci:** add promote.yml for version-based TEST environment promotion ([#12](https://github.com/radhasgrl/data-ingestion-raw/issues/12)) ([9399774](https://github.com/radhasgrl/data-ingestion-raw/commit/9399774753c0c6a7d73d44d211cea0399ce38e11))
* **ci:** add release-please for Conventional-Commits-driven versioning ([#10](https://github.com/radhasgrl/data-ingestion-raw/issues/10)) ([d42f13d](https://github.com/radhasgrl/data-ingestion-raw/commit/d42f13d77029b588c03b0a82f539b57b7ddda948))
* **ci:** enforce Conventional Commits on PR titles ([#9](https://github.com/radhasgrl/data-ingestion-raw/issues/9)) ([cad6b94](https://github.com/radhasgrl/data-ingestion-raw/commit/cad6b947fd89114ffa01a7a293d97885b61fa523))
* scaffold data-ingestion-raw (Repo 2 of 3) ([2560f88](https://github.com/radhasgrl/data-ingestion-raw/commit/2560f88126df5bebaf1cf7844d56319d04bbe63b))


### Bug Fixes

* AWS rejects a made-up account ID even as a placeholder principal ([dea6a61](https://github.com/radhasgrl/data-ingestion-raw/commit/dea6a6110be6782c380207c6a7005808137552ce))
* ON_ERROR = ABORT_STATEMENT is not valid in a pipe definition ([43ed63f](https://github.com/radhasgrl/data-ingestion-raw/commit/43ed63ff05a9d10afe8f2b9c45a19677dd525b18))
* remove broken COPY_HISTORY diagnostic step, pipe status already confirms success ([858979f](https://github.com/radhasgrl/data-ingestion-raw/commit/858979fc0d02969d9c2a9e36490ecac9c1cb23a5))
* remove broken copy-history diagnostic, add small post-poll safety margin ([#3](https://github.com/radhasgrl/data-ingestion-raw/issues/3)) ([dc534e5](https://github.com/radhasgrl/data-ingestion-raw/commit/dc534e5270c5b004507076ead295a87902e32d05))
