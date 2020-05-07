version 1.0

task harmonize {
    input {
        File gwas
        File bim
        String output_prefix
        String bfile
        String walltime
        Int nodes
        Int procs
        Int memory_gb
        String errout
        String job_name
    }

    command {
        bin/align_gwas_to_bim.pl --gwas ${gwas} \
                                 --bfile ${bfile} \
                                > ${output_prefix}.assoc
    }

    output {
        File out = "${output_prefix}.assoc"
        String beta_or = read_string(stdout())
    }

    runtime {
        walltime : walltime
        nodes : nodes
        procs : procs
        memory_gb : memory_gb
        errout : errout
        job_name : job_name
        work_dir : work_dir
    }
}

task prsice_run {
    input {
        reference
        target_bed
        target_bim
        target_fam
        target
        bar_levels
        output_prefix
        prsice
        work_dir
        nodes
        procs
        memory_gb
        errout
        job_name
        walltime
    }

    command {
        ${prsice} --snp SNP \
                  --A1 A1 \
                  --A2 A2 \
                  --chr CHR \
                  --bp POS \
                  --pvalue P \
                  --stat ${beta_or} \
                  --fastscore \
                  --all-score \
                  --binary-target ${binary} \
                  --base ${reference} \
                  --target ${target} \
                  --${beta_or}
                  --out ${output_prefix} \
                  --bar-levels ${bar_levels}
    }

    output {
        File scores  = "${output_prefix}.all.scores"
        File log     = "${output_prefix}.log"
        File summary = "${output_prefix}.summary"
    }
    runtime {
        walltime : walltime
        nodes : nodes
        procs : procs
        memory_gb : memory_gb
        errout : errout
        job_name : job_name
        work_dir : work_dir
    }
}
