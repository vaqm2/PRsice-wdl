version 1.0

task harmonize {
    input {
        File gwas
        File bim
        String output_prefix
        String bfile
        String walltime
        Int procs
        Int memory_gb
        String err
        String out
        String job_name
        String code_dir
        String perl_path
    }

    command {
        ${perl_path} ${code_dir}/align_gwas_to_bim.pl --gwas ${gwas} \
                                 --bfile ${bfile} \
                                 --out ${output_prefix}
    }

    output {
        File out     = "${output_prefix}.assoc"
        File col_map = "${output_prefix}.json"
    }

    runtime {
        walltime : walltime
        cpu : procs
        memory_gb : memory_gb
        err : err
        out : out
        job_name : job_name
    }
}

task prsice_run {
    input {
        File reference
        File target_bed
        File target_bim
        File target_fam
        String target
        String bar_levels
        String output_prefix
        File prsice
        String SNP
        String A1
        String A2
        String CHR
        String POS
        String P
        String beta_or
        String binary
        Int procs
        Int memory_gb
        String err
        String out
        String job_name
        String walltime
    }

    command {
        ${prsice} --snp ${SNP} \
                  --A1 ${A1} \
                  --A2 ${A2} \
                  --chr ${CHR} \
                  --bp ${POS} \
                  --pvalue ${P} \
                  --stat ${beta_or} \
                  --fastscore \
                  --all-score \
                  --binary-target ${binary} \
                  --base ${reference} \
                  --target ${target} \
                  --${beta_or} \
                  --out ${output_prefix} \
                  --bar-levels ${bar_levels}
    }

    output {
        File scores  = "${output_prefix}.all.score"
        File log     = "${output_prefix}.log"
        File summary = "${output_prefix}.prsice"
    }

    runtime {
        walltime : walltime
        cpu : procs
        memory_gb : memory_gb
        err : err
        out : out
        job_name : job_name
    }
}
