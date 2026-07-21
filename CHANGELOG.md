## 2.1.3 - 2026-07-22

### Added

* Added optional `filters` support to GET index requests through `HosteDayClient.get()`.
* Added Laravel-compatible encoding for single and multiple filter values, such as
  `filters[status]=active` and `filters[status][]=active`.