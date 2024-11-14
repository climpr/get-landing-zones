# Get Landing Zones

This action outputs a list of Landing Zone objects with information about the landing zone.

## How to use this action

It is called as a step like this:

It requires the repository to be checked out before use.

```yaml
# ...
steps:
  - name: Checkout repository
    uses: actions/checkout@v4

  - name: Get Landing Zones
    id: get-landing-zones
    uses: climpr/get-landing-zones@v1
    with:
      root-landing-zones-path: lz-management/landing-zones
# ...
```

## Parameters

### `root-landing-zones-path`

Root directory for Landing Zones. Supports multi-line input.

### `pattern`

If this parameter is specified, only the Landing Zones matching the specified regex pattern is included.

> NOTE: This pattern is matched against the Landing Zone **directory**. I.e. `sample-landing-zone` in the following directory structure: `lz-management/landing-zones/sample-landing-zone/metadata.json`.

### `filter-on-changed-files`

Include only changed files. Supports 'true' or 'false'.

## Outputs

The action returns a list of Landing Zone objects. They look like this:

```jsonc
[
  {
    "Name": "string", // The name of the Landing Zone
    "LandingZonePath": "string", // The relative path of the Landing Zone
    "Deploy": "string" // A boolean that specifies if the Landing Zone is included or not
  }
]
```
