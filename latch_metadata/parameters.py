
from dataclasses import dataclass
import typing
import typing_extensions

from flytekit.core.annotation import FlyteAnnotation

from latch.types.metadata import NextflowParameter
from latch.types.file import LatchFile
from latch.types.directory import LatchDir, LatchOutputDir

# Import these into your `__init__.py` file:
#
# from .parameters import generated_parameters

generated_parameters = {
    'input': NextflowParameter(
        type=typing.Optional[LatchFile],
        default=None,
        section_title='Input/output options',
        description='Path to comma-separated file containing information about the samples in the experiment.',
    ),
    'input_region': NextflowParameter(
        type=typing.Optional[LatchFile],
        default=None,
        section_title=None,
        description='Region of the genome to use (optional: if no file given, the whole genome will be used). The file should be a comma-separated file with 3 columns, and a header row.',
    ),
    'outdir': NextflowParameter(
        type=typing_extensions.Annotated[LatchDir, FlyteAnnotation({'output': True})],
        default=None,
        section_title=None,
        description='The output directory where the results will be saved. You have to use absolute paths to storage on Cloud infrastructure.',
    ),
    'rename_chr': NextflowParameter(
        type=typing.Optional[bool],
        default=None,
        section_title=None,
        description="Should the panel vcf files be renamed to match the reference genome (e.g. 'chr1' -> '1')",
    ),
    'remove_samples': NextflowParameter(
        type=typing.Optional[str],
        default=None,
        section_title=None,
        description='Comma-separated list of samples to remove from the reference panel. Useful for benchmarking purposes.',
    ),
    'email': NextflowParameter(
        type=typing.Optional[str],
        default=None,
        section_title=None,
        description='Email address for completion summary.',
    ),
    'multiqc_title': NextflowParameter(
        type=typing.Optional[str],
        default=None,
        section_title=None,
        description='MultiQC report title. Printed as page header, used for filename if not otherwise specified.',
    ),
    'steps': NextflowParameter(
        type=typing.Optional[str],
        default=None,
        section_title=None,
        description='Step(s) to run.',
    ),
    'tools': NextflowParameter(
        type=typing.Optional[str],
        default=None,
        section_title=None,
        description='Imputation tool to use.',
    ),
    'depth': NextflowParameter(
        type=typing.Optional[int],
        default=1,
        section_title='Simulate',
        description='Depth of coverage for the simulated data',
    ),
    'genotype': NextflowParameter(
        type=typing.Optional[LatchFile],
        default=None,
        section_title=None,
        description='Genotype position to use to simulate the data',
    ),
    'panel': NextflowParameter(
        type=typing.Optional[LatchFile],
        default=None,
        section_title='Panel preparation',
        description='Path to the reference panel or csv file with the list of panels',
    ),
    'phased': NextflowParameter(
        type=typing.Optional[bool],
        default=None,
        section_title=None,
        description='Is the reference panel phased',
    ),
    'compute_freq': NextflowParameter(
        type=typing.Optional[bool],
        default=None,
        section_title=None,
        description='Should the allele frequency for each variant (AC/AN fields necessary for Glimpse1 and the validation step) be computed using VCFFIXUP tool. This can be necessary if the fields are absent from the panel or if samples have been removed.',
    ),
    'binaryref': NextflowParameter(
        type=typing.Optional[str],
        default=None,
        section_title=None,
        description='Whether to generate a binary reference file to be used with GLIMPSE2',
    ),
    'chunks': NextflowParameter(
        type=typing.Optional[LatchFile],
        default=None,
        section_title='Imputation options',
        description='Path to comma-separated file containing tab-separated files with the genomic chunks to be used for imputation.',
    ),
    'input_truth': NextflowParameter(
        type=typing.Optional[LatchFile],
        default=None,
        section_title='Concordance analysis',
        description='Path to comma-separated file containing information about the samples truth files in the experiment.',
    ),
    'bins': NextflowParameter(
        type=typing.Optional[str],
        default='0 0.01 0.05 0.1 0.2 0.5',
        section_title=None,
        description='User-defined allele count bins used for rsquared computations.',
    ),
    'min_val_gl': NextflowParameter(
        type=typing.Optional[float],
        default=0.9,
        section_title=None,
        description='Minimum genotype likelihood probability P(G|R) in validation data. Set to zero to have no filter of if using gt-validation',
    ),
    'min_val_dp': NextflowParameter(
        type=typing.Optional[int],
        default=5,
        section_title=None,
        description='Minimum coverage in validation data. If FORMAT/DP is missing and -min_val_dp > 0, the program exits with an error. Set to zero to have no filter of if using –gt-validation',
    ),
    'genome': NextflowParameter(
        type=typing.Optional[str],
        default=None,
        section_title='Reference genome options',
        description='Name of iGenomes reference.',
    ),
    'fasta': NextflowParameter(
        type=typing.Optional[LatchFile],
        default=None,
        section_title=None,
        description='Path to FASTA genome file.',
    ),
    'fasta_fai': NextflowParameter(
        type=typing.Optional[LatchFile],
        default=None,
        section_title=None,
        description='Path to FASTA index genome file.',
    ),
    'map': NextflowParameter(
        type=typing.Optional[LatchFile],
        default=None,
        section_title=None,
        description='Path to gmap genome file.',
    ),
    'multiqc_methods_description': NextflowParameter(
        type=typing.Optional[str],
        default=None,
        section_title='Generic options',
        description='Custom MultiQC yaml file containing HTML including a methods description.',
    ),
    'buffer': NextflowParameter(
        type=typing.Optional[int],
        default=10000,
        section_title='QUILT parameters',
        description='Buffer of region to perform imputation over. So imputation is run form regionStart-buffer to regionEnd+buffer, and reported for regionStart to regionEnd, including the bases of regionStart and regionEnd.',
    ),
    'ngen': NextflowParameter(
        type=typing.Optional[int],
        default=100,
        section_title=None,
        description='Number of generations since founding of the population to use for imputation.',
    ),
    'seed': NextflowParameter(
        type=typing.Optional[int],
        default=1,
        section_title='STITCH parameters',
        description=None,
    ),
    'posfile': NextflowParameter(
        type=typing.Optional[LatchFile],
        default=None,
        section_title=None,
        description='Path to comma-separated file containing tab-separated files describing the variable positions to be used for imputation. Refer to the documentation for the `--posfile` argument of STITCH for more information.',
    ),
    'k_val': NextflowParameter(
        type=typing.Optional[int],
        default=2,
        section_title=None,
        description='Number of ancestral haplotypes to use for imputation. Refer to the documentation for the `--K` argument of STITCH for more information.',
    ),
}

