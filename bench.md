## Benchmarks

#### mops version `2.2.0`
Benchmarking the performance with 10k calls

Instructions

|       | to_candid() | from_candid() |      decode() |      encode() |
| :---- | ----------: | ------------: | ------------: | ------------: |
| Serde |   6_847_934 |    20_275_957 | 1_053_547_402 | 2_000_462_160 |


Heap

|       | to_candid() | from_candid() |   decode() |   encode() |
| :---- | ----------: | ------------: | ---------: | ---------: |
| Serde |     373_360 |       397_012 | 10_425_876 | -1_620_764 |


#### one_shot: backward referencing

Instructions

|                                     | decode() / too_candid() | encode() / from_candid() |
| :---------------------------------- | ----------------------: | -----------------------: |
| Serde 'mo:motoko_candid' lib        |           1_053_963_520 |            2_000_335_920 |
| Motoko (to_candid(), from_candid()) |               6_851_133 |               20_284_651 |
| Serde: One Shot                     |                   2_984 |              978_890_225 |
| Serde: One Shot sans type inference |                   4_556 |              749_880_806 |


Heap

|                                     | decode() / too_candid() | encode() / from_candid() |
| :---------------------------------- | ----------------------: | -----------------------: |
| Serde 'mo:motoko_candid' lib        |              10_271_552 |               -1_821_176 |
| Motoko (to_candid(), from_candid()) |                 374_264 |                  397_532 |
| Serde: One Shot                     |                   8_904 |              -10_726_840 |
| Serde: One Shot sans type inference |                   8_904 |               28_404_880 |
