# Changelog - Appwin SDK for Flutter

Versions follow [semantic versioning](https://semver.org).

Each Appwin artefact versions independently: a fix here does not move the iOS,
Android or React Native SDK. All four numbers live in one place, `version.json`
in the monorepo, and the release script derives every manifest and every
cross-artefact pin from it.

The three packages (`appwin_core`, `appwin_support`, `appwin_community`) are
released together and share **this** version. They pin the native iOS SDK at the
version they were tested against, which moves on its own schedule.

## 0.1.0

First release.
