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
| Serde: One Shot                     | 388_511_193 | 1_510_253_429 |
| Serde: One Shot sans type inference | 491_012_626 | 1_080_441_883 |
| Motoko (to_candid(), from_candid()) |  34_577_855 |     9_677_578 |


**Heap**

|                                     |  decode() |   encode() |
| :---------------------------------- | --------: | ---------: |
| Serde: One Shot                     | -6.15 MiB |  12.14 MiB |
| Serde: One Shot sans type inference | -3.45 MiB |   9.85 MiB |
| Motoko (to_candid(), from_candid()) | 644.5 KiB | 602.83 KiB |


**Garbage Collection**

|                                     |  decode() |  encode() |
| :---------------------------------- | --------: | --------: |
| Serde: One Shot                     | 28.08 MiB | 59.79 MiB |
| Serde: One Shot sans type inference | 29.84 MiB | 27.79 MiB |
| Motoko (to_candid(), from_candid()) |       0 B |       0 B |


</details>
Saving results to .bench/serde.bench.json
