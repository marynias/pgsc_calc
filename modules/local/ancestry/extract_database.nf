process EXTRACT_DATABASE {
    // labels are defined in conf/modules.config
    label 'process_low'
    label 'zstd' // controls conda, docker, + singularity options

    storeDir "$workDir/ref_extracted/"

    conda "${task.ext.conda}"

    container "${ workflow.containerEngine == 'singularity' &&
        !task.ext.singularity_pull_docker_container ?
        "${task.ext.singularity}${task.ext.singularity_version}" :
        "${task.ext.docker}${task.ext.docker_version}" }"

    input:
    path reference

    output:
    tuple val(meta38), path("GRCh38_*_ALL.pgen"), path("GRCh38_*_ALL.psam"), path("GRCh38_*_ALL.pvar.zst"), emit: grch38, optional: true
    tuple val(meta38), path("deg2_hg38.king.cutoff.out.id"), emit: grch38_king, optional: true
    tuple val(meta37), path("GRCh37_*_ALL.pgen"), path("GRCh37_*_ALL.psam"), path("GRCh37_*_ALL.pvar.zst"), emit: grch37, optional: true
    tuple val(meta37), path("deg2_phase3.king.cutoff.out.id"), emit: grch37_king, optional: true
    path "versions.yml", emit: versions

    script:
    meta38 = ['build': 'GRCh38']
    meta37 = ['build': 'GRCh37']
    def king = params.target_build == "GRCh37" ? "deg2_phase3.king.cutoff.out.id" : "deg2_hg38.king.cutoff.out.id"

    """
    tar -xvf $reference --wildcards "${params.target_build}*" $king

    cat <<-END_VERSIONS > versions.yml
    ${task.process.tokenize(':').last()}:
        zstd: \$(zstd -V | grep -Eo 'v[0-9]\\.[0-9]\\.[0-9]+' )
    END_VERSIONS
    """
}
