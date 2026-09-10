# Reference change patterns

This branch is the subsequent-upload fixture for MT-1676. Compare it with
`reference/baseline`, pinned at
`97f6de9374114dcca8ee9678bfb6e40d7b50a24e`.

The branches contain identical `.mo-parse` configuration. The fixture changes
only source files that Imogen Parse discovers, apart from this documentation.

## Implemented scenarios

| Scenario | Baseline | Change pattern | Expected downstream observation |
| --- | --- | --- | --- |
| Unchanged entity | All untouched sources | No change | Preserve the UUID without prompting. |
| Move only | `app/cbl/CBTRN01C.cbl` | `app/cbl/batch/CBTRN01C.cbl`; contents unchanged | Preserve the UUID and update the key when uniquely matched. |
| Case-only rename | `app/app-authorization-ims-db2-mq/cbl/CBPAUP0C.cbl` | Filename becomes `cbpaup0c.cbl`; contents unchanged | A unique case-folded path and identical hash preserve the UUID and adopt the latest key casing without prompting. |
| Program content edit | `app/cbl/CBTRN02C.cbl` | Comment added; path unchanged | Detect the content change. Identity and prompt behavior are deferred. |
| Source added | Source absent | Add self-contained `app/cbl/CBNEW01C.cbl` | Mint a new UUID. |
| Source removed | `app/jcl/WAITSTEP.jcl` invokes its sole program, `app/cbl/COBSWAIT.cbl` | Remove both files as one cohesive fixture | Preserve their identity records and mark them removed. |
| EntryPoint content edit | `app/jcl/READCUST.jcl` | Comment added; path unchanged | Detect the content change for a surviving EntryPoint. Identity and prompt behavior are deferred. |
| Cross-category duplicate Short Name | `CBEXPORT` and `CBIMPORT` each exist as both JCL EntryPoints and COBOL Programs | Leave all four sources unchanged | Ingest distinct entities with distinct UUIDs, unchanged Short Names, and no duplicate-name warning. |

## Downstream-only scenario

The manual DataSource lifecycle requires executable API/reparse test setup and
does not add a source fixture to this repository. A later test should:

1. Ingest `reference/baseline`.
2. Manually create `CUSTOMER_MASTER` with kind `DB2_TABLE`.
3. Record its UUID, kind, and Short Name.
4. Ingest `reference/change-patterns`.
5. Verify that the same DataSource remains resolvable with unchanged identity
   fields and is neither removed nor reconciled with a parse-derived entity.

## Deferred scenarios

| Scenario | Reason deferred |
| --- | --- |
| Move and edit | The ingest UX must first define how ambiguity is presented, answered, and resumed while the pipeline runs. |
| Same-category duplicate Short Name | No confirmed corpus example or agreed matching, lookup, warning, or prompt behavior exists yet. |
| Repeating every pattern by entity category | Identity rules are category-independent; the branch keeps only the additional EntryPoint content-edit coverage. |

## Parser verification

Both branches were extracted with Imogen Parse 0.94.2. The baseline produced
39 OK EntryPoints, 24 warnings, and 8 errors. This branch produced 39 OK
EntryPoints, 23 warnings, and 8 errors. The only diagnostic removed is the
pre-existing `WAITSTEP` unresolved-assembly warning; no diagnostic is added.

The move-only and case-only fixtures preserve their respective content hashes,
and `.mo-parse` has the same Git blob on both branches:
`e3af6355614ee6c2da0d8c571d6f03de77397e03`.
