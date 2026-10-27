# Runtime hardware licenses implementation plan

**Goal:** ONEC_USE_HW_LICENSES=0|1, default 0, for both images and arbitrary UID.
**Architecture:** entrypoint validates the value and updates the documented
user configuration $HOME/.1C/1cestart/1cestart.cfg in UTF-16LE. Global
/opt configuration remains owned by root. Preserve other user settings;
when no user file exists, seed from the global file if available.
**Tech stack:** Bash, iconv (libc-bin), GitHub Actions.
**Approved interface:** user's 2026-10-27 request and preceding explanation.
Implementation choice: use the platform's supported user configuration
instead of making the global file writable or requiring root.

Source: https://1c-dn.com/library/tutorials/1c_enterprise_administrator_guide_file_mode_8_3_27/
Appendix 3.6 documents the user file and UTF-16LE format.

- [ ] Add tests for default/0/1, invalid and empty values, existing UTF-8 and
  UTF-16LE settings, duplicate keys, repeated startup, read-only file.
  Run in Check on Actions and observe RED before implementation.
- [ ] Add focused runtime helper, invoke after HOME initialization, copy
  into both images. Empty explicit value is invalid; absent means 0.
  Use private temporary files and atomic replacement; report failures.
- [ ] Extend full runtime smoke tests for default and arbitrary UID,
  value 1 and invalid input; run Check and full image builds on Actions.
- [ ] Document docker/Jenkins usage and precedence; record results.

Scope: no license provisioning, registry publication or project release.
Existing IMAGE_VERSION=1.0 remains the unreleased development version.
