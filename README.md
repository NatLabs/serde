# Benchmark Results


2026-04-05 23:26:30.843756571 UTC: [Canister l62sy-yx777-77777-aaabq-cai] Generating test data for all types...
2026-04-05 23:26:30.843756571 UTC: [Canister l62sy-yx777-77777-aaabq-cai] Generated test data for all types

<details>

<summary>bench/serde.bench.mo $({\color{red}+237029.59\%})$</summary>

### Benchmarking Serde

_Benchmarking the performance with 1k calls_


Instructions: ${\color{red}+26.13\\%}$
Heap: ${\color{red}+236405.92\\%}$
Stable Memory: ${\color{gray}0\\%}$
Garbage Collection: ${\color{red}+597.54\\%}$


**Instructions**

|                                     |                               decode() |                                 encode() |
| :---------------------------------- | -------------------------------------: | ---------------------------------------: |
| Serde: One Shot                     | 500_810_940 $({\color{red}+26.96\\%})$ | 1_494_948_716 $({\color{red}+35.25\\%})$ |
| Serde: One Shot sans type inference | 344_282_368 $({\color{red}+52.62\\%})$ | 1_127_586_001 $({\color{red}+26.46\\%})$ |
| Motoko (to_candid(), from_candid()) |   33_999_350 $({\color{red}+8.58\\%})$ |      9_758_720 $({\color{red}+7.69\\%})$ |
| Serde: Single Type Serializer       | 152_819_172 $({\color{red}+36.50\\%})$ |   255_900_057 $({\color{red}+14.97\\%})$ |


**Heap**

|                                     |                                    decode() |                                      encode() |
| :---------------------------------- | ------------------------------------------: | --------------------------------------------: |
| Serde: One Shot                     |       1.19 MiB $({\color{green}-21.12\\%})$ |     13.91 MiB $({\color{red}+4736393.51\\%})$ |
| Serde: One Shot sans type inference | -8.48 MiB $({\color{green}-3270692.65\\%})$ |     12.59 MiB $({\color{red}+4854844.12\\%})$ |
| Motoko (to_candid(), from_candid()) |   644.15 KiB $({\color{red}+242404.41\\%})$ | -29.26 MiB $({\color{green}-11278104.41\\%})$ |
| Serde: Single Type Serializer       |    7.86 MiB $({\color{red}+3031867.65\\%})$ |      9.27 MiB $({\color{red}+3574555.88\\%})$ |


**Garbage Collection**

|                                     |                             decode() |                               encode() |
| :---------------------------------- | -----------------------------------: | -------------------------------------: |
| Serde: One Shot                     | 28.49 MiB $({\color{red}+15.61\\%})$ |  59.79 MiB $({\color{green}-4.39\\%})$ |
| Serde: One Shot sans type inference | 29.84 MiB $({\color{red}+70.02\\%})$ | 27.79 MiB $({\color{green}-18.16\\%})$ |
| Motoko (to_candid(), from_candid()) |    0 B $({\color{green}-100.00\\%})$ | 29.84 MiB $({\color{red}+5017.27\\%})$ |
| Serde: Single Type Serializer       |    0 B $({\color{green}-100.00\\%})$ |      0 B $({\color{green}-100.00\\%})$ |


</details>
Saving results to .bench/serde.bench.json

<details>

<summary>bench/types.bench.mo $({\color{red}+455.67\%})$</summary>

### Benchmarking Serde by Data Types

_Performance comparison across all supported Candid data types with 1k operations_


Instructions: ${\color{red}+13193.87\\%}$
Heap: ${\color{green}-12738.20\\%}$
Stable Memory: ${\color{gray}0\\%}$
Garbage Collection: ${\color{gray}0\\%}$


**Instructions**

|                  |                                    encode() |                    encode(sans inference) |                                  decode() |                    decode(sans inference) |
| :--------------- | ------------------------------------------: | ----------------------------------------: | ----------------------------------------: | ----------------------------------------: |
| Nat              |    25_171_160 $({\color{red}+34527.14\\%})$ |   8_904_088 $({\color{red}+13705.43\\%})$ |   1_665_887 $({\color{red}+11257.29\\%})$ |    1_620_082 $({\color{red}+5324.50\\%})$ |
| Nat8             |    12_844_363 $({\color{red}+17709.22\\%})$ |   8_674_083 $({\color{red}+13405.56\\%})$ |   1_553_377 $({\color{red}+10646.30\\%})$ |    1_506_894 $({\color{red}+4928.01\\%})$ |
| Nat16            |    12_986_934 $({\color{red}+17623.31\\%})$ |   8_809_286 $({\color{red}+13313.05\\%})$ |   1_599_334 $({\color{red}+10315.04\\%})$ |    1_552_480 $({\color{red}+4877.81\\%})$ |
| Nat32            |    13_196_714 $({\color{red}+17483.19\\%})$ |   9_020_242 $({\color{red}+13213.62\\%})$ |   1_719_903 $({\color{red}+10234.09\\%})$ |    1_672_371 $({\color{red}+4999.94\\%})$ |
| Nat64            |    13_620_571 $({\color{red}+17404.69\\%})$ |   9_439_621 $({\color{red}+13231.29\\%})$ |   2_619_239 $({\color{red}+13899.89\\%})$ |    1_862_350 $({\color{red}+5194.53\\%})$ |
| Int              |    13_350_503 $({\color{red}+17627.63\\%})$ |   9_191_075 $({\color{red}+13271.95\\%})$ |    1_714_432 $({\color{red}+9820.91\\%})$ |    1_665_544 $({\color{red}+4789.46\\%})$ |
| Int8             |    12_849_241 $({\color{red}+17129.50\\%})$ |   8_685_334 $({\color{red}+12616.26\\%})$ |    1_571_158 $({\color{red}+9180.32\\%})$ |    1_521_592 $({\color{red}+4371.33\\%})$ |
| Int16            |    12_991_812 $({\color{red}+17055.21\\%})$ |   8_823_607 $({\color{red}+12549.97\\%})$ |    1_617_729 $({\color{red}+8972.56\\%})$ |    1_567_485 $({\color{red}+4347.02\\%})$ |
| Int32            |    13_224_381 $({\color{red}+16965.48\\%})$ |   9_051_519 $({\color{red}+12504.64\\%})$ |    1_742_098 $({\color{red}+9009.96\\%})$ |    1_691_176 $({\color{red}+4488.48\\%})$ |
| Int64            |    13_648_946 $({\color{red}+16913.12\\%})$ |   9_471_791 $({\color{red}+12555.55\\%})$ |    1_933_263 $({\color{red}+9024.33\\%})$ |    1_881_663 $({\color{red}+4695.39\\%})$ |
| Float            |    17_832_015 $({\color{red}+17266.08\\%})$ |  13_634_597 $({\color{red}+13881.33\\%})$ |   7_165_732 $({\color{red}+14576.06\\%})$ |   7_113_454 $({\color{red}+10486.44\\%})$ |
| Bool             |    12_901_044 $({\color{red}+16620.29\\%})$ |   8_704_347 $({\color{red}+11935.88\\%})$ |    1_578_291 $({\color{red}+8084.03\\%})$ |    1_537_335 $({\color{red}+3942.43\\%})$ |
| Text             |    13_925_304 $({\color{red}+16914.86\\%})$ |   9_719_150 $({\color{red}+12476.87\\%})$ |    2_229_673 $({\color{red}+9466.95\\%})$ |    2_177_039 $({\color{red}+5045.08\\%})$ |
| Null             |    12_664_459 $({\color{red}+16343.93\\%})$ |   8_391_180 $({\color{red}+11399.81\\%})$ |  14_105_576 $({\color{red}+15874.60\\%})$ |   9_733_849 $({\color{red}+11529.73\\%})$ |
| Empty            |    12_672_435 $({\color{red}+16266.31\\%})$ |   8_394_678 $({\color{red}+11293.43\\%})$ |  14_130_752 $({\color{red}+15813.01\\%})$ |   9_739_362 $({\color{red}+11436.66\\%})$ |
| Principal        |    16_600_198 $({\color{red}+16713.73\\%})$ |  12_386_811 $({\color{red}+12926.41\\%})$ |    3_402_536 $({\color{red}+9989.96\\%})$ |    3_349_868 $({\color{red}+6139.28\\%})$ |
| Blob             |    35_359_654 $({\color{red}+14409.26\\%})$ |  25_399_767 $({\color{red}+11977.41\\%})$ |    9_477_732 $({\color{red}+9524.80\\%})$ |    9_021_801 $({\color{red}+7628.91\\%})$ |
| Option(Nat)      |    19_400_799 $({\color{red}+16623.96\\%})$ |  10_766_357 $({\color{red}+11999.48\\%})$ |    2_266_962 $({\color{red}+8320.79\\%})$ |    1_812_538 $({\color{red}+3882.29\\%})$ |
| Option(Text)     |    19_823_838 $({\color{red}+16385.38\\%})$ |  11_202_066 $({\color{red}+11904.57\\%})$ |    2_535_594 $({\color{red}+8229.54\\%})$ |    2_070_492 $({\color{red}+4099.61\\%})$ |
| Array(Nat8)      |    30_084_996 $({\color{red}+21945.14\\%})$ |  12_390_846 $({\color{red}+13370.07\\%})$ |   3_313_834 $({\color{red}+11104.85\\%})$ |    2_859_054 $({\color{red}+5759.08\\%})$ |
| Array(Text)      |    38_931_783 $({\color{red}+20705.12\\%})$ |  20_912_449 $({\color{red}+16254.20\\%})$ |   8_518_488 $({\color{red}+14604.29\\%})$ |   8_054_030 $({\color{red}+10302.23\\%})$ |
| Array(Record)    |    55_056_998 $({\color{red}+18371.23\\%})$ |  34_807_721 $({\color{red}+16937.97\\%})$ |  12_316_509 $({\color{red}+16572.32\\%})$ |   8_879_594 $({\color{red}+10199.96\\%})$ |
| Record(Simple)   |            35_750_620 (no previous results) |          22_135_689 (no previous results) |          11_191_776 (no previous results) |           8_418_162 (no previous results) |
| Record(Nested)   |   131_184_079 $({\color{red}+17136.34\\%})$ | 101_246_747 $({\color{red}+19045.50\\%})$ |  70_275_007 $({\color{red}+22602.83\\%})$ |  18_554_153 $({\color{red}+12393.12\\%})$ |
| Tuple(Mixed)     |            48_739_019 (no previous results) |          39_237_858 (no previous results) |          13_983_938 (no previous results) |           8_537_768 (no previous results) |
| Variant(Simple)  |    26_212_400 $({\color{red}+17381.93\\%})$ |  19_520_971 $({\color{red}+13738.28\\%})$ |  25_270_529 $({\color{red}+39629.16\\%})$ |    3_763_081 $({\color{red}+6859.90\\%})$ |
| Variant(Complex) |     90_362_253 $({\color{red}+9313.50\\%})$ | 150_362_736 $({\color{red}+18491.00\\%})$ | 114_538_366 $({\color{red}+27361.04\\%})$ |  12_817_938 $({\color{red}+10234.21\\%})$ |
| Large Text       |   682_584_686 $({\color{red}+11609.99\\%})$ | 678_383_858 $({\color{red}+11536.75\\%})$ |  170_523_680 $({\color{red}+8840.59\\%})$ |  170_476_198 $({\color{red}+8726.31\\%})$ |
| Large Array      | 1_276_430_427 $({\color{red}+21026.40\\%})$ | 485_935_879 $({\color{red}+17661.40\\%})$ | 172_747_364 $({\color{red}+14042.98\\%})$ | 172_296_798 $({\color{red}+13751.54\\%})$ |
| Deep Nesting     |   117_093_739 $({\color{red}+18563.93\\%})$ |  80_828_376 $({\color{red}+18540.16\\%})$ |  23_062_855 $({\color{red}+18337.60\\%})$ |  14_336_017 $({\color{red}+11666.46\\%})$ |
| Wide Record      |   138_494_125 $({\color{red}+16189.52\\%})$ |  88_423_675 $({\color{red}+17335.34\\%})$ |  81_048_343 $({\color{red}+23963.09\\%})$ |  52_434_206 $({\color{red}+15791.22\\%})$ |


**Heap**

|                  |                                      encode() |                    encode(sans inference) |                                    decode() |                    decode(sans inference) |
| :--------------- | --------------------------------------------: | ----------------------------------------: | ------------------------------------------: | ----------------------------------------: |
| Nat              | -238.75 MiB $({\color{green}-1239208.14\\%})$ |     1.39 MiB $({\color{red}+8318.26\\%})$ |     128.58 KiB $({\color{red}+1143.09\\%})$ |   116.86 KiB $({\color{red}+1035.80\\%})$ |
| Nat8             |         1.94 MiB $({\color{red}+9977.60\\%})$ |     1.39 MiB $({\color{red}+8310.26\\%})$ |     128.58 KiB $({\color{red}+1147.80\\%})$ |   116.86 KiB $({\color{red}+1040.13\\%})$ |
| Nat16            |        1.95 MiB $({\color{red}+10001.33\\%})$ | -8.58 MiB $({\color{green}-52181.00\\%})$ |     128.58 KiB $({\color{red}+1145.44\\%})$ |   116.86 KiB $({\color{red}+1037.96\\%})$ |
| Nat32            |        1.95 MiB $({\color{red}+10013.16\\%})$ |     1.39 MiB $({\color{red}+8353.38\\%})$ |     129.66 KiB $({\color{red}+1151.15\\%})$ |   117.94 KiB $({\color{red}+1044.11\\%})$ |
| Nat64            |        1.96 MiB $({\color{red}+10038.76\\%})$ |      1.4 MiB $({\color{red}+8385.21\\%})$ | -25.46 MiB $({\color{green}-249373.66\\%})$ |    118.3 KiB $({\color{red}+1037.25\\%})$ |
| Int              |        1.96 MiB $({\color{red}+10055.91\\%})$ |      1.4 MiB $({\color{red}+8402.96\\%})$ |     128.58 KiB $({\color{red}+1143.09\\%})$ |   116.86 KiB $({\color{red}+1035.80\\%})$ |
| Int8             |         1.94 MiB $({\color{red}+9977.60\\%})$ |     1.39 MiB $({\color{red}+8310.26\\%})$ |     128.58 KiB $({\color{red}+1147.80\\%})$ |   116.86 KiB $({\color{red}+1040.13\\%})$ |
| Int16            |        1.95 MiB $({\color{red}+10001.33\\%})$ | -8.56 MiB $({\color{green}-52054.81\\%})$ |     128.58 KiB $({\color{red}+1145.44\\%})$ |   116.86 KiB $({\color{red}+1037.96\\%})$ |
| Int32            |        1.95 MiB $({\color{red}+10018.63\\%})$ |     1.39 MiB $({\color{red}+8359.76\\%})$ |     129.66 KiB $({\color{red}+1151.15\\%})$ |   117.94 KiB $({\color{red}+1044.11\\%})$ |
| Int64            |        1.96 MiB $({\color{red}+10046.04\\%})$ | -6.48 MiB $({\color{green}-39375.20\\%})$ |     130.02 KiB $({\color{red}+1143.37\\%})$ |    118.3 KiB $({\color{red}+1037.25\\%})$ |
| Float            |        2.09 MiB $({\color{red}+10347.49\\%})$ |     1.53 MiB $({\color{red}+8808.62\\%})$ |     291.86 KiB $({\color{red}+2515.23\\%})$ |   280.14 KiB $({\color{red}+2422.58\\%})$ |
| Bool             |         1.94 MiB $({\color{red}+9977.60\\%})$ |     1.39 MiB $({\color{red}+8310.26\\%})$ |     128.58 KiB $({\color{red}+1147.80\\%})$ |   116.86 KiB $({\color{red}+1040.13\\%})$ |
| Text             |     -7.97 MiB $({\color{green}-41375.20\\%})$ |     1.39 MiB $({\color{red}+8335.50\\%})$ |     149.34 KiB $({\color{red}+1319.64\\%})$ |   137.62 KiB $({\color{red}+1215.08\\%})$ |
| Null             |         1.93 MiB $({\color{red}+9959.87\\%})$ |     1.38 MiB $({\color{red}+8271.25\\%})$ |      2.05 MiB $({\color{red}+10315.78\\%})$ |  -6.4 MiB $({\color{green}-38225.89\\%})$ |
| Empty            |         1.93 MiB $({\color{red}+9959.87\\%})$ |     1.38 MiB $({\color{red}+8271.25\\%})$ |      2.05 MiB $({\color{red}+10315.78\\%})$ |     1.47 MiB $({\color{red}+8672.83\\%})$ |
| Principal        |     -7.94 MiB $({\color{green}-40663.21\\%})$ |     1.42 MiB $({\color{red}+8378.18\\%})$ |     174.68 KiB $({\color{red}+1470.12\\%})$ |   162.96 KiB $({\color{red}+1372.02\\%})$ |
| Blob             |        3.27 MiB $({\color{red}+11763.40\\%})$ |     2.04 MiB $({\color{red}+9395.53\\%})$ |   -7.24 MiB $({\color{green}-46656.53\\%})$ |   557.67 KiB $({\color{red}+3459.31\\%})$ |
| Option(Nat)      |        2.53 MiB $({\color{red}+11277.80\\%})$ |     1.46 MiB $({\color{red}+8567.01\\%})$ |     185.24 KiB $({\color{red}+1637.03\\%})$ |   128.21 KiB $({\color{red}+1132.95\\%})$ |
| Option(Text)     |        2.53 MiB $({\color{red}+11265.03\\%})$ |     1.47 MiB $({\color{red}+8561.76\\%})$ |     194.98 KiB $({\color{red}+1698.77\\%})$ |   137.95 KiB $({\color{red}+1204.62\\%})$ |
| Array(Nat8)      |     -6.71 MiB $({\color{green}-28180.37\\%})$ |     1.53 MiB $({\color{red}+8901.95\\%})$ |     256.05 KiB $({\color{red}+2268.10\\%})$ |   199.02 KiB $({\color{red}+1787.00\\%})$ |
| Array(Text)      |     -4.55 MiB $({\color{green}-18313.93\\%})$ |     1.61 MiB $({\color{red}+9032.77\\%})$ |        417 KiB $({\color{red}+3229.73\\%})$ |   359.96 KiB $({\color{red}+2836.62\\%})$ |
| Array(Record)    |        4.44 MiB $({\color{red}+13839.20\\%})$ |    2.24 MiB $({\color{red}+10845.95\\%})$ |   -9.01 MiB $({\color{green}-67315.46\\%})$ |   637.62 KiB $({\color{red}+4781.31\\%})$ |
| Record(Simple)   |                 3.2 MiB (no previous results) |            1.79 MiB (no previous results) |            796.21 KiB (no previous results) |          606.37 KiB (no previous results) |
| Record(Nested)   |      -14.08 KiB $({\color{green}-126.31\\%})$ | -5.48 MiB $({\color{green}-17956.98\\%})$ |      3.02 MiB $({\color{red}+13114.15\\%})$ |     1.17 MiB $({\color{red}+6958.44\\%})$ |
| Tuple(Mixed)     |               -4.25 MiB (no previous results) |             2.6 MiB (no previous results) |            852.27 KiB (no previous results) |          474.14 KiB (no previous results) |
| Variant(Simple)  |        2.97 MiB $({\color{red}+12408.30\\%})$ | -8.14 MiB $({\color{green}-45344.58\\%})$ |       1.07 MiB $({\color{red}+8925.14\\%})$ |   239.23 KiB $({\color{red}+2178.39\\%})$ |
| Variant(Complex) |      -1.72 MiB $({\color{green}-2858.21\\%})$ |    6.12 MiB $({\color{red}+14989.73\\%})$ |   -5.28 MiB $({\color{green}-20471.31\\%})$ |   783.04 KiB $({\color{red}+5120.29\\%})$ |
| Large Text       |         5.84 MiB $({\color{red}+4075.26\\%})$ |     3.06 MiB $({\color{red}+2131.54\\%})$ |       3.64 MiB $({\color{red}+2658.94\\%})$ |     3.63 MiB $({\color{red}+2651.38\\%})$ |
| Large Array      |         11.7 MiB $({\color{red}+5247.13\\%})$ |     5.42 MiB $({\color{red}+6024.84\\%})$ |    -1.43 MiB $({\color{green}-1829.01\\%})$ |  -3.54 MiB $({\color{green}-4394.96\\%})$ |
| Deep Nesting     |         1.42 MiB $({\color{red}+2640.42\\%})$ |    3.97 MiB $({\color{red}+13844.37\\%})$ |       1.63 MiB $({\color{red}+9940.36\\%})$ |     1.04 MiB $({\color{red}+6973.80\\%})$ |
| Wide Record      |      -2.16 MiB $({\color{green}-5048.81\\%})$ | -3.25 MiB $({\color{green}-12730.92\\%})$ |       4.8 MiB $({\color{red}+16460.71\\%})$ | -5.33 MiB $({\color{green}-19481.62\\%})$ |


**Garbage Collection**

|                  |                                encode() |                 encode(sans inference) |                               decode() |                 decode(sans inference) |
| :--------------- | --------------------------------------: | -------------------------------------: | -------------------------------------: | -------------------------------------: |
| Nat              | 233.6 MiB $({\color{red}+Infinity\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Nat8             |              0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Nat16            |              0 B $({\color{gray}0\\%})$ | 9.97 MiB $({\color{red}+Infinity\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Nat32            |              0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Nat64            |              0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |  7.9 MiB $({\color{red}+Infinity\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Int              |              0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Int8             |              0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Int16            |              0 B $({\color{gray}0\\%})$ | 9.95 MiB $({\color{red}+Infinity\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Int32            |              0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Int64            |              0 B $({\color{gray}0\\%})$ | 7.88 MiB $({\color{red}+Infinity\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Float            |              0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Bool             |              0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Text             |  9.92 MiB $({\color{red}+Infinity\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Null             |              0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ | 7.87 MiB $({\color{red}+Infinity\\%})$ |
| Empty            |              0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Principal        |  9.91 MiB $({\color{red}+Infinity\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Blob             |              0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ | 7.84 MiB $({\color{red}+Infinity\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Option(Nat)      |              0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Option(Text)     |              0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Array(Nat8)      |  9.88 MiB $({\color{red}+Infinity\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Array(Text)      |  7.81 MiB $({\color{red}+Infinity\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Array(Record)    |              0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ | 9.85 MiB $({\color{red}+Infinity\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Record(Simple)   |               0 B (no previous results) |              0 B (no previous results) |              0 B (no previous results) |              0 B (no previous results) |
| Record(Nested)   |  7.79 MiB $({\color{red}+Infinity\\%})$ | 9.84 MiB $({\color{red}+Infinity\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Tuple(Mixed)     |          7.77 MiB (no previous results) |              0 B (no previous results) |              0 B (no previous results) |              0 B (no previous results) |
| Variant(Simple)  |              0 B $({\color{gray}0\\%})$ | 9.81 MiB $({\color{red}+Infinity\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Variant(Complex) |  7.74 MiB $({\color{red}+Infinity\\%})$ |             0 B $({\color{gray}0\\%})$ | 9.78 MiB $({\color{red}+Infinity\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Large Text       |  7.46 MiB $({\color{red}+Infinity\\%})$ | 9.69 MiB $({\color{red}+Infinity\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Large Array      | 38.87 MiB $({\color{red}+Infinity\\%})$ | 8.93 MiB $({\color{red}+Infinity\\%})$ | 6.71 MiB $({\color{red}+Infinity\\%})$ | 8.77 MiB $({\color{red}+Infinity\\%})$ |
| Deep Nesting     |   6.7 MiB $({\color{red}+Infinity\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |             0 B $({\color{gray}0\\%})$ |
| Wide Record      |  8.75 MiB $({\color{red}+Infinity\\%})$ |  6.7 MiB $({\color{red}+Infinity\\%})$ |             0 B $({\color{gray}0\\%})$ | 8.71 MiB $({\color{red}+Infinity\\%})$ |


</details>
Saving results to .bench/types.bench.json
