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


#### one_show: optimized back reference and implemented forwad reference
Instructions

|                                        | decode() / too_candid() | encode() / from_candid() |
| :------------------------------------- | ----------------------: | -----------------------: |
| Serde 'mo:motoko_candid' lib           |           1_053_794_644 |            2_000_106_476 |
| Motoko (to_candid(), from_candid())    |               6_849_520 |               20_277_779 |
| Serde: One Shot Back Reference (BR)    |                   3_444 |              814_495_115 |
| Serde: One Shot BR sans type inference |                   4_719 |              570_941_476 |
| Serde: One Shot Forward Reference (FR) |                   5_861 |            1_002_895_852 |
| Serde: One Shot FR sans type inference |                   7_067 |              759_206_807 |


Heap

|                                        | decode() / too_candid() | encode() / from_candid() |
| :------------------------------------- | ----------------------: | -----------------------: |
| Serde 'mo:motoko_candid' lib           |              10_271_024 |               -1_831_772 |
| Motoko (to_candid(), from_candid())    |                 373_872 |                  397_408 |
| Serde: One Shot Back Reference (BR)    |                   8_904 |               14_959_180 |
| Serde: One Shot BR sans type inference |                   8_904 |               -7_202_408 |
| Serde: One Shot Forward Reference (FR) |                   8_904 |              -11_924_836 |
| Serde: One Shot FR sans type inference |                   8_904 |               -4_800_284 |

#### one_shot: br decoding

Instructions

|                                        | decode() / too_candid() | encode() / from_candid() |
| :------------------------------------- | ----------------------: | -----------------------: |
| Motoko (to_candid(), from_candid())    |               6_852_599 |               20_277_307 |
| Serde 'mo:motoko_candid' lib           |           1_054_078_235 |            2_000_977_097 |
| Serde: One Shot Back Reference (BR)    |             283_341_316 |              814_744_565 |
| Serde: One Shot BR sans type inference |             259_040_591 |              576_643_675 |
| Serde: One Shot Forward Reference (FR) |                   5_861 |            1_003_145_085 |
| Serde: One Shot FR sans type inference |                   7_067 |              765_997_023 |


Heap

|                                        | decode() / too_candid() | encode() / from_candid() |
| :------------------------------------- | ----------------------: | -----------------------: |
| Motoko (to_candid(), from_candid())    |                 374_696 |                  397_764 |
| Serde 'mo:motoko_candid' lib           |              10_441_244 |               -1_598_868 |
| Serde: One Shot Back Reference (BR)    |              17_063_820 |              -16_414_880 |
| Serde: One Shot BR sans type inference |              15_095_820 |               -9_291_632 |
| Serde: One Shot Forward Reference (FR) |                   8_904 |              -11_919_024 |
| Serde: One Shot FR sans type inference |                   8_904 |               -4_795_636 |

#### sorting user provided types before encoding or decoding

Instructions

|                                     |    decode() |    encode() |
| :---------------------------------- | ----------: | ----------: |
| Serde: One Shot                     | 298_167_258 | 864_784_948 |
| Serde: One Shot sans type inference | 343_730_830 | 654_138_729 |
| Motoko (to_candid(), from_candid()) |  21_778_910 |   7_236_572 |


Heap

|                                     |   decode() |    encode() |
| :---------------------------------- | ---------: | ----------: |
| Serde: One Shot                     | 18_078_612 | -11_697_036 |
| Serde: One Shot sans type inference | 19_894_612 |  -4_651_180 |
| Motoko (to_candid(), from_candid()) |    433_756 |     376_168 |