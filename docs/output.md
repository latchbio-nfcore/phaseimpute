# nf-core/phaseimpute: Output

## Introduction

This document describes the output produced by the pipeline. Most of the plots are taken from the MultiQC report, which summarises results at the end of the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

<!-- TODO nf-core: Write this documentation describing your workflow's output -->

## Pipeline overview

## Panel preparation outputs `--steps panelprep`

This steps of the pipeline performs a QC of the reference panel data and produces the necessary files for imputation (`--steps impute`). It has two optional modes: reference panel phasing with SHAPEIT5 and removal of specified samples from reference panel.

- [Remove Multiallelics](#multiallelics) - Remove multiallelic sites from the reference panel
- [Convert](#convert) - Convert reference panel to .hap and .legend files
- [Posfile](#posfile) - Produce a TSV with the list of positions to genotype (for STITCH/QUILT)
- [Sites](#sites) - Produce a TSV with the list of positions to genotype (for GLIMPSE1)
- [Glimpse Chunk](#glimpse) - Create chunks of the reference panel
- [CSV](#csv) - Obtain a CSV from this step

The directory structure from `--steps panelprep` is:

```
├── chunks
│   ├── glimpse1
│   └── glimpse2
├── csv
├── panel
├── haplegend
└── sites
    ├── tsv
    └── vcf
```

### Panel directory

- `prep_panel/panel/`
  - `*.vcf.gz`: A vcf for the prepared reference panel.
  - `*.tbi*`: A tbi for the prepared reference panel.

A directory containing the final phased and prepared panel per chromosome.

### Haplegend directory

- `prep_panel/haplegend/`
  - `*.hap`: a .hap file for the reference panel.
  - `*.legend*`: a .legend file for the reference panel.

[bcftools](https://samtools.github.io/bcftools/bcftools.html) aids in the conversion of vcf files to .hap and .legend files. A .samples file is also generated. Once that you have generated the hap and legend files for your reference panel, you can skip the reference preparation steps and directly submit these files for imputation. The hap and legend files are input files used with `--tools quilt`.

### Sites directory

- `prep_panel/sites/`
  - `vcf/`
    - `*.vcf.gz`: VCF with biallelic SNPs only.
    - `*.csi`: Index file for VCF.
  - `tsv/`
    - `*.txt.gz`: TXT file for biallelic SNPs.
    - `*.tbi`: Index file for TSV.

[bcftools query](https://samtools.github.io/bcftools/bcftools.html) produces VCF (`*.vcf.gz`) files per chromosome. These QCed VCFs can be gathered into a csv and used with all the tools in `--steps impute` using the flag `--panel`.

In addition, [bcftools query](https://samtools.github.io/bcftools/bcftools.html) produces tab-delimited files (`*_tsv.txt`) and, together with the VCFs, they can be gathered into a samplesheet and directly submitted for imputation with `--tools glimpse1,stitch` and `--posfile`.

### Chunks directory

- `prep_panel/chunks/`
  - `*.txt`: TXT file containing the chunks obtained from running Glimpse chunks.

[Glimpse1 chunk](https://odelaneau.github.io/GLIMPSE/) defines chunks where to run imputation. For further reading and documentation see the [Glimpse1 documentation](https://odelaneau.github.io/GLIMPSE/glimpse1/commands.html). Once that you have generated the chunks for your reference panel, you can skip the reference preparation steps and directly submit this file for imputation.

### CSV directory

- `prep_panel/csv/`
  - `chunks.csv`: A csv containing the list of chunks obtained for each chromosome and panel.
  - `panel.csv`: A csv containing the final phased and prepared for each chromosome and input panel.
  - `posfile.csv`: A csv containing the final list of panel positions, in vcf and tsv, for each chromosome and input panel.

## Imputation outputs `--steps impute`

The results from steps impute will have the following directory structure:

- `imputation/csv/`
  - `impute.csv`: A single csv containing the path to a vcf and its index, of each imputed sample with their corresponding tool.
- `imputation/[glimpse1,glimpse2,quilt,stitch]/`
  - `concat/*.vcf.gz`: A vcf of each imputed sample.
  - `concat/*.vcf.gz.tbi`: A tbi for the imputed vcf.

[bcftools concat](https://samtools.github.io/bcftools/bcftools.html) will produce a single VCF from a list of imputed VCFs in chunks.

## Reports

Reports contain useful metrics and pipeline information for the different modes.

- [Pipeline information](#pipeline-information) - Report metrics generated during the workflow execution
- [MultiQC](#multiqc) - Aggregate report describing results and QC from the whole pipeline
- [Pipeline information](#pipeline-information) - Report metrics generated during the workflow execution

### MultiQC

<details markdown="1">
<summary>Output files</summary>

- `multiqc/`
  - `multiqc_report.html`: a standalone HTML file that can be viewed in your web browser.
  - `multiqc_data/`: directory containing parsed statistics from the different tools used in the pipeline.
  - `multiqc_plots/`: directory containing static images from the report in various formats.

</details>

[MultiQC](http://multiqc.info) is a visualization tool that generates a single HTML report summarising all samples in your project. Most of the pipeline QC results are visualised in the report and further statistics are available in the report data directory.
[MultiQC](http://multiqc.info) is a visualization tool that generates a single HTML report summarising all samples in your project. Most of the pipeline QC results are visualised in the report and further statistics are available in the report data directory.

Results generated by MultiQC collate pipeline QC from supported tools e.g. FastQC. The pipeline has special steps which also allow the software versions to be reported in the MultiQC output for future traceability. For more information about how to use MultiQC reports, see <http://multiqc.info>.

### Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
  - Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.yml`. The `pipeline_report*` files will only be present if the `--email` / `--email_on_fail` parameter's are used when running the pipeline.
  - Reformatted samplesheet files used as input to the pipeline: `samplesheet.valid.csv`.
  - Parameters used by the pipeline run: `params.json`.

</details>

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.
