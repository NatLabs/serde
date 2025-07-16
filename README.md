# Benchmark Results


No previous results found "/home/runner/work/serde/serde/.bench/serde.bench.json"

<details>

<summary>bench/serde.bench.mo $({\color{gray}0\%})$</summary>

### Benchmarking Serde

_Benchmarking the performance with 10k calls_


Instructions: ${\color{gray}0\\%}$
Heap: ${\color{gray}0\\%}$
Stable Memory: ${\color{gray}0\\%}$
Garbage Collection: ${\color{gray}0\\%}$


**Instructions**

|                                     |    decode() |      encode() |
| :---------------------------------- | ----------: | ------------: |
| Serde: One Shot                     | 388_634_152 | 1_510_263_669 |
| Serde: One Shot sans type inference | 491_135_586 | 1_080_725_185 |
| Motoko (to_candid(), from_candid()) |  34_594_293 |     9_692_991 |


**Heap**

|                                     |   decode() |   encode() |
| :---------------------------------- | ---------: | ---------: |
| Serde: One Shot                     |  -6.15 MiB |  12.15 MiB |
| Serde: One Shot sans type inference |  -3.44 MiB |   9.86 MiB |
| Motoko (to_candid(), from_candid()) | 645.08 KiB | 603.71 KiB |


**Garbage Collection**

|                                     |  decode() |  encode() |
| :---------------------------------- | --------: | --------: |
| Serde: One Shot                     | 28.09 MiB | 59.78 MiB |
| Serde: One Shot sans type inference | 29.84 MiB | 27.78 MiB |
| Motoko (to_candid(), from_candid()) |       0 B |       0 B |


</details>
Saving results to .bench/serde.bench.json
