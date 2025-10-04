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
| Serde: One Shot                     | 370_326_268 | 1_450_634_915 |
| Serde: One Shot sans type inference | 464_058_702 | 1_055_977_484 |
| Motoko (to_candid(), from_candid()) |  33_969_802 |     9_645_870 |


**Heap**

|                                     |  decode() |   encode() |
| :---------------------------------- | --------: | ---------: |
| Serde: One Shot                     | -6.15 MiB |  12.18 MiB |
| Serde: One Shot sans type inference | -3.44 MiB |    9.9 MiB |
| Motoko (to_candid(), from_candid()) | 644.9 KiB | 603.85 KiB |


**Garbage Collection**

|                                     |  decode() |  encode() |
| :---------------------------------- | --------: | --------: |
| Serde: One Shot                     | 28.08 MiB | 59.79 MiB |
| Serde: One Shot sans type inference | 29.84 MiB | 27.79 MiB |
| Motoko (to_candid(), from_candid()) |       0 B |       0 B |


</details>
Saving results to .bench/serde.bench.json
