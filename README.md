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
| Serde: One Shot                     | 370_118_793 | 1_450_772_592 |
| Serde: One Shot sans type inference | 463_851_227 | 1_055_540_193 |
| Motoko (to_candid(), from_candid()) |  33_954_865 |     9_628_451 |


**Heap**

|                                     |   decode() |  encode() |
| :---------------------------------- | ---------: | --------: |
| Serde: One Shot                     |  -6.15 MiB | 12.15 MiB |
| Serde: One Shot sans type inference |  -3.46 MiB |  9.88 MiB |
| Motoko (to_candid(), from_candid()) | 644.13 KiB | 602.5 KiB |


**Garbage Collection**

|                                     |  decode() |  encode() |
| :---------------------------------- | --------: | --------: |
| Serde: One Shot                     | 28.08 MiB | 59.79 MiB |
| Serde: One Shot sans type inference | 29.85 MiB | 27.79 MiB |
| Motoko (to_candid(), from_candid()) |       0 B |       0 B |


</details>
Saving results to .bench/serde.bench.json
