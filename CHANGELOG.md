# Changelog

## [0.1.1] - 2026-03-18

### Fixed
- Validate `role` against `ROLES` in `join_group` — rejects invalid roles (consistent with `update_role`)
- Enforce `MAX_GROUP_MEMBERS` (50) in `join_group` — rejects groups with more than 50 members
- Add `RECIPROCITY_DIRECTIONS` constant (`[:given, :received]`) and validate in `record_reciprocity`
- Runner `record_exchange` returns error for invalid direction

## [0.1.0] - 2026-03-13

### Added
- Initial release: social group membership, multi-dimensional reputation, reciprocity tracking
- Norm violations, cohesion tracking, EMA-based reputation updates
- Standalone Client
