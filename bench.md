## Benchmarks

#### mops version `2.2.0`
Benchmarking the performance with 10k calls

**Instructions**

|       | to_candid() |      decode() |      encode() |
| :---- | ----------: | ------------: | ------------: |
| Serde |   6_613_393 | 1_053_697_986 | 2_923_910_215 |


**Heap**

|       | to_candid() |   decode() |  encode() |
| :---- | ----------: | ---------: | --------: |
| Serde |     373_992 | 10_257_380 | 7_543_216 |