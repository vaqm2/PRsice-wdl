version 1.0

## This WDL implements the PRSice_v2.0 polygenic scoring pipeline
##
## Inputs required: A GWAS file with header columns: SNP CHR A1 A2 OR/b se p
##                  A PLINK bfile of target genotypes
##
## Outputs: Polygenic Scores at specified p-value thresholds
##          Variance explained in the phenotype
##
## Cromwell version tested: 50
## Womtool version tested: 50
##

import "prsice_tasks.wdl" as tasks

workflow prsice {
    String version = "1.0"

    input {
        File gwas
        File bed
        File bim
        File fam
        File prsice_executable_path
        String out
        String working_directory
        String p_value_thresholds
        String binary_phenotype_T_F
    }

    call tasks.harmonize {
        input:
            gwas          = gwas,
            bim           = bim,
            bfile         = sub(bim, "\.bim$", ""),
            output_prefix = out,
            work_dir      = working_directory,
            walltime      = "02:00:00",
            nodes         = 1,
            procs         = 1,
            memory_gb     = 8,
            errout        = "harmonize" + "_" + out,
            job_name      = "harmonize" + "_" + out
    }

    Map[String, String] columns = read_json(harmonize.col_map)

    call tasks.prsice_run {
        input:
            reference     = harmonize.out,
            beta_or       = columns["stat"],
            target_bed    = bed,
            target_bim    = bim,
            target_fam    = fam,
            target        = sub(bed, "\.bed$", ""),
            bar_levels    = p_value_thresholds,
            output_prefix = out,
            prsice        = prsice_executable_path,
            SNP           = columns["snp"],
            A1            = columns["A1"],
            A2            = columns["A2"],
            P             = columns["P"],
            POS           = columns["bp"],
            CHR           = columns["chr"],
            beta_or       = columns["stat"],
            binary        = binary_phenotype_T_F,
            work_dir      = working_directory,
            nodes         = 1,
            procs         = 1,
            memory_gb     = 16,
            errout        = "prsice" + "_" + out,
            job_name      = "prsice" + "_" + out,
            walltime      = "08:00:00"
    }

    output {
        File scores            = prsice_run.scores
        File VarianceExplained = prsice_run.summary
        File log               = prsice_run.log
    }
}
