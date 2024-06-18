from dataclasses import dataclass
from enum import Enum
import os
import subprocess
import requests
import shutil
from pathlib import Path
import typing
import typing_extensions

from latch.resources.workflow import workflow
from latch.resources.tasks import nextflow_runtime_task, custom_task
from latch.types.file import LatchFile
from latch.types.directory import LatchDir, LatchOutputDir
from latch.ldata.path import LPath
from latch_cli.nextflow.workflow import get_flag
from latch_cli.nextflow.utils import _get_execution_name
from latch_cli.utils import urljoins
from latch.types import metadata
from flytekit.core.annotation import FlyteAnnotation

from latch_cli.services.register.utils import import_module_by_path

meta = Path("latch_metadata") / "__init__.py"
import_module_by_path(meta)
import latch_metadata

@custom_task(cpu=0.25, memory=0.5, storage_gib=1)
def initialize() -> str:
    token = os.environ.get("FLYTE_INTERNAL_EXECUTION_ID")
    if token is None:
        raise RuntimeError("failed to get execution token")

    headers = {"Authorization": f"Latch-Execution-Token {token}"}

    print("Provisioning shared storage volume... ", end="")
    resp = requests.post(
        "http://nf-dispatcher-service.flyte.svc.cluster.local/provision-storage",
        headers=headers,
        json={
            "storage_gib": 100,
        }
    )
    resp.raise_for_status()
    print("Done.")

    return resp.json()["name"]






@nextflow_runtime_task(cpu=4, memory=8, storage_gib=100)
def nextflow_runtime(pvc_name: str, input: typing.Optional[LatchFile], input_region: typing.Optional[LatchFile], outdir: typing_extensions.Annotated[LatchDir, FlyteAnnotation({'output': True})], rename_chr: typing.Optional[bool], remove_samples: typing.Optional[str], email: typing.Optional[str], multiqc_title: typing.Optional[str], steps: typing.Optional[str], tools: typing.Optional[str], genotype: typing.Optional[LatchFile], panel: typing.Optional[LatchFile], phased: typing.Optional[bool], compute_freq: typing.Optional[bool], binaryref: typing.Optional[str], chunks: typing.Optional[LatchFile], input_truth: typing.Optional[LatchFile], genome: typing.Optional[str], fasta: typing.Optional[LatchFile], fasta_fai: typing.Optional[LatchFile], map: typing.Optional[LatchFile], multiqc_methods_description: typing.Optional[str], posfile: typing.Optional[LatchFile], depth: typing.Optional[int], bins: typing.Optional[str], min_val_gl: typing.Optional[float], min_val_dp: typing.Optional[int], buffer: typing.Optional[int], ngen: typing.Optional[int], seed: typing.Optional[int], k_val: typing.Optional[int]) -> None:
    try:
        shared_dir = Path("/nf-workdir")



        ignore_list = [
            "latch",
            ".latch",
            "nextflow",
            ".nextflow",
            "work",
            "results",
            "miniconda",
            "anaconda3",
            "mambaforge",
        ]

        shutil.copytree(
            Path("/root"),
            shared_dir,
            ignore=lambda src, names: ignore_list,
            ignore_dangling_symlinks=True,
            dirs_exist_ok=True,
        )

        cmd = [
            "/root/nextflow",
            "run",
            str(shared_dir / "main.nf"),
            "-work-dir",
            str(shared_dir),
            "-profile",
            "docker",
            "-c",
            "latch.config",
                *get_flag('input', input),
                *get_flag('input_region', input_region),
                *get_flag('outdir', outdir),
                *get_flag('rename_chr', rename_chr),
                *get_flag('remove_samples', remove_samples),
                *get_flag('email', email),
                *get_flag('multiqc_title', multiqc_title),
                *get_flag('steps', steps),
                *get_flag('tools', tools),
                *get_flag('depth', depth),
                *get_flag('genotype', genotype),
                *get_flag('panel', panel),
                *get_flag('phased', phased),
                *get_flag('compute_freq', compute_freq),
                *get_flag('binaryref', binaryref),
                *get_flag('chunks', chunks),
                *get_flag('input_truth', input_truth),
                *get_flag('bins', bins),
                *get_flag('min_val_gl', min_val_gl),
                *get_flag('min_val_dp', min_val_dp),
                *get_flag('genome', genome),
                *get_flag('fasta', fasta),
                *get_flag('fasta_fai', fasta_fai),
                *get_flag('map', map),
                *get_flag('multiqc_methods_description', multiqc_methods_description),
                *get_flag('buffer', buffer),
                *get_flag('ngen', ngen),
                *get_flag('seed', seed),
                *get_flag('posfile', posfile),
                *get_flag('k_val', k_val)
        ]

        print("Launching Nextflow Runtime")
        print(' '.join(cmd))
        print(flush=True)

        env = {
            **os.environ,
            "NXF_HOME": "/root/.nextflow",
            "NXF_OPTS": "-Xms2048M -Xmx8G -XX:ActiveProcessorCount=4",
            "K8S_STORAGE_CLAIM_NAME": pvc_name,
            "NXF_DISABLE_CHECK_LATEST": "true",
        }
        subprocess.run(
            cmd,
            env=env,
            check=True,
            cwd=str(shared_dir),
        )
    finally:
        print()

        nextflow_log = shared_dir / ".nextflow.log"
        if nextflow_log.exists():
            name = _get_execution_name()
            if name is None:
                print("Skipping logs upload, failed to get execution name")
            else:
                remote = LPath(urljoins("latch:///your_log_dir/nf_nf_core_phaseimpute", name, "nextflow.log"))
                print(f"Uploading .nextflow.log to {remote.path}")
                remote.upload_from(nextflow_log)



@workflow(metadata._nextflow_metadata)
def nf_nf_core_phaseimpute(input: typing.Optional[LatchFile], input_region: typing.Optional[LatchFile], outdir: typing_extensions.Annotated[LatchDir, FlyteAnnotation({'output': True})], rename_chr: typing.Optional[bool], remove_samples: typing.Optional[str], email: typing.Optional[str], multiqc_title: typing.Optional[str], steps: typing.Optional[str], tools: typing.Optional[str], genotype: typing.Optional[LatchFile], panel: typing.Optional[LatchFile], phased: typing.Optional[bool], compute_freq: typing.Optional[bool], binaryref: typing.Optional[str], chunks: typing.Optional[LatchFile], input_truth: typing.Optional[LatchFile], genome: typing.Optional[str], fasta: typing.Optional[LatchFile], fasta_fai: typing.Optional[LatchFile], map: typing.Optional[LatchFile], multiqc_methods_description: typing.Optional[str], posfile: typing.Optional[LatchFile], depth: typing.Optional[int] = 1, bins: typing.Optional[str] = '0 0.01 0.05 0.1 0.2 0.5', min_val_gl: typing.Optional[float] = 0.9, min_val_dp: typing.Optional[int] = 5, buffer: typing.Optional[int] = 10000, ngen: typing.Optional[int] = 100, seed: typing.Optional[int] = 1, k_val: typing.Optional[int] = 2) -> None:
    """
    nf-core/phaseimpute

    Sample Description
    """

    pvc_name: str = initialize()
    nextflow_runtime(pvc_name=pvc_name, input=input, input_region=input_region, outdir=outdir, rename_chr=rename_chr, remove_samples=remove_samples, email=email, multiqc_title=multiqc_title, steps=steps, tools=tools, depth=depth, genotype=genotype, panel=panel, phased=phased, compute_freq=compute_freq, binaryref=binaryref, chunks=chunks, input_truth=input_truth, bins=bins, min_val_gl=min_val_gl, min_val_dp=min_val_dp, genome=genome, fasta=fasta, fasta_fai=fasta_fai, map=map, multiqc_methods_description=multiqc_methods_description, buffer=buffer, ngen=ngen, seed=seed, posfile=posfile, k_val=k_val)

