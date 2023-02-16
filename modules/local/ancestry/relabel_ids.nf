process RELABEL_IDS {
    // labels are defined in conf/modules.config
    label 'process_low'
    label 'pgscatalog_utils' // controls conda, docker, + singularity options

    tag "$meta.id $target_format $meta.chrom"

    conda (params.enable_conda ? "${task.ext.conda}" : null)

    container "${ workflow.containerEngine == 'singularity' &&
        !task.ext.singularity_pull_docker_container ?
        "${task.ext.singularity}${task.ext.singularity_version}" :
        "${task.ext.docker}${task.ext.docker_version}" }"

    input:
    tuple val(meta), path(matched), path(target)

    output:
    tuple val(relabel_meta), path("*_${meta.id}*"), emit: relabelled
    path "versions.yml", emit: versions

    script:
    target_format = target.getName().tokenize('.')[1] // test.tar.gz -> tar, test.var -> var
    relabel_meta = meta.plus(['target_format': target_format]) // .plus() returns a new map
    col_from = (target_format == 'scorefile') ? 'ID_TARGET' : 'ID_REF'
    col_to = (target_format == 'scorefile') ? 'ID_REF' : 'ID_TARGET'
    def split =  meta.chrom ? '--split' : ''
    """
    relabel_ids --maps $matched \
        --col_from $col_from \
        --col_to $col_to \
        --target_file $target \
        --target_col ID \
        --out ${meta.id}.${target.getExtension()} \
        --verbose \
        $split

    cat <<-END_VERSIONS > versions.yml
    ${task.process.tokenize(':').last()}:
        pgscatalog_utils: \$(echo \$(python -c 'import pgscatalog_utils; print(pgscatalog_utils.__version__)'))
    END_VERSIONS
    """
}

