# Benchmark Results


2025-12-04 19:52:06.591442556 UTC: [Canister l62sy-yx777-77777-aaabq-cai] Generating test data for all types...
2025-12-04 19:52:06.591442556 UTC: [Canister l62sy-yx777-77777-aaabq-cai] Generated test data for all types

<details>

<summary>bench/serde.bench.mo $({\color{red}+493744.32\%})$</summary>

### Benchmarking Serde

_Benchmarking the performance with 10k calls_


Instructions: ${\color{red}+34.17\\%}$
Heap: ${\color{red}+493755.30\\%}$
Stable Memory: ${\color{gray}0\\%}$
Garbage Collection: ${\color{green}-45.15\\%}$


**Instructions**

|                                     |                               decode() |                                 encode() |
| :---------------------------------- | -------------------------------------: | ---------------------------------------: |
| Serde: One Shot                     | 608_329_078 $({\color{red}+54.22\\%})$ | 1_641_783_284 $({\color{red}+48.54\\%})$ |
| Serde: One Shot sans type inference | 365_529_353 $({\color{red}+62.03\\%})$ | 1_147_192_946 $({\color{red}+28.66\\%})$ |
| Motoko (to_candid(), from_candid()) |  34_591_271 $({\color{red}+10.47\\%})$ |      9_683_738 $({\color{red}+6.86\\%})$ |
| Serde: Single Type Serializer       | 162_233_752 $({\color{red}+44.91\\%})$ |   261_905_755 $({\color{red}+17.67\\%})$ |


**Heap**

|                                     |                                  decode() |                                     encode() |
| :---------------------------------- | ----------------------------------------: | -------------------------------------------: |
| Serde: One Shot                     |      3.36 MiB $({\color{red}+122.77\\%})$ | -11.44 MiB $({\color{green}-3895448.05\\%})$ |
| Serde: One Shot sans type inference | 21.36 MiB $({\color{red}+8235304.41\\%})$ | -19.38 MiB $({\color{green}-7473098.53\\%})$ |
| Motoko (to_candid(), from_candid()) | 644.54 KiB $({\color{red}+242548.53\\%})$ |    602.96 KiB $({\color{red}+226895.59\\%})$ |
| Serde: Single Type Serializer       |  7.87 MiB $({\color{red}+3033972.06\\%})$ |     9.29 MiB $({\color{red}+3579745.59\\%})$ |


**Garbage Collection**

|                                     |                             decode() |                             encode() |
| :---------------------------------- | -----------------------------------: | -----------------------------------: |
| Serde: One Shot                     | 28.57 MiB $({\color{red}+15.94\\%})$ | 91.79 MiB $({\color{red}+46.78\\%})$ |
| Serde: One Shot sans type inference |    0 B $({\color{green}-100.00\\%})$ | 59.79 MiB $({\color{red}+76.08\\%})$ |
| Motoko (to_candid(), from_candid()) |    0 B $({\color{green}-100.00\\%})$ |    0 B $({\color{green}-100.00\\%})$ |
| Serde: Single Type Serializer       |    0 B $({\color{green}-100.00\\%})$ |    0 B $({\color{green}-100.00\\%})$ |


</details>
Saving results to .bench/serde.bench.json

<details>

<summary>bench/types.bench.mo $({\color{red}+0.74\%})$</summary>

### Benchmarking Serde by Data Types

_Performance comparison across all supported Candid data types with 10k operations_


Instructions: ${\color{red}+2.26\\%}$
Heap: ${\color{green}-1.52\\%}$
Stable Memory: ${\color{gray}0\\%}$
Garbage Collection: ${\color{gray}0\\%}$


**Instructions**

|                  |                              encode() |                encode(sans inference) |                               decode() |                 decode(sans inference) |
| :--------------- | ------------------------------------: | ------------------------------------: | -------------------------------------: | -------------------------------------: |
| Nat              |         72_692 $({\color{gray}0\\%})$ |    64_494 $({\color{green}-0.00\\%})$ |       15_787 $({\color{red}+7.63\\%})$ |       30_888 $({\color{red}+3.42\\%})$ |
| Nat8             |         72_122 $({\color{gray}0\\%})$ |    64_223 $({\color{green}-0.00\\%})$ |       15_767 $({\color{red}+9.08\\%})$ |       31_185 $({\color{red}+4.05\\%})$ |
| Nat16            |      73_423 $({\color{red}+0.20\\%})$ |      65_821 $({\color{red}+0.22\\%})$ |       16_577 $({\color{red}+7.95\\%})$ |       32_312 $({\color{red}+3.60\\%})$ |
| Nat32            |      75_057 $({\color{red}+0.01\\%})$ |      67_753 $({\color{red}+0.00\\%})$ |       17_682 $({\color{red}+6.24\\%})$ |       33_734 $({\color{red}+2.87\\%})$ |
| Nat64            |    77_741 $({\color{green}-0.09\\%})$ |    70_735 $({\color{green}-0.10\\%})$ |       19_372 $({\color{red}+3.54\\%})$ |       35_741 $({\color{red}+1.61\\%})$ |
| Int              |         75_309 $({\color{gray}0\\%})$ |    68_731 $({\color{green}-0.00\\%})$ |       18_401 $({\color{red}+6.48\\%})$ |       35_087 $({\color{red}+3.00\\%})$ |
| Int8             |         74_577 $({\color{gray}0\\%})$ |    68_298 $({\color{green}-0.00\\%})$ |       18_242 $({\color{red}+7.75\\%})$ |       35_245 $({\color{red}+3.57\\%})$ |
| Int16            |      75_878 $({\color{red}+0.19\\%})$ |      69_896 $({\color{red}+0.21\\%})$ |       19_052 $({\color{red}+6.85\\%})$ |       36_372 $({\color{red}+3.19\\%})$ |
| Int32            |      77_680 $({\color{red}+0.24\\%})$ |      71_996 $({\color{red}+0.26\\%})$ |       20_332 $({\color{red}+6.32\\%})$ |       37_969 $({\color{red}+3.02\\%})$ |
| Int64            |      80_366 $({\color{red}+0.17\\%})$ |      74_980 $({\color{red}+0.18\\%})$ |       22_022 $({\color{red}+3.94\\%})$ |       39_976 $({\color{red}+1.88\\%})$ |
| Float            |     103_392 $({\color{red}+0.69\\%})$ |      98_226 $({\color{red}+0.72\\%})$ |       50_119 $({\color{red}+2.65\\%})$ |       68_390 $({\color{red}+1.78\\%})$ |
| Bool             |         77_158 $({\color{gray}0\\%})$ |    72_317 $({\color{green}-0.00\\%})$ |       20_597 $({\color{red}+6.80\\%})$ |       39_245 $({\color{red}+3.19\\%})$ |
| Text             |    81_477 $({\color{green}-0.45\\%})$ |    76_910 $({\color{green}-0.48\\%})$ |       24_025 $({\color{red}+3.09\\%})$ |       42_935 $({\color{red}+1.47\\%})$ |
| Null             |         77_016 $({\color{gray}0\\%})$ |    72_965 $({\color{green}-0.00\\%})$ |       89_708 $({\color{red}+1.59\\%})$ |       85_009 $({\color{red}+1.57\\%})$ |
| Empty            |         77_430 $({\color{gray}0\\%})$ |    73_677 $({\color{green}-0.00\\%})$ |       90_208 $({\color{red}+1.59\\%})$ |       85_732 $({\color{red}+1.55\\%})$ |
| Principal        |    97_697 $({\color{green}-1.05\\%})$ |    94_054 $({\color{green}-1.09\\%})$ |     32_091 $({\color{green}-4.84\\%})$ |     51_962 $({\color{green}-3.22\\%})$ |
| Blob             |     248_736 $({\color{red}+2.06\\%})$ |     210_310 $({\color{red}+0.00\\%})$ |     90_867 $({\color{green}-7.72\\%})$ |    108_822 $({\color{green}-6.77\\%})$ |
| Option(Nat)      |     116_011 $({\color{red}+0.00\\%})$ |      88_984 $({\color{red}+0.00\\%})$ |       28_159 $({\color{red}+4.60\\%})$ |       46_441 $({\color{red}+2.03\\%})$ |
| Option(Text)     |   119_891 $({\color{green}-0.30\\%})$ |    92_952 $({\color{green}-0.39\\%})$ |       31_279 $({\color{red}+2.75\\%})$ |       49_828 $({\color{red}+1.07\\%})$ |
| Array(Nat8)      |     144_332 $({\color{red}+5.76\\%})$ |      91_990 $({\color{red}+0.00\\%})$ |       30_802 $({\color{red}+4.15\\%})$ |       49_723 $({\color{red}+1.90\\%})$ |
| Array(Text)      |     198_093 $({\color{red}+5.86\\%})$ |   125_319 $({\color{green}-2.00\\%})$ |     54_635 $({\color{green}-5.69\\%})$ |     73_828 $({\color{green}-4.65\\%})$ |
| Array(Record)    |     310_942 $({\color{red}+4.32\\%})$ |     212_131 $({\color{red}+3.84\\%})$ |      87_120 $({\color{red}+17.93\\%})$ |       86_410 $({\color{red}+0.23\\%})$ |
| Record(Nested)   |     798_534 $({\color{red}+4.92\\%})$ |     558_187 $({\color{red}+5.55\\%})$ |     419_202 $({\color{red}+35.43\\%})$ |    145_404 $({\color{green}-2.09\\%})$ |
| Variant(Simple)  |     160_343 $({\color{red}+6.94\\%})$ |   140_474 $({\color{green}-0.42\\%})$ |      72_029 $({\color{red}+13.24\\%})$ |       55_348 $({\color{red}+2.37\\%})$ |
| Variant(Complex) |   1_006_537 $({\color{red}+4.86\\%})$ |     839_090 $({\color{red}+3.75\\%})$ |     587_207 $({\color{red}+40.79\\%})$ |    122_988 $({\color{green}-0.84\\%})$ |
| Large Text       | 5_686_587 $({\color{green}-2.44\\%})$ | 5_687_171 $({\color{green}-2.44\\%})$ | 1_427_622 $({\color{green}-25.15\\%})$ | 1_451_684 $({\color{green}-24.84\\%})$ |
| Large Array      |  7_161_925 $({\color{red}+18.54\\%})$ |   2_735_912 $({\color{red}+0.00\\%})$ |   994_844 $({\color{green}-18.55\\%})$ | 1_016_990 $({\color{green}-18.24\\%})$ |
| Deep Nesting     |     648_113 $({\color{red}+3.30\\%})$ |     454_050 $({\color{red}+4.71\\%})$ |     146_301 $({\color{red}+16.96\\%})$ |      122_856 $({\color{red}+0.84\\%})$ |
| Wide Record      |   826_163 $({\color{green}-2.83\\%})$ |   492_118 $({\color{green}-2.96\\%})$ |     540_797 $({\color{red}+60.56\\%})$ |    325_083 $({\color{green}-1.48\\%})$ |


**Heap**

|                  |                                encode() |                  encode(sans inference) |                               decode() |                 decode(sans inference) |
| :--------------- | --------------------------------------: | --------------------------------------: | -------------------------------------: | -------------------------------------: |
| Nat              |        19.73 KiB $({\color{gray}0\\%})$ |   16.88 KiB $({\color{green}-0.02\\%})$ |    10.43 KiB $({\color{red}+0.79\\%})$ |    10.37 KiB $({\color{red}+0.76\\%})$ |
| Nat8             |        19.72 KiB $({\color{gray}0\\%})$ |   16.86 KiB $({\color{green}-0.02\\%})$ |    10.43 KiB $({\color{red}+1.18\\%})$ |    10.37 KiB $({\color{red}+1.14\\%})$ |
| Nat16            |     19.75 KiB $({\color{red}+0.10\\%})$ |     16.89 KiB $({\color{red}+0.09\\%})$ |    10.43 KiB $({\color{red}+0.98\\%})$ |    10.37 KiB $({\color{red}+0.95\\%})$ |
| Nat32            |     19.76 KiB $({\color{red}+0.14\\%})$ |     16.91 KiB $({\color{red}+0.14\\%})$ |    10.43 KiB $({\color{red}+0.60\\%})$ |    10.37 KiB $({\color{red}+0.57\\%})$ |
| Nat64            |      19.8 KiB $({\color{red}+0.22\\%})$ |     16.94 KiB $({\color{red}+0.23\\%})$ |  10.44 KiB $({\color{green}-0.15\\%})$ |  10.38 KiB $({\color{green}-0.19\\%})$ |
| Int              |        19.73 KiB $({\color{gray}0\\%})$ |   16.88 KiB $({\color{green}-0.02\\%})$ |    10.43 KiB $({\color{red}+0.79\\%})$ |    10.37 KiB $({\color{red}+0.76\\%})$ |
| Int8             |        19.72 KiB $({\color{gray}0\\%})$ |   16.86 KiB $({\color{green}-0.02\\%})$ |    10.43 KiB $({\color{red}+1.18\\%})$ |    10.37 KiB $({\color{red}+1.14\\%})$ |
| Int16            |     19.75 KiB $({\color{red}+0.10\\%})$ |     16.89 KiB $({\color{red}+0.09\\%})$ |    10.43 KiB $({\color{red}+0.98\\%})$ |    10.37 KiB $({\color{red}+0.95\\%})$ |
| Int32            |     19.77 KiB $({\color{red}+0.20\\%})$ |     16.92 KiB $({\color{red}+0.21\\%})$ |    10.44 KiB $({\color{red}+0.72\\%})$ |    10.38 KiB $({\color{red}+0.68\\%})$ |
| Int64            |     19.81 KiB $({\color{red}+0.30\\%})$ |     16.96 KiB $({\color{red}+0.32\\%})$ |       10.46 KiB $({\color{gray}0\\%})$ |   10.4 KiB $({\color{green}-0.04\\%})$ |
| Float            |     20.48 KiB $({\color{red}+0.19\\%})$ |     17.63 KiB $({\color{red}+0.20\\%})$ |    11.24 KiB $({\color{red}+0.74\\%})$ |    11.18 KiB $({\color{red}+0.70\\%})$ |
| Bool             |        19.72 KiB $({\color{gray}0\\%})$ |   16.86 KiB $({\color{green}-0.02\\%})$ |    10.43 KiB $({\color{red}+1.18\\%})$ |    10.37 KiB $({\color{red}+1.14\\%})$ |
| Text             |   19.75 KiB $({\color{green}-0.18\\%})$ |   16.89 KiB $({\color{green}-0.23\\%})$ |       10.52 KiB $({\color{gray}0\\%})$ |  10.46 KiB $({\color{green}-0.04\\%})$ |
| Null             |        19.68 KiB $({\color{gray}0\\%})$ |   16.83 KiB $({\color{green}-0.02\\%})$ |    20.26 KiB $({\color{red}+0.70\\%})$ |    17.32 KiB $({\color{red}+0.80\\%})$ |
| Empty            |        19.68 KiB $({\color{gray}0\\%})$ |   16.83 KiB $({\color{green}-0.02\\%})$ |    20.26 KiB $({\color{red}+0.70\\%})$ |    17.32 KiB $({\color{red}+0.80\\%})$ |
| Principal        |   19.91 KiB $({\color{green}-0.62\\%})$ |   17.05 KiB $({\color{green}-0.75\\%})$ |  10.66 KiB $({\color{green}-4.21\\%})$ |   10.6 KiB $({\color{green}-4.27\\%})$ |
| Blob             |     28.84 KiB $({\color{red}+2.27\\%})$ |   22.04 KiB $({\color{green}-0.02\\%})$ | 14.21 KiB $({\color{green}-10.79\\%})$ | 13.93 KiB $({\color{green}-11.09\\%})$ |
| Option(Nat)      |        22.75 KiB $({\color{gray}0\\%})$ |   17.29 KiB $({\color{green}-0.02\\%})$ |    10.74 KiB $({\color{red}+0.73\\%})$ |    10.46 KiB $({\color{red}+0.56\\%})$ |
| Option(Text)     |   22.77 KiB $({\color{green}-0.15\\%})$ |   17.32 KiB $({\color{green}-0.23\\%})$ |  10.84 KiB $({\color{green}-0.04\\%})$ |  10.55 KiB $({\color{green}-0.22\\%})$ |
| Array(Nat8)      |     25.22 KiB $({\color{red}+3.13\\%})$ |   17.39 KiB $({\color{green}-0.02\\%})$ |    10.89 KiB $({\color{red}+0.72\\%})$ |    10.61 KiB $({\color{red}+0.56\\%})$ |
| Array(Text)      |     26.36 KiB $({\color{red}+3.01\\%})$ |   17.77 KiB $({\color{green}-1.39\\%})$ |  11.68 KiB $({\color{green}-6.77\\%})$ |  11.39 KiB $({\color{green}-7.07\\%})$ |
| Array(Record)    |      33.5 KiB $({\color{red}+2.82\\%})$ |     21.23 KiB $({\color{red}+1.21\\%})$ |     14.2 KiB $({\color{red}+3.44\\%})$ |  12.96 KiB $({\color{green}-0.78\\%})$ |
| Record(Nested)   |     55.37 KiB $({\color{red}+3.49\\%})$ |     32.36 KiB $({\color{red}+3.05\\%})$ |   26.23 KiB $({\color{red}+12.18\\%})$ |  16.11 KiB $({\color{green}-4.98\\%})$ |
| Variant(Simple)  |     25.58 KiB $({\color{red}+5.15\\%})$ |   18.38 KiB $({\color{green}-0.21\\%})$ |    12.48 KiB $({\color{red}+2.63\\%})$ |    10.62 KiB $({\color{red}+1.12\\%})$ |
| Variant(Complex) |      66.8 KiB $({\color{red}+4.82\\%})$ |     42.62 KiB $({\color{red}+2.55\\%})$ |   31.35 KiB $({\color{red}+18.13\\%})$ |  14.52 KiB $({\color{green}-3.20\\%})$ |
| Large Text       | 123.98 KiB $({\color{green}-13.40\\%})$ | 121.13 KiB $({\color{green}-13.67\\%})$ | 39.23 KiB $({\color{green}-70.93\\%})$ | 39.18 KiB $({\color{green}-70.96\\%})$ |
| Large Array      |   273.89 KiB $({\color{red}+22.27\\%})$ |    90.6 KiB $({\color{green}-0.00\\%})$ | 38.51 KiB $({\color{green}-54.49\\%})$ | 38.23 KiB $({\color{green}-54.69\\%})$ |
| Deep Nesting     |     54.22 KiB $({\color{red}+1.98\\%})$ |     30.07 KiB $({\color{red}+3.27\\%})$ |    18.3 KiB $({\color{red}+10.13\\%})$ |    15.09 KiB $({\color{red}+0.52\\%})$ |
| Wide Record      |     45.81 KiB $({\color{red}+2.60\\%})$ |     27.46 KiB $({\color{red}+4.32\\%})$ |   36.48 KiB $({\color{red}+22.92\\%})$ |  27.13 KiB $({\color{green}-3.68\\%})$ |


**Garbage Collection**

|                  |                   encode() |     encode(sans inference) |                   decode() |     decode(sans inference) |
| :--------------- | -------------------------: | -------------------------: | -------------------------: | -------------------------: |
| Nat              | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Nat8             | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Nat16            | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Nat32            | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Nat64            | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Int              | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Int8             | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Int16            | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Int32            | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Int64            | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Float            | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Bool             | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Text             | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Null             | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Empty            | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Principal        | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Blob             | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Option(Nat)      | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Option(Text)     | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Array(Nat8)      | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Array(Text)      | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Array(Record)    | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Record(Nested)   | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Variant(Simple)  | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Variant(Complex) | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Large Text       | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Large Array      | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Deep Nesting     | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| Wide Record      | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |


</details>
Saving results to .bench/types.bench.json
