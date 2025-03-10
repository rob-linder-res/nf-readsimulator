process ARTILLUMINA {
    tag "$meta.id"
    label 'process_single'
    debug true

    // WARN: Version information not provided by tool on CLI. Please update version string below when bumping container versions.
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/art_bioawk:f7eb38b1357af99b' :
        'community.wave.seqera.io/library/art_bioawk:f7eb38b1357af99b' }"

    input:
    tuple val(meta), path(fasta)
    val(sequencing_system)
    val(reads)
    val(read_length)
    tuple val(meta), val(seed)

    output:
    tuple val(meta), path("*.fq.gz")              , emit: fastq
    tuple val(meta), path("*.aln"), optional:true , emit: aln
    tuple val(meta), path("*.sam"), optional:true , emit: sam
    path "versions.yml"                           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def args3 = task.ext.args3 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '2016.06.05' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    num_sequences=\$(cat $fasta | grep ">" | wc -l)
    
    if [[ \$num_sequences -gt $reads ]]; then
        bioawk -c fastx 'NR<=$reads {print ">"\$name"\\n"\$seq}\' $fasta > downsampled_ref.fasta
        num_reads=1
    else 
        cat $fasta > downsampled_ref.fasta
        num_reads=\$((($reads / \$num_sequences) + ($reads % \$num_sequences > 0)))
    fi
    
    echo \$num_sequences
    echo $reads
    echo \$num_reads
    
    art_illumina \\
        -ss $sequencing_system \\
        -rs $seed \\
        -i downsampled_ref.fasta \\
        -l $read_length \\
        -c \$num_reads \\
        -o $prefix \\
        $args

    gzip \\
        --no-name \\
        $args2 \\
        $prefix*.fq
    
    mv "${prefix}1.fq.gz" "${prefix}_R1.fq.gz"
    mv "${prefix}2.fq.gz" "${prefix}_R2.fq.gz"
    
    for file in *.fq.gz ; do mv \$file \${$args3} ; done
    
    rm -f downsampled_ref.fasta
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        art: $VERSION
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '2016.06.05'
    """
    echo "" | gzip > ${prefix}.fq.gz
    echo "" | gzip >  ${prefix}1.fq.gz
    echo "" | gzip >  ${prefix}2.fq.gz
    touch ${prefix}.aln
    touch ${prefix}1.aln
    touch ${prefix}2.aln
    touch ${prefix}.sam
    touch ${prefix}1.sam
    touch ${prefix}2.sam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        art: $VERSION
    END_VERSIONS
    """
}
