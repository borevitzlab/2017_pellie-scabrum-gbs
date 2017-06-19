import snkmk
import json
configfile: "config.yml"

shell.executable("/bin/bash")
shell.prefix("set -euo pipefail && ")

SAMP2LANE, LANE2SAMP = snkmk.s2l2s("metadata/pellie-metadata.csv")
READCOUNTS = snkmk.make_readcountdict(config["lanes"].keys())
SAMPLES = [s for s, rc in READCOUNTS.items() if rc > config["minreads"]]

localrules: all, qc, map, varcall, qcreads


rule all:
    input:
        expand("data/reads/qc/{sample}.fastq.gz", sample=SAMPLES)


rule qcreads:
    input:
        reads=lambda wc: "data/reads/raw/{lane}/{sample}_il.fastq".format(
                                lane=SAMP2LANE[wc.sample], sample=wc.sample),
    output:
        reads="data/reads/qc/{sample}.fastq.gz",
        settings="data/stats/adapterremoval/{sample}_settings.txt",
    log:
        "data/log/adapterremoval/{sample}.log",
    threads:
        2
    params:
        adp1=config["qc"]["adapter1"],
        adp2=config["qc"]["adapter2"],
        collapse='--collapse' if config["qc"].get('merge', False) else '',
        minqual=config["qc"].get('minqual', 20),
    shell:
        "( set -x; AdapterRemoval"
        "   --file1 {input.reads}"
        "   --adapter1 {params.adp1}"
        "   --adapter2 {params.adp2}"
        "   --combined-output"
        "   --interleaved"
        "   --gzip"
        "   {params.collapse}"
        "   --trimns"
        "   --trimqualities"
        "   --minquality {params.minqual}"
        "   --threads {threads}"
        "   --settings {output.settings}"
        "   --output1 {output.reads}"
        ") >{log} 2>&1"
