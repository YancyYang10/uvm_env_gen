set wave $env(wave)
set tc $env(tc)
set seed $env(seed)

if {$env(wave)} {

    fsdbDumpfile "./out/sim_${tc}_${seed}.fsdb"
    # "+mda"   - 包含多维数组（Memory/Array）
    # "+struct" - 包含结构体（可选，按需添加）
    fsdbDumpvars 0 tb_top "+mda+struct"
}
run 1ms
stop
