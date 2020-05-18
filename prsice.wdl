version 1.0

## This WDL implements the PRSice_v2.0 polygenic scoring pipeline
##
## Inputs required: A GWAS file with header columns: snp chr pos A1 A2 OR/b p
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
        String p_value_thresholds
        String binary_phenotype_T_F
        String code_directory
        String perl_path
    }

    call tasks.harmonize {
        input:
            gwas          = gwas,
            bim           = bim,
            bfile         = sub(bim, "\.bim$", ""),
            output_prefix = out,
            code_dir      = code_directory,
            perl_path     = perl_path,
            walltime      = "02:00:00",
            procs         = 1,
            memory_gb     = 8
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
            procs         = 1,
            memory_gb     = 16,
            walltime      = "08:00:00"
    }

    output {
        File scores            = prsice_run.scores
        File VarianceExplained = prsice_run.summary
        File log               = prsice_run.log
    }
}
