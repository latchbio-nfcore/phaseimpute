/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { MULTIQC                     } from '../../modules/nf-core/multiqc'
include { paramsSummaryMap            } from 'plugin/nf-validation'
include { paramsSummaryMultiqc        } from '../../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML      } from '../../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText      } from '../../subworkflows/local/utils_nfcore_phaseimpute_pipeline'
include { getAllFilesExtension        } from '../../subworkflows/local/utils_nfcore_phaseimpute_pipeline'

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//

// Simulate subworkflows
include { BAM_REGION                                 } from '../../subworkflows/local/bam_region'
include { BAM_DOWNSAMPLE                             } from '../../subworkflows/local/bam_downsample'

// Panelprep subworkflows
include { VCF_CHR_CHECK                              } from '../../subworkflows/local/vcf_chr_check'
include { VCF_NORMALIZE_BCFTOOLS                     } from '../../subworkflows/local/vcf_normalize_bcftools'
include { VCF_SITES_EXTRACT_BCFTOOLS                 } from '../../subworkflows/local/vcf_sites_extract_bcftools'
include { VCF_PHASE_PANEL                            } from '../../subworkflows/local/vcf_phase_panel'
include { PREPARE_POSFILE_TSV                        } from '../../subworkflows/local/prepare_posfile_tsv'

// GLIMPSE1 subworkflows
include { CHUNK_PREPARE_CHANNEL                      } from '../../subworkflows/local/chunk_prepare_channel'
include { VCF_IMPUTE_GLIMPSE1                        } from '../../subworkflows/local/vcf_impute_glimpse1'
include { VCF_CONCATENATE_BCFTOOLS as CONCAT_GLIMPSE1} from '../../subworkflows/local/vcf_concatenate_bcftools'
include { CHUNK_PREPARE_CHANNEL                      } from '../../subworkflows/local/chunk_prepare_channel'

// GLIMPSE2 subworkflows
include { VCF_IMPUTE_GLIMPSE2                        } from '../../subworkflows/local/vcf_impute_glimpse2'
include { VCF_CONCATENATE_BCFTOOLS as CONCAT_GLIMPSE2} from '../../subworkflows/local/vcf_concatenate_bcftools'

// QUILT subworkflows
include { VCF_CHUNK_GLIMPSE                          } from '../../subworkflows/local/vcf_chunk_glimpse'
include { BAM_IMPUTE_QUILT                           } from '../../subworkflows/local/bam_impute_quilt'
include { VCF_CONCATENATE_BCFTOOLS as CONCAT_QUILT   } from '../../subworkflows/local/vcf_concatenate_bcftools'

// STITCH subworkflows
include { PREPARE_INPUT_STITCH                       } from '../../subworkflows/local/prepare_input_stitch'
include { BAM_IMPUTE_STITCH                          } from '../../subworkflows/local/bam_impute_stitch'
include { VCF_CONCATENATE_BCFTOOLS as CONCAT_STITCH  } from '../../subworkflows/local/vcf_concatenate_bcftools'

// CONCAT subworkflows
include { VCF_CONCATENATE_BCFTOOLS as CONCAT_TRUTH   } from '../../subworkflows/local/vcf_concatenate_bcftools'
include { VCF_CONCATENATE_BCFTOOLS as CONCAT_PANEL   } from '../../subworkflows/local/vcf_concatenate_bcftools'

// Concordance subworkflows
include { BAM_GL_BCFTOOLS as GL_TRUTH                } from '../../subworkflows/local/bam_gl_bcftools'
include { VCF_CONCORDANCE_GLIMPSE2                   } from '../../subworkflows/local/vcf_concordance_glimpse2'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PHASEIMPUTE {

    take:
    ch_input_impute         // channel: input file    [ [id], file, index ]
    ch_input_sim            // channel: input file    [ [id], file, index ]
    ch_input_validate       // channel: input file    [ [id], file, index ]
    ch_input_validate_truth // channel: truth file    [ [id], file, index ]
    ch_fasta                // channel: fasta file    [ [genome], fasta, fai ]
    ch_panel                // channel: panel file    [ [id, chr], vcf, index ]
    ch_region               // channel: region to use [ [chr, region], region]
    ch_depth                // channel: depth select  [ [depth], depth ]
    ch_map                  // channel: genetic map   [ [chr], map]
    ch_posfile              // channel: posfile       [ [chr], txt]
    ch_chunks               // channel: chunks       [ [chr], txt]
    ch_versions             // channel: versions of software used

    main:

    ch_multiqc_files = Channel.empty()

    //
    // Simulate data if asked
    //
    if (params.steps.split(',').contains("simulate") || params.steps.split(',').contains("all")) {
        // Output channel of simulate process
        ch_sim_output = Channel.empty()

        // Test if the input are all bam files
        getAllFilesExtension(ch_input_sim)
            .map{ if (it != "bam") {
                error "All input files must be in BAM format to perform simulation"
            } }

        // Split the bam into the region specified
        BAM_REGION(ch_input_sim, ch_region, ch_fasta)
        ch_versions = ch_versions.mix(BAM_REGION.out.versions)

        // Initialize channel to impute
        ch_bam_to_impute = Channel.empty()

        if (params.depth) {
            // Downsample input to desired depth
            BAM_DOWNSAMPLE(
                BAM_REGION.out.bam_region,
                ch_depth,
                ch_fasta
            )
            ch_versions             = ch_versions.mix(BAM_DOWNSAMPLE.out.versions)
            ch_multiqc_files        = ch_multiqc_files.mix(BAM_DOWNSAMPLE.out.coverage.map{ [it[1]] })
            ch_input_impute         = BAM_DOWNSAMPLE.out.bam_emul
            ch_input_validate_truth = ch_input_sim
        }

        if (params.genotype) {
            error "Genotype simulation not yet implemented"
        }
    }

    //
    // Prepare panel
    //
    if (params.steps.split(',').contains("panelprep") || params.steps.split(',').contains("validate") || params.steps.split(',').contains("all")) {
        // Check chr prefix and remove if necessary
        VCF_CHR_CHECK(ch_panel, ch_fasta)
        ch_versions = ch_versions.mix(VCF_CHR_CHECK.out.versions)

        // Normalize indels in panel
        VCF_NORMALIZE_BCFTOOLS(VCF_CHR_CHECK.out.vcf, ch_fasta)
        ch_versions = ch_versions.mix(VCF_NORMALIZE_BCFTOOLS.out.versions)

        // Extract sites from normalized vcf
        VCF_SITES_EXTRACT_BCFTOOLS(VCF_NORMALIZE_BCFTOOLS.out.vcf_tbi)
        ch_versions = ch_versions.mix(VCF_SITES_EXTRACT_BCFTOOLS.out.versions)

        // Prepare posfile stitch
        PREPARE_POSFILE_TSV(VCF_SITES_EXTRACT_BCFTOOLS.out.panel_sites)
        ch_versions = ch_versions.mix(PREPARE_POSFILE_TSV.out.versions)

        // If required, phase panel (currently not working, a test should be added)
        // Phase panel with tool of choice (e.g. SHAPEIT5)
        VCF_PHASE_PANEL(VCF_NORMALIZE_BCFTOOLS.out.vcf_tbi)
        ch_versions = ch_versions.mix(VCF_PHASE_PANEL.out.versions)

        ch_panel = VCF_NORMALIZE_BCFTOOLS.out.vcf_tbi
            .join(VCF_SITES_EXTRACT_BCFTOOLS.out.panel_sites)
            .join(VCF_SITES_EXTRACT_BCFTOOLS.out.panel_tsv)
            .join(VCF_PHASE_PANEL.out.vcf_tbi)

        // Generate channels (to be simplified)
        ch_panel_sites_tsv = ch_panel
            .map{ metaPC, norm, n_index, sites, s_index, tsv, t_index, phased, p_index
                -> [metaPC, sites, tsv]
            }
        CONCAT_PANEL(VCF_SITES_EXTRACT_BCFTOOLS.out.panel_sites)
        ch_versions    = ch_versions.mix(CONCAT_PANEL.out.versions)

        ch_panel_sites = CONCAT_PANEL.out.vcf_tbi_join
        ch_panel_phased = VCF_PHASE_PANEL.out.vcf_tbi

        // Create chunks from reference VCF
        VCF_CHUNK_GLIMPSE(ch_panel_phased, ch_map)
        ch_versions = ch_versions.mix(VCF_CHUNK_GLIMPSE.out.versions)

    }

    if (params.steps.split(',').contains("impute") || params.steps.split(',').contains("all")) {
            if (params.tools.split(',').contains("glimpse1")) {
                println "Impute with Glimpse1"

                if (params.chunks) {
                    ch_chunks_glimpse1 = CHUNK_PREPARE_CHANNEL(ch_chunks, "glimpse").out.chunks
                } else if (params.panel && params.steps.split(',').find { it in ["all", "panelprep"] } && !params.chunks) {
                    ch_chunks_glimpse1 = VCF_CHUNK_GLIMPSE.out.chunks_glimpse1
                }

                //Params posfile should replace part of ch_panel_sites_tsv (specifically, the .txt)
                //The VCF with the sites and post-prepared panel should be used as input in --panel.

                // if (params.posfile) {
                //             ch_panel_sites_tsv = ch_posfile
                // } else if (params.panel && params.steps.split(',').contains("panelprep") && !params.posfile) {
                //         ch_panel_sites_tsv = VCF_PHASE_PANEL.out.panel
                //                     .map{ metaPC, norm, n_index, sites, s_index, tsv, t_index, phased, p_index
                //                     -> [metaPC, sites, tsv]
                //                     }
                // }

                VCF_IMPUTE_GLIMPSE1(
                    ch_input_impute,
                    ch_panel_sites_tsv,
                    ch_panel_phased,
                    ch_chunks_glimpse1,
                    ch_fasta
                )
                ch_versions = ch_versions.mix(VCF_IMPUTE_GLIMPSE1.out.versions)
                ch_multiqc_files = ch_multiqc_files.mix(VCF_IMPUTE_GLIMPSE1.out.multiqc_files)

                // Concatenate by chromosomes
                CONCAT_GLIMPSE1(VCF_IMPUTE_GLIMPSE1.out.vcf_tbi)
                ch_versions = ch_versions.mix(CONCAT_GLIMPSE1.out.versions)

                // Add results to input validate
                ch_input_validate = ch_input_validate.mix(CONCAT_GLIMPSE1.out.vcf_tbi_join)

            }
            if (params.tools.split(',').contains("glimpse2")) {

                // Use previous chunks if --steps panelprep
                if (params.panel && params.steps.split(',').find { it in ["all", "panelprep"] } && !params.chunks) {
                    ch_chunks = VCF_CHUNK_GLIMPSE.out.chunks_glimpse1
                } else if (params.chunks) {
                    ch_chunks = CHUNK_PREPARE_CHANNEL(ch_chunks, "glimpse").out.chunks
                }

                // Run imputation
                VCF_IMPUTE_GLIMPSE2(ch_input_impute,
                        ch_panel_phased,
                        ch_chunks,
                        ch_fasta)
                ch_versions = ch_versions.mix(VCF_IMPUTE_GLIMPSE2.out.versions)
                // Concatenate by chromosomes
                CONCAT_GLIMPSE2(VCF_IMPUTE_GLIMPSE2.out.vcf_tbi)
                ch_versions = ch_versions.mix(CONCAT_GLIMPSE2.out.versions)

                // Add results to input validate
                ch_input_validate = ch_input_validate.mix(CONCAT_GLIMPSE2.out.vcf_tbi_join)
            }
            if (params.tools.split(',').contains("stitch")) {
                print("Impute with STITCH")

                // Get posfile from panelprep steps if --posfile not supplied
                if (params.panel && params.steps.split(',').find { it in ["all", "panelprep"] }) {
                    ch_posfile = PREPARE_POSFILE_TSV.out.posfile
                }

                // Prepare inputs
                PREPARE_INPUT_STITCH(ch_posfile, ch_fasta, ch_input_impute)
                ch_versions = ch_versions.mix(PREPARE_INPUT_STITCH.out.versions)

                // Impute with STITCH
                BAM_IMPUTE_STITCH ( PREPARE_INPUT_STITCH.out.stitch_parameters,
                                    PREPARE_INPUT_STITCH.out.stitch_samples,
                                    ch_fasta )
                ch_versions = ch_versions.mix(BAM_IMPUTE_STITCH.out.versions)

                // Concatenate by chromosomes
                CONCAT_STITCH(BAM_IMPUTE_STITCH.out.vcf_tbi)
                ch_versions = ch_versions.mix(CONCAT_STITCH.out.versions)

                // Add results to input validate
                ch_input_validate = ch_input_validate.mix(CONCAT_STITCH.out.vcf_tbi_join)

            }
            if (params.tools.split(',').contains("quilt")) {
                print("Impute with QUILT")

                // Use previous chunks if --steps panelprep
                if (params.panel && params.steps.split(',').find { it in ["all", "panelprep"] } && !params.chunks) {
                    ch_chunks_quilt = VCF_CHUNK_GLIMPSE.out.chunks_quilt
                // Use provided chunks if --chunks
                } else if (params.chunks) {
                    ch_chunks_quilt = CHUNK_PREPARE_CHANNEL(ch_chunks, "quilt").out.chunks
                }

                // Impute BAMs with QUILT
                BAM_IMPUTE_QUILT(ch_input_impute, VCF_NORMALIZE_BCFTOOLS.out.hap_legend, VCF_CHUNK_GLIMPSE.out.chunks_quilt)
                ch_versions = ch_versions.mix(BAM_IMPUTE_QUILT.out.versions)

                // Concatenate by chromosomes
                CONCAT_QUILT(BAM_IMPUTE_QUILT.out.vcf_tbi)
                ch_versions = ch_versions.mix(CONCAT_QUILT.out.versions)

                // Add results to input validate
                ch_input_validate = ch_input_validate.mix(CONCAT_QUILT.out.vcf_tbi_join)
            }
        }

    if (params.steps.split(',').contains("validate") || params.steps.split(',').contains("all")) {

        // if (params.posfile) {
        // Use channel ch_posfile for validation
        //      ch_panel_sites_tsv = ch_posfile
        // } else if (params.panel && params.steps.split(',').contains("panelprep") && !params.posfile) {
        // ch_panel_sites_tsv = VCF_PHASE_PANEL.out.panel
        //             .map{ metaPC, norm, n_index, sites, s_index, tsv, t_index, phased, p_index
        //             -> [metaPC, sites, tsv]
        //             }
        //}

        ch_truth_vcf = Channel.empty()
        // Get extension of input files
        truth_ext = getAllFilesExtension(ch_input_validate_truth)

        // Channels for branching
        ch_truth = ch_input_validate_truth
            .combine(truth_ext)
            .branch {
                bam: it[3] == 'bam'
                vcf: it[3] =~ 'vcf|bcf'
            }

        GL_TRUTH(
            ch_truth.bam.map { [it[0], it[1], it[2]] },
            ch_panel_sites_tsv,
            ch_fasta
        )
        ch_multiqc_files = ch_multiqc_files.mix(GL_TRUTH.out.multiqc_files)
        ch_versions      = ch_versions.mix(GL_TRUTH.out.versions)

        // Mix the original vcf and the computed vcf
        ch_truth_vcf = ch_truth.vcf
            .map { [it[0], it[1], it[2]] }
            .mix(GL_TRUTH.out.vcf)

        // Compute concordance analysis
        VCF_CONCORDANCE_GLIMPSE2(
            ch_input_validate,
            ch_truth_vcf,
            ch_panel_sites,
            ch_region
        )
        ch_multiqc_files = ch_multiqc_files.mix(VCF_CONCORDANCE_GLIMPSE2.out.multiqc_files)
        ch_versions      = ch_versions.mix(VCF_CONCORDANCE_GLIMPSE2.out.versions)
    }

    if (params.steps.split(',').contains("refine")) {
        error "refine steps not yet implemented"
    }

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(storeDir: "${params.outdir}/pipeline_info", name: 'nf_core_pipeline_software_mqc_versions.yml', sort: true, newLine: true)
        .set { ch_collated_versions }

    //
    // MODULE: MultiQC
    //
    ch_multiqc_config                     = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config              = params.multiqc_config ? Channel.fromPath(params.multiqc_config, checkIfExists: true) : Channel.empty()
    ch_multiqc_logo                       = params.multiqc_logo ? Channel.fromPath(params.multiqc_logo, checkIfExists: true) : Channel.empty()
    summary_params                        = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary                   = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(methodsDescriptionText(ch_multiqc_custom_methods_description))
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml', sort: false))

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
