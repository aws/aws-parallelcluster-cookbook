# Limitations

## Package Availability

The `line` cookbook does not install or manage an upstream software package. It provides Chef custom
resources that edit local files, so there are no APT, DNF/YUM, Zypper, architecture, or upstream
version availability constraints to document.

## Architecture Limitations

No architecture-specific package limitations are known.

## Source/Compiled Installation

There is no source or compiled installation path for this cookbook.

## Known Issues

* The resources process target files in memory, so very large files can be expensive to edit.
* Scientific Linux reached end of life on June 30, 2024 and is no longer declared as supported.
