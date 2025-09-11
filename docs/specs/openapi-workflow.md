# OpenAPI Workflow (PeatedAPI)

## Critical Warning

Updating the API client regenerates a large codebase and can break dependents. Work on a clean branch, commit first, and review diffs carefully.

## Why manual generation

We pre-generate code (no build plugin) for faster builds, explicit version control, and fewer prompts. Updates happen only when we run our script.

## Quick start

Preferred entry point from repo root:

```bash
./Scripts/update-api.sh
```

From package directory:

```bash
cd PeatedAPI
./update-api.sh
```

The script will:
- Download spec to `PeatedAPI/Sources/PeatedAPI/openapi.json`
- Normalize spec (3.1.1 → 3.1.0, nullable fixes, parameter schema fixes)
- Generate code into `PeatedAPI/Sources/PeatedAPI/Generated/`
- Build via Swift toolchain (or generator via `swift run`)

## Pre-update checklist

- Clean working tree (`git status`)
- On a feature branch
- Current build/tests are green
- Time allocated to adapt breaking changes

## Manual process (fallback)

```bash
# 1) Download spec
curl -o PeatedAPI/Sources/PeatedAPI/openapi.json https://api.peated.com/spec.json

# 2) Normalize (generator quirk)
sed -i '' 's/"openapi": "3.1.1"/"openapi": "3.1.0"/' PeatedAPI/Sources/PeatedAPI/openapi.json

# 3) Run preprocessors
cd PeatedAPI
./fix-nullable-fields.sh Sources/PeatedAPI/openapi.json
./fix-parameter-schemas.sh Sources/PeatedAPI/openapi.json

# 4) Generate
swift run swift-openapi-generator generate \
  --config Sources/PeatedAPI/openapi-generator-config.yaml \
  --output-directory Sources/PeatedAPI/Generated \
  Sources/PeatedAPI/openapi.json

# 5) Verify
swift build && swift test
```

## Post-update verification

- Review `git diff` for expected changes
- Build and run tests: `swift build && swift test`
- Smoke test critical flows (login, feed, create tasting, search)

## Preprocessing rules (built into script)

- OpenAPI version normalization: 3.1.1 → 3.1.0
- Nullable fields: convert `anyOf [T, null]` to `nullable: true` where appropriate
- Missing parameter schemas: inject schema objects when absent

## Example usage

```bash
# One-liner from root
./Scripts/update-api.sh && (cd PeatedAPI && swift build && swift test)
```

## Rationale (decision record)

- Separate PeatedAPI package isolates large generated code for performance
- Pre-generation avoids plugin prompts and makes API changes visible in PRs
- Scripted preprocessing stabilizes generator input for consistent output
   
   ```bash
   # DO NOT RUN THIS WITHOUT ASKING:
   # git checkout -- .  # ❌ FORBIDDEN without permission
   
   # Instead, try targeted fixes:
   
   # Try updating step by step
   ./fix-nullable-fields.sh Sources/PeatedAPI/openapi.json
   # Check if this helped
   
   ./fix-parameter-schemas.sh Sources/PeatedAPI/openapi.json
   # Check again
   
   # If you need to revert specific files, ASK FIRST
   # Explain what's broken and why reverting might help
   ```

## Troubleshooting

### Build takes forever
The generated files are large (12MB+). This is normal for the first build. Subsequent builds use cached modules.

### "Unsupported document version: 3.1.1"
The generator has a quirk with OpenAPI 3.1.1. The update script handles this automatically, but if doing manually:
```bash
sed -i '' 's/"openapi":"3.1.1"/"openapi":"3.1.0"/' openapi.json
```

### Type mismatches after update
When the API changes, you may need to update your code:
1. Check what changed in the generated Types.swift
2. Update your models to match new field names/types
3. The compiler will guide you to all places that need updates

## Best Practices

1. **Always review generated changes** - Large diffs in Types.swift indicate significant API changes
2. **Update atomically** - Don't commit partial updates; ensure everything builds
3. **Test after updates** - API changes might have semantic differences beyond types
4. **Keep specs versioned** - The openapi.json file should be in version control

## CI/CD Integration

For automated updates in CI:

```yaml
# Example GitHub Action
- name: Update API Client
  run: |
    ./Scripts/update-api-client.sh
    if git diff --quiet; then
      echo "No API changes"
    else
      echo "API changes detected"
      # Create PR with changes
    fi
```

## References

- [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator)
- [Swift OpenAPI Generator Documentation](https://swiftpackageindex.com/apple/swift-openapi-generator/documentation)
- [OpenAPI Specification](https://www.openapis.org/)
