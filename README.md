# Benchmark Results


2025-11-22 22:26:17.578544107 UTC: [Canister l62sy-yx777-77777-aaabq-cai] Generating test data for all types...
2025-11-22 22:26:17.578544107 UTC: [Canister l62sy-yx777-77777-aaabq-cai] Generated test data for all types

<details>

<summary>bench/serde.bench.mo $({\color{red}+2.21\%})$</summary>

### Benchmarking Serde

_Benchmarking the performance with 10k calls_


Instructions: ${\color{red}+0.47\\%}$
Heap: ${\color{green}-0.01\\%}$
Stable Memory: ${\color{gray}0\\%}$
Garbage Collection: ${\color{red}+1.75\\%}$


**Instructions**

|                                     |                                decode() |                                encode() |
| :---------------------------------- | --------------------------------------: | --------------------------------------: |
| Serde: One Shot                     | 394_433_750 $({\color{green}-0.01\\%})$ | 1_143_639_513 $({\color{red}+3.47\\%})$ |
| Serde: One Shot sans type inference | 225_556_914 $({\color{green}-0.01\\%})$ |   892_444_207 $({\color{red}+0.09\\%})$ |
| Motoko (to_candid(), from_candid()) |  31_297_307 $({\color{green}-0.05\\%})$ |   9_046_014 $({\color{green}-0.17\\%})$ |
| Serde: Single Type Serializer       | 111_925_859 $({\color{green}-0.03\\%})$ |   223_626_155 $({\color{red}+0.47\\%})$ |


**Heap**

|                                     |                             decode() |                     encode() |
| :---------------------------------- | -----------------------------------: | ---------------------------: |
| Serde: One Shot                     | 1.51 MiB $({\color{green}-0.05\\%})$ | 308 B $({\color{gray}0\\%})$ |
| Serde: One Shot sans type inference |         272 B $({\color{gray}0\\%})$ | 272 B $({\color{gray}0\\%})$ |
| Motoko (to_candid(), from_candid()) |         272 B $({\color{gray}0\\%})$ | 272 B $({\color{gray}0\\%})$ |
| Serde: Single Type Serializer       |         272 B $({\color{gray}0\\%})$ | 272 B $({\color{gray}0\\%})$ |


**Garbage Collection**

|                                     |                               decode() |                             encode() |
| :---------------------------------- | -------------------------------------: | -----------------------------------: |
| Serde: One Shot                     |  24.64 MiB $({\color{green}-0.01\\%})$ |  67.67 MiB $({\color{red}+8.22\\%})$ |
| Serde: One Shot sans type inference |  17.55 MiB $({\color{green}-0.01\\%})$ |  34.33 MiB $({\color{red}+1.12\\%})$ |
| Motoko (to_candid(), from_candid()) | 542.29 KiB $({\color{green}-0.03\\%})$ | 597.19 KiB $({\color{red}+0.00\\%})$ |
| Serde: Single Type Serializer       |   6.52 MiB $({\color{green}-0.03\\%})$ |    8.4 MiB $({\color{red}+4.75\\%})$ |


</details>
Saving results to .bench/serde.bench.json

<details>

<summary>bench/types.bench.mo $({\color{green}-129.53\%})$</summary>

### Benchmarking Serde by Data Types

_Performance comparison across all supported Candid data types with 10k operations_


Instructions: ${\color{green}-31.24\\%}$
Heap: ${\color{green}-98.29\\%}$
Stable Memory: ${\color{gray}0\\%}$
Garbage Collection: ${\color{gray}0\\%}$


**Instructions**

|                  |                              encode() |                 encode(sans inference) |                               decode() |                 decode(sans inference) |
| :--------------- | ------------------------------------: | -------------------------------------: | -------------------------------------: | -------------------------------------: |
| Nat              |   33_442 $({\color{green}-53.99\\%})$ |    39_615 $({\color{green}-38.58\\%})$ |     9_853 $({\color{green}-32.83\\%})$ |    23_584 $({\color{green}-21.03\\%})$ |
| Nat8             |   32_868 $({\color{green}-54.43\\%})$ |    39_343 $({\color{green}-38.74\\%})$ |     9_782 $({\color{green}-32.33\\%})$ |    23_830 $({\color{green}-20.49\\%})$ |
| Nat16            |   33_942 $({\color{green}-53.68\\%})$ |    40_717 $({\color{green}-38.00\\%})$ |    10_538 $({\color{green}-31.38\\%})$ |    24_903 $({\color{green}-20.15\\%})$ |
| Nat32            |   35_460 $({\color{green}-52.75\\%})$ |    42_536 $({\color{green}-37.22\\%})$ |    11_588 $({\color{green}-30.37\\%})$ |    26_270 $({\color{green}-19.89\\%})$ |
| Nat64            |   37_969 $({\color{green}-51.20\\%})$ |    45_346 $({\color{green}-35.96\\%})$ |    13_084 $({\color{green}-30.07\\%})$ |    28_083 $({\color{green}-20.16\\%})$ |
| Int              |   35_787 $({\color{green}-52.48\\%})$ |    43_575 $({\color{green}-36.60\\%})$ |    12_202 $({\color{green}-29.39\\%})$ |    27_518 $({\color{green}-19.22\\%})$ |
| Int8             |   35_053 $({\color{green}-53.00\\%})$ |    43_143 $({\color{green}-36.83\\%})$ |    11_992 $({\color{green}-29.17\\%})$ |    27_625 $({\color{green}-18.82\\%})$ |
| Int16            |   36_209 $({\color{green}-52.19\\%})$ |    44_517 $({\color{green}-36.18\\%})$ |    12_748 $({\color{green}-28.51\\%})$ |    28_698 $({\color{green}-18.58\\%})$ |
| Int32            |   37_716 $({\color{green}-51.33\\%})$ |    46_407 $({\color{green}-35.38\\%})$ |    13_835 $({\color{green}-27.65\\%})$ |    30_102 $({\color{green}-18.33\\%})$ |
| Int64            |   40_186 $({\color{green}-49.91\\%})$ |    49_219 $({\color{green}-34.24\\%})$ |    15_331 $({\color{green}-27.64\\%})$ |    31_915 $({\color{green}-18.67\\%})$ |
| Float            |   59_791 $({\color{green}-41.77\\%})$ |    69_059 $({\color{green}-29.18\\%})$ |    39_863 $({\color{green}-18.36\\%})$ |    56_764 $({\color{green}-15.52\\%})$ |
| Bool             |   37_336 $({\color{green}-51.61\\%})$ |    46_887 $({\color{green}-35.17\\%})$ |    14_082 $({\color{green}-26.98\\%})$ |    31_360 $({\color{green}-17.54\\%})$ |
| Text             |   41_402 $({\color{green}-49.41\\%})$ |    51_233 $({\color{green}-33.70\\%})$ |    16_956 $({\color{green}-27.25\\%})$ |    34_496 $({\color{green}-18.47\\%})$ |
| Null             |   37_286 $({\color{green}-51.59\\%})$ |    47_738 $({\color{green}-34.58\\%})$ |    45_104 $({\color{green}-48.92\\%})$ |    55_395 $({\color{green}-33.82\\%})$ |
| Empty            |   37_642 $({\color{green}-51.39\\%})$ |    48_395 $({\color{green}-34.32\\%})$ |    45_545 $({\color{green}-48.71\\%})$ |    56_062 $({\color{green}-33.59\\%})$ |
| Principal        |   56_639 $({\color{green}-42.63\\%})$ |    67_401 $({\color{green}-29.12\\%})$ |    24_717 $({\color{green}-26.70\\%})$ |    43_218 $({\color{green}-19.50\\%})$ |
| Blob             |  149_277 $({\color{green}-38.75\\%})$ |   148_555 $({\color{green}-29.36\\%})$ |    54_077 $({\color{green}-45.08\\%})$ |    72_206 $({\color{green}-38.14\\%})$ |
| Option(Nat)      |   57_276 $({\color{green}-50.63\\%})$ |    60_197 $({\color{green}-32.35\\%})$ |    19_063 $({\color{green}-29.19\\%})$ |    37_519 $({\color{green}-17.57\\%})$ |
| Option(Text)     |   60_891 $({\color{green}-49.36\\%})$ |    63_927 $({\color{green}-31.49\\%})$ |    21_620 $({\color{green}-28.98\\%})$ |    40_343 $({\color{green}-18.17\\%})$ |
| Array(Nat8)      |   70_840 $({\color{green}-48.09\\%})$ |    62_445 $({\color{green}-32.12\\%})$ |    20_536 $({\color{green}-30.56\\%})$ |    39_631 $({\color{green}-18.78\\%})$ |
| Array(Text)      |  116_466 $({\color{green}-37.76\\%})$ |    92_831 $({\color{green}-27.40\\%})$ |    39_696 $({\color{green}-31.48\\%})$ |    59_063 $({\color{green}-23.72\\%})$ |
| Array(Record)    |  185_332 $({\color{green}-37.82\\%})$ |   156_656 $({\color{green}-23.32\\%})$ |    55_241 $({\color{green}-25.22\\%})$ |    60_401 $({\color{green}-29.94\\%})$ |
| Record(Nested)   |  530_923 $({\color{green}-30.24\\%})$ |   426_403 $({\color{green}-19.37\\%})$ |    285_998 $({\color{green}-7.61\\%})$ |    97_357 $({\color{green}-34.45\\%})$ |
| Variant(Simple)  |   83_944 $({\color{green}-44.01\\%})$ |   103_607 $({\color{green}-26.55\\%})$ |    51_936 $({\color{green}-18.35\\%})$ |    45_003 $({\color{green}-16.77\\%})$ |
| Variant(Complex) |  659_943 $({\color{green}-31.25\\%})$ |   630_016 $({\color{green}-22.10\\%})$ |    413_052 $({\color{green}-0.97\\%})$ |    84_789 $({\color{green}-31.64\\%})$ |
| Large Text       | 5_516_208 $({\color{green}-5.37\\%})$ |  5_531_190 $({\color{green}-5.12\\%})$ | 1_385_413 $({\color{green}-27.36\\%})$ | 1_408_105 $({\color{green}-27.10\\%})$ |
| Large Array      | 5_856_631 $({\color{green}-3.07\\%})$ | 2_436_585 $({\color{green}-10.94\\%})$ |   758_620 $({\color{green}-37.89\\%})$ |   780_981 $({\color{green}-37.21\\%})$ |
| Deep Nesting     |  387_666 $({\color{green}-38.21\\%})$ |   335_632 $({\color{green}-22.60\\%})$ |    86_149 $({\color{green}-31.13\\%})$ |    82_208 $({\color{green}-32.53\\%})$ |
| Wide Record      |  623_161 $({\color{green}-26.70\\%})$ |   400_752 $({\color{green}-20.98\\%})$ |      357_486 $({\color{red}+6.14\\%})$ |   206_160 $({\color{green}-37.52\\%})$ |


**Heap**

|                  |                              encode() |             encode(sans inference) |                           decode() |             decode(sans inference) |
| :--------------- | ------------------------------------: | ---------------------------------: | ---------------------------------: | ---------------------------------: |
| Nat              |    292 B $({\color{green}-98.55\\%})$ | 272 B $({\color{green}-98.43\\%})$ | 272 B $({\color{green}-97.43\\%})$ | 272 B $({\color{green}-97.42\\%})$ |
| Nat8             |    288 B $({\color{green}-98.57\\%})$ | 272 B $({\color{green}-98.43\\%})$ | 272 B $({\color{green}-97.42\\%})$ | 272 B $({\color{green}-97.41\\%})$ |
| Nat16            |    292 B $({\color{green}-98.55\\%})$ | 272 B $({\color{green}-98.43\\%})$ | 272 B $({\color{green}-97.43\\%})$ | 272 B $({\color{green}-97.41\\%})$ |
| Nat32            |    292 B $({\color{green}-98.56\\%})$ | 272 B $({\color{green}-98.43\\%})$ | 272 B $({\color{green}-97.44\\%})$ | 272 B $({\color{green}-97.42\\%})$ |
| Nat64            |    296 B $({\color{green}-98.54\\%})$ | 272 B $({\color{green}-98.43\\%})$ | 272 B $({\color{green}-97.46\\%})$ | 272 B $({\color{green}-97.45\\%})$ |
| Int              |    292 B $({\color{green}-98.55\\%})$ | 272 B $({\color{green}-98.43\\%})$ | 272 B $({\color{green}-97.43\\%})$ | 272 B $({\color{green}-97.42\\%})$ |
| Int8             |    288 B $({\color{green}-98.57\\%})$ | 272 B $({\color{green}-98.43\\%})$ | 272 B $({\color{green}-97.42\\%})$ | 272 B $({\color{green}-97.41\\%})$ |
| Int16            |    292 B $({\color{green}-98.55\\%})$ | 272 B $({\color{green}-98.43\\%})$ | 272 B $({\color{green}-97.43\\%})$ | 272 B $({\color{green}-97.41\\%})$ |
| Int32            |    292 B $({\color{green}-98.56\\%})$ | 272 B $({\color{green}-98.43\\%})$ | 272 B $({\color{green}-97.44\\%})$ | 272 B $({\color{green}-97.42\\%})$ |
| Int64            |    296 B $({\color{green}-98.54\\%})$ | 272 B $({\color{green}-98.43\\%})$ | 272 B $({\color{green}-97.46\\%})$ | 272 B $({\color{green}-97.45\\%})$ |
| Float            |    296 B $({\color{green}-98.59\\%})$ | 272 B $({\color{green}-98.49\\%})$ | 272 B $({\color{green}-97.62\\%})$ | 272 B $({\color{green}-97.61\\%})$ |
| Bool             |    288 B $({\color{green}-98.57\\%})$ | 272 B $({\color{green}-98.43\\%})$ | 272 B $({\color{green}-97.42\\%})$ | 272 B $({\color{green}-97.41\\%})$ |
| Text             |    296 B $({\color{green}-98.54\\%})$ | 272 B $({\color{green}-98.43\\%})$ | 272 B $({\color{green}-97.47\\%})$ | 272 B $({\color{green}-97.46\\%})$ |
| Null             |    272 B $({\color{green}-98.65\\%})$ | 272 B $({\color{green}-98.42\\%})$ | 272 B $({\color{green}-98.68\\%})$ | 272 B $({\color{green}-98.45\\%})$ |
| Empty            |    272 B $({\color{green}-98.65\\%})$ | 272 B $({\color{green}-98.42\\%})$ | 272 B $({\color{green}-98.68\\%})$ | 272 B $({\color{green}-98.45\\%})$ |
| Principal        |    320 B $({\color{green}-98.44\\%})$ | 272 B $({\color{green}-98.45\\%})$ | 272 B $({\color{green}-97.61\\%})$ | 272 B $({\color{green}-97.60\\%})$ |
| Blob             |    388 B $({\color{green}-98.66\\%})$ | 272 B $({\color{green}-98.79\\%})$ | 272 B $({\color{green}-98.33\\%})$ | 272 B $({\color{green}-98.30\\%})$ |
| Option(Nat)      |    296 B $({\color{green}-98.73\\%})$ | 272 B $({\color{green}-98.46\\%})$ | 272 B $({\color{green}-97.51\\%})$ | 272 B $({\color{green}-97.45\\%})$ |
| Option(Text)     |    300 B $({\color{green}-98.72\\%})$ | 272 B $({\color{green}-98.47\\%})$ | 272 B $({\color{green}-97.55\\%})$ | 272 B $({\color{green}-97.49\\%})$ |
| Array(Nat8)      |    296 B $({\color{green}-98.82\\%})$ | 272 B $({\color{green}-98.47\\%})$ | 272 B $({\color{green}-97.54\\%})$ | 272 B $({\color{green}-97.48\\%})$ |
| Array(Text)      |    340 B $({\color{green}-98.70\\%})$ | 272 B $({\color{green}-98.53\\%})$ | 272 B $({\color{green}-97.88\\%})$ | 272 B $({\color{green}-97.83\\%})$ |
| Array(Record)    |    320 B $({\color{green}-99.04\\%})$ | 272 B $({\color{green}-98.73\\%})$ | 272 B $({\color{green}-98.06\\%})$ | 272 B $({\color{green}-97.97\\%})$ |
| Record(Nested)   |    408 B $({\color{green}-99.26\\%})$ | 272 B $({\color{green}-99.15\\%})$ | 272 B $({\color{green}-98.86\\%})$ | 272 B $({\color{green}-98.43\\%})$ |
| Variant(Simple)  |    304 B $({\color{green}-98.78\\%})$ | 272 B $({\color{green}-98.56\\%})$ | 272 B $({\color{green}-97.82\\%})$ | 272 B $({\color{green}-97.47\\%})$ |
| Variant(Complex) |    396 B $({\color{green}-99.39\\%})$ | 272 B $({\color{green}-99.36\\%})$ | 272 B $({\color{green}-99.00\\%})$ | 272 B $({\color{green}-98.23\\%})$ |
| Large Text       | 5.07 KiB $({\color{green}-96.46\\%})$ | 272 B $({\color{green}-99.81\\%})$ | 272 B $({\color{green}-99.80\\%})$ | 272 B $({\color{green}-99.80\\%})$ |
| Large Array      |  2.6 KiB $({\color{green}-98.84\\%})$ | 272 B $({\color{green}-99.71\\%})$ | 272 B $({\color{green}-99.69\\%})$ | 272 B $({\color{green}-99.69\\%})$ |
| Deep Nesting     |    332 B $({\color{green}-99.39\\%})$ | 272 B $({\color{green}-99.09\\%})$ | 272 B $({\color{green}-98.40\\%})$ | 272 B $({\color{green}-98.23\\%})$ |
| Wide Record      |    472 B $({\color{green}-98.97\\%})$ | 272 B $({\color{green}-98.99\\%})$ | 272 B $({\color{green}-99.10\\%})$ | 272 B $({\color{green}-99.06\\%})$ |


**Garbage Collection**

|                  |                                 encode() |                   encode(sans inference) |                                decode() |                  decode(sans inference) |
| :--------------- | ---------------------------------------: | ---------------------------------------: | --------------------------------------: | --------------------------------------: |
| Nat              |   25.2 KiB $({\color{red}+Infinity\\%})$ |  22.82 KiB $({\color{red}+Infinity\\%})$ | 16.87 KiB $({\color{red}+Infinity\\%})$ | 16.82 KiB $({\color{red}+Infinity\\%})$ |
| Nat8             |  25.19 KiB $({\color{red}+Infinity\\%})$ |   22.8 KiB $({\color{red}+Infinity\\%})$ | 16.87 KiB $({\color{red}+Infinity\\%})$ | 16.82 KiB $({\color{red}+Infinity\\%})$ |
| Nat16            |  25.21 KiB $({\color{red}+Infinity\\%})$ |  22.83 KiB $({\color{red}+Infinity\\%})$ | 16.87 KiB $({\color{red}+Infinity\\%})$ | 16.82 KiB $({\color{red}+Infinity\\%})$ |
| Nat32            |  25.22 KiB $({\color{red}+Infinity\\%})$ |  22.84 KiB $({\color{red}+Infinity\\%})$ | 16.87 KiB $({\color{red}+Infinity\\%})$ | 16.82 KiB $({\color{red}+Infinity\\%})$ |
| Nat64            |  25.25 KiB $({\color{red}+Infinity\\%})$ |  22.88 KiB $({\color{red}+Infinity\\%})$ | 16.88 KiB $({\color{red}+Infinity\\%})$ | 16.84 KiB $({\color{red}+Infinity\\%})$ |
| Int              |   25.2 KiB $({\color{red}+Infinity\\%})$ |  22.82 KiB $({\color{red}+Infinity\\%})$ | 16.87 KiB $({\color{red}+Infinity\\%})$ | 16.82 KiB $({\color{red}+Infinity\\%})$ |
| Int8             |  25.19 KiB $({\color{red}+Infinity\\%})$ |   22.8 KiB $({\color{red}+Infinity\\%})$ | 16.87 KiB $({\color{red}+Infinity\\%})$ | 16.82 KiB $({\color{red}+Infinity\\%})$ |
| Int16            |  25.21 KiB $({\color{red}+Infinity\\%})$ |  22.83 KiB $({\color{red}+Infinity\\%})$ | 16.87 KiB $({\color{red}+Infinity\\%})$ | 16.82 KiB $({\color{red}+Infinity\\%})$ |
| Int32            |  25.23 KiB $({\color{red}+Infinity\\%})$ |  22.85 KiB $({\color{red}+Infinity\\%})$ | 16.88 KiB $({\color{red}+Infinity\\%})$ | 16.83 KiB $({\color{red}+Infinity\\%})$ |
| Int64            |  25.27 KiB $({\color{red}+Infinity\\%})$ |  22.89 KiB $({\color{red}+Infinity\\%})$ | 16.89 KiB $({\color{red}+Infinity\\%})$ | 16.85 KiB $({\color{red}+Infinity\\%})$ |
| Float            |  25.84 KiB $({\color{red}+Infinity\\%})$ |  23.46 KiB $({\color{red}+Infinity\\%})$ | 17.57 KiB $({\color{red}+Infinity\\%})$ | 17.53 KiB $({\color{red}+Infinity\\%})$ |
| Bool             |  25.19 KiB $({\color{red}+Infinity\\%})$ |   22.8 KiB $({\color{red}+Infinity\\%})$ | 16.87 KiB $({\color{red}+Infinity\\%})$ | 16.82 KiB $({\color{red}+Infinity\\%})$ |
| Text             |  25.21 KiB $({\color{red}+Infinity\\%})$ |  22.84 KiB $({\color{red}+Infinity\\%})$ | 16.95 KiB $({\color{red}+Infinity\\%})$ |  16.9 KiB $({\color{red}+Infinity\\%})$ |
| Null             |  25.18 KiB $({\color{red}+Infinity\\%})$ |  22.78 KiB $({\color{red}+Infinity\\%})$ | 25.64 KiB $({\color{red}+Infinity\\%})$ | 23.17 KiB $({\color{red}+Infinity\\%})$ |
| Empty            |  25.18 KiB $({\color{red}+Infinity\\%})$ |  22.78 KiB $({\color{red}+Infinity\\%})$ | 25.64 KiB $({\color{red}+Infinity\\%})$ | 23.17 KiB $({\color{red}+Infinity\\%})$ |
| Principal        |  25.34 KiB $({\color{red}+Infinity\\%})$ |  22.99 KiB $({\color{red}+Infinity\\%})$ | 17.09 KiB $({\color{red}+Infinity\\%})$ | 17.04 KiB $({\color{red}+Infinity\\%})$ |
| Blob             |  32.69 KiB $({\color{red}+Infinity\\%})$ |  27.12 KiB $({\color{red}+Infinity\\%})$ | 19.85 KiB $({\color{red}+Infinity\\%})$ | 19.62 KiB $({\color{red}+Infinity\\%})$ |
| Option(Nat)      |   27.7 KiB $({\color{red}+Infinity\\%})$ |  23.16 KiB $({\color{red}+Infinity\\%})$ | 17.13 KiB $({\color{red}+Infinity\\%})$ | 16.89 KiB $({\color{red}+Infinity\\%})$ |
| Option(Text)     |  27.72 KiB $({\color{red}+Infinity\\%})$ |  23.18 KiB $({\color{red}+Infinity\\%})$ |  17.2 KiB $({\color{red}+Infinity\\%})$ | 16.97 KiB $({\color{red}+Infinity\\%})$ |
| Array(Nat8)      |  29.77 KiB $({\color{red}+Infinity\\%})$ |  23.24 KiB $({\color{red}+Infinity\\%})$ | 17.24 KiB $({\color{red}+Infinity\\%})$ | 17.01 KiB $({\color{red}+Infinity\\%})$ |
| Array(Text)      |  30.73 KiB $({\color{red}+Infinity\\%})$ |  23.59 KiB $({\color{red}+Infinity\\%})$ | 17.89 KiB $({\color{red}+Infinity\\%})$ | 17.66 KiB $({\color{red}+Infinity\\%})$ |
| Array(Record)    |  36.64 KiB $({\color{red}+Infinity\\%})$ |  26.44 KiB $({\color{red}+Infinity\\%})$ | 19.94 KiB $({\color{red}+Infinity\\%})$ | 18.93 KiB $({\color{red}+Infinity\\%})$ |
| Record(Nested)   |  54.81 KiB $({\color{red}+Infinity\\%})$ |  35.73 KiB $({\color{red}+Infinity\\%})$ |  29.8 KiB $({\color{red}+Infinity\\%})$ | 21.47 KiB $({\color{red}+Infinity\\%})$ |
| Variant(Simple)  |  30.06 KiB $({\color{red}+Infinity\\%})$ |  24.08 KiB $({\color{red}+Infinity\\%})$ | 18.58 KiB $({\color{red}+Infinity\\%})$ | 17.03 KiB $({\color{red}+Infinity\\%})$ |
| Variant(Complex) |   64.2 KiB $({\color{red}+Infinity\\%})$ |  44.11 KiB $({\color{red}+Infinity\\%})$ | 34.19 KiB $({\color{red}+Infinity\\%})$ | 20.17 KiB $({\color{red}+Infinity\\%})$ |
| Large Text       | 124.63 KiB $({\color{red}+Infinity\\%})$ | 127.04 KiB $({\color{red}+Infinity\\%})$ | 45.66 KiB $({\color{red}+Infinity\\%})$ | 45.62 KiB $({\color{red}+Infinity\\%})$ |
| Large Array      | 248.38 KiB $({\color{red}+Infinity\\%})$ |  90.29 KiB $({\color{red}+Infinity\\%})$ | 38.73 KiB $({\color{red}+Infinity\\%})$ |  38.5 KiB $({\color{red}+Infinity\\%})$ |
| Deep Nesting     |  53.77 KiB $({\color{red}+Infinity\\%})$ |  33.74 KiB $({\color{red}+Infinity\\%})$ | 23.25 KiB $({\color{red}+Infinity\\%})$ | 20.66 KiB $({\color{red}+Infinity\\%})$ |
| Wide Record      |  46.96 KiB $({\color{red}+Infinity\\%})$ |  31.94 KiB $({\color{red}+Infinity\\%})$ |    38 KiB $({\color{red}+Infinity\\%})$ |  30.5 KiB $({\color{red}+Infinity\\%})$ |


</details>
Saving results to .bench/types.bench.json
