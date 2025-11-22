# Benchmark Results


2025-11-22 22:18:12.417301915 UTC: [Canister l62sy-yx777-77777-aaabq-cai] Generating test data for all types...
2025-11-22 22:18:12.417301915 UTC: [Canister l62sy-yx777-77777-aaabq-cai] Generated test data for all types

<details>

<summary>bench/serde.bench.mo $({\color{red}+490944.44\%})$</summary>

### Benchmarking Serde

_Benchmarking the performance with 10k calls_


Instructions: ${\color{red}+29.97\\%}$
Heap: ${\color{red}+490959.62\\%}$
Stable Memory: ${\color{gray}0\\%}$
Garbage Collection: ${\color{green}-45.15\\%}$


**Instructions**

|                                     |                               decode() |                                 encode() |
| :---------------------------------- | -------------------------------------: | ---------------------------------------: |
| Serde: One Shot                     | 580_419_885 $({\color{red}+47.14\\%})$ | 1_583_526_541 $({\color{red}+43.27\\%})$ |
| Serde: One Shot sans type inference | 347_444_140 $({\color{red}+54.02\\%})$ | 1_122_563_777 $({\color{red}+25.89\\%})$ |
| Motoko (to_candid(), from_candid()) |   33_945_881 $({\color{red}+8.40\\%})$ |      9_618_499 $({\color{red}+6.14\\%})$ |
| Serde: Single Type Serializer       | 155_793_437 $({\color{red}+39.16\\%})$ |   257_579_501 $({\color{red}+15.72\\%})$ |


**Heap**

|                                     |                                  decode() |                                     encode() |
| :---------------------------------- | ----------------------------------------: | -------------------------------------------: |
| Serde: One Shot                     |      3.36 MiB $({\color{red}+122.78\\%})$ | -11.48 MiB $({\color{green}-3907764.94\\%})$ |
| Serde: One Shot sans type inference | 21.36 MiB $({\color{red}+8232835.29\\%})$ | -19.39 MiB $({\color{green}-7476414.71\\%})$ |
| Motoko (to_candid(), from_candid()) | 643.85 KiB $({\color{red}+242289.71\\%})$ |    602.54 KiB $({\color{red}+226736.76\\%})$ |
| Serde: Single Type Serializer       |  7.86 MiB $({\color{red}+3031514.71\\%})$ |     9.28 MiB $({\color{red}+3578357.35\\%})$ |


**Garbage Collection**

|                                     |                             decode() |                             encode() |
| :---------------------------------- | -----------------------------------: | -----------------------------------: |
| Serde: One Shot                     | 28.56 MiB $({\color{red}+15.91\\%})$ | 91.79 MiB $({\color{red}+46.79\\%})$ |
| Serde: One Shot sans type inference |    0 B $({\color{green}-100.00\\%})$ | 59.79 MiB $({\color{red}+76.10\\%})$ |
| Motoko (to_candid(), from_candid()) |    0 B $({\color{green}-100.00\\%})$ |    0 B $({\color{green}-100.00\\%})$ |
| Serde: Single Type Serializer       |    0 B $({\color{green}-100.00\\%})$ |    0 B $({\color{green}-100.00\\%})$ |


</details>
Saving results to .bench/serde.bench.json

<details>

<summary>bench/types.bench.mo $({\color{green}-3.35\%})$</summary>

### Benchmarking Serde by Data Types

_Performance comparison across all supported Candid data types with 10k operations_


Instructions: ${\color{green}-1.83\\%}$
Heap: ${\color{green}-1.52\\%}$
Stable Memory: ${\color{gray}0\\%}$
Garbage Collection: ${\color{gray}0\\%}$


**Instructions**

|                  |                              encode() |                encode(sans inference) |                               decode() |                 decode(sans inference) |
| :--------------- | ------------------------------------: | ------------------------------------: | -------------------------------------: | -------------------------------------: |
| Nat              |    67_124 $({\color{green}-7.66\\%})$ |    61_228 $({\color{green}-5.07\\%})$ |       15_086 $({\color{red}+2.85\\%})$ |       30_234 $({\color{red}+1.23\\%})$ |
| Nat8             |    66_554 $({\color{green}-7.72\\%})$ |    60_957 $({\color{green}-5.09\\%})$ |       15_066 $({\color{red}+4.23\\%})$ |       30_531 $({\color{red}+1.87\\%})$ |
| Nat16            |    67_835 $({\color{green}-7.43\\%})$ |    62_535 $({\color{green}-4.78\\%})$ |       15_876 $({\color{red}+3.39\\%})$ |       31_658 $({\color{red}+1.51\\%})$ |
| Nat32            |    69_469 $({\color{green}-7.44\\%})$ |    64_467 $({\color{green}-4.85\\%})$ |       16_981 $({\color{red}+2.03\\%})$ |       33_080 $({\color{red}+0.88\\%})$ |
| Nat64            |    72_153 $({\color{green}-7.27\\%})$ |    67_449 $({\color{green}-4.74\\%})$ |     18_651 $({\color{green}-0.31\\%})$ |     35_067 $({\color{green}-0.31\\%})$ |
| Int              |    69_741 $({\color{green}-7.39\\%})$ |    65_465 $({\color{green}-4.76\\%})$ |       17_700 $({\color{red}+2.42\\%})$ |       34_433 $({\color{red}+1.08\\%})$ |
| Int8             |    69_009 $({\color{green}-7.47\\%})$ |    65_032 $({\color{green}-4.79\\%})$ |       17_541 $({\color{red}+3.61\\%})$ |       34_591 $({\color{red}+1.65\\%})$ |
| Int16            |    70_290 $({\color{green}-7.18\\%})$ |    66_610 $({\color{green}-4.50\\%})$ |       18_351 $({\color{red}+2.92\\%})$ |       35_718 $({\color{red}+1.33\\%})$ |
| Int32            |    72_072 $({\color{green}-6.99\\%})$ |    68_690 $({\color{green}-4.35\\%})$ |       19_610 $({\color{red}+2.55\\%})$ |       37_294 $({\color{red}+1.19\\%})$ |
| Int64            |    74_758 $({\color{green}-6.82\\%})$ |    71_674 $({\color{green}-4.23\\%})$ |       21_281 $({\color{red}+0.44\\%})$ |       39_282 $({\color{red}+0.11\\%})$ |
| Float            |    97_334 $({\color{green}-5.21\\%})$ |    94_470 $({\color{green}-3.13\\%})$ |       48_905 $({\color{red}+0.16\\%})$ |       67_223 $({\color{red}+0.04\\%})$ |
| Bool             |    71_590 $({\color{green}-7.22\\%})$ |    69_051 $({\color{green}-4.52\\%})$ |       19_896 $({\color{red}+3.17\\%})$ |       38_591 $({\color{red}+1.48\\%})$ |
| Text             |    75_910 $({\color{green}-7.25\\%})$ |    73_645 $({\color{green}-4.70\\%})$ |     23_251 $({\color{green}-0.24\\%})$ |     42_208 $({\color{green}-0.25\\%})$ |
| Null             |    71_484 $({\color{green}-7.18\\%})$ |    69_740 $({\color{green}-4.42\\%})$ |     83_611 $({\color{green}-5.31\\%})$ |     81_292 $({\color{green}-2.87\\%})$ |
| Empty            |    71_898 $({\color{green}-7.14\\%})$ |    70_452 $({\color{green}-4.38\\%})$ |     84_111 $({\color{green}-5.28\\%})$ |     82_015 $({\color{green}-2.85\\%})$ |
| Principal        |    92_117 $({\color{green}-6.70\\%})$ |    90_776 $({\color{green}-4.54\\%})$ |     31_330 $({\color{green}-7.09\\%})$ |     51_248 $({\color{green}-4.55\\%})$ |
| Blob             |   235_498 $({\color{green}-3.37\\%})$ |   202_694 $({\color{green}-3.62\\%})$ |    86_017 $({\color{green}-12.65\\%})$ |   104_240 $({\color{green}-10.70\\%})$ |
| Option(Nat)      |   107_868 $({\color{green}-7.02\\%})$ |    85_360 $({\color{green}-4.07\\%})$ |       27_137 $({\color{red}+0.80\\%})$ |       45_687 $({\color{red}+0.38\\%})$ |
| Option(Text)     |   111_744 $({\color{green}-7.07\\%})$ |    89_324 $({\color{green}-4.28\\%})$ |     30_184 $({\color{green}-0.84\\%})$ |     49_001 $({\color{green}-0.61\\%})$ |
| Array(Nat8)      |   134_174 $({\color{green}-1.68\\%})$ |    88_266 $({\color{green}-4.05\\%})$ |       29_632 $({\color{red}+0.19\\%})$ |       48_821 $({\color{red}+0.05\\%})$ |
| Array(Text)      |     187_222 $({\color{red}+0.05\\%})$ |   121_442 $({\color{green}-5.03\\%})$ |     52_806 $({\color{green}-8.85\\%})$ |     72_267 $({\color{green}-6.66\\%})$ |
| Array(Record)    |   294_518 $({\color{green}-1.19\\%})$ |     205_847 $({\color{red}+0.76\\%})$ |      83_171 $({\color{red}+12.58\\%})$ |     83_490 $({\color{green}-3.16\\%})$ |
| Record(Nested)   |     766_477 $({\color{red}+0.71\\%})$ |     545_208 $({\color{red}+3.10\\%})$ |     407_131 $({\color{red}+31.53\\%})$ |    139_591 $({\color{green}-6.01\\%})$ |
| Variant(Simple)  |     149_994 $({\color{red}+0.04\\%})$ |   136_283 $({\color{green}-3.39\\%})$ |       69_627 $({\color{red}+9.46\\%})$ |       54_459 $({\color{red}+0.72\\%})$ |
| Variant(Complex) |     966_596 $({\color{red}+0.70\\%})$ |     819_798 $({\color{red}+1.36\\%})$ |     572_853 $({\color{red}+37.34\\%})$ |    118_460 $({\color{green}-4.49\\%})$ |
| Large Text       | 5_680_884 $({\color{green}-2.54\\%})$ | 5_683_770 $({\color{green}-2.50\\%})$ | 1_426_848 $({\color{green}-25.19\\%})$ | 1_450_957 $({\color{green}-24.88\\%})$ |
| Large Array      |  7_009_823 $({\color{red}+16.02\\%})$ | 2_700_668 $({\color{green}-1.29\\%})$ |   962_246 $({\color{green}-21.22\\%})$ |   984_660 $({\color{green}-20.84\\%})$ |
| Deep Nesting     |   616_404 $({\color{green}-1.75\\%})$ |     442_699 $({\color{red}+2.09\\%})$ |     138_618 $({\color{red}+10.82\\%})$ |    118_081 $({\color{green}-3.08\\%})$ |
| Wide Record      |   801_688 $({\color{green}-5.71\\%})$ |   483_081 $({\color{green}-4.75\\%})$ |     516_796 $({\color{red}+53.44\\%})$ |    309_985 $({\color{green}-6.05\\%})$ |


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
