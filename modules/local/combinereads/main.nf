process COMBINEREADS {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/art_bioawk:f7eb38b1357af99b' :
        'community.wave.seqera.io/library/art_bioawk:f7eb38b1357af99b' }"

    input:
    tuple val(meta), path(bug_fastqs), path(human_fastqs)

    output:
    tuple val(meta), path("*_combined.fq.gz")  , emit: combined_fqs
    path "versions.yml"                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '2016.06.05'
    """
    cat *_R1.fq.gz > ${prefix}_R1_combined.fq.gz
    cat *_R2.fq.gz > ${prefix}_R2_combined.fq.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        art: $VERSION
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '2016.06.05'
    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        art: $VERSION
    END_VERSIONS
    """
}
